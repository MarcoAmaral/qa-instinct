#!/usr/bin/env node
// benchmark/build.js: builds the eval cases of the efficacy benchmark (plan 048) and checks them.
//
//   node benchmark/build.js                 build benchmark/cases/<condition>/<task>/ and print the digest
//   node benchmark/build.js --check         build into a temporary folder, then check:
//                                           - the digest equals benchmark/cases.sha256 (the frozen tree);
//                                           - every regex grader passes on its task's correct sample,
//                                             every "contains" grader fails on the generic wrong answer,
//                                             and each task's wrong sample fails at least one grader;
//                                           - the placebo says nothing about testing (CONTROL.md's sweep)
//                                             and its size is within 25% of the mean file D loads.
//   node benchmark/build.js --write-digest  build, then record the digest in benchmark/cases.sha256
//
// The text sent to the model comes only from PROMPTS.md and the fixtures; the graders only from
// benchmark/graders/<task>/*.md. Node standard library only; the output does not depend on the
// machine, the date or the order the file system lists files in.
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const crypto = require("crypto");

const ROOT = __dirname;
const REPO = path.dirname(ROOT);
const CONDITIONS = ["A", "B", "C", "D"];
// Plugin each condition loads, relative to a case directory benchmark/cases/<condition>/<task>/.
const PLUGIN = {
  A: "../../../bare-plugin",
  B: "../../../bare-plugin",
  C: "../../../control-standard",
  D: "../../../..",
};
// What condition D loads per command or skill, for the placebo's size parity.
const D_FILE = {
  "qa-cases": ".claude/commands/qa-cases.md",
  "qa-defect": ".claude/commands/qa-defect.md",
  "qa-bdd": ".claude/commands/qa-bdd.md",
  "qa-plan": ".claude/skills/qa-plan/SKILL.md",
  "qa-api": ".claude/skills/qa-api/SKILL.md",
  "qa-a11y": ".claude/skills/qa-a11y/SKILL.md",
  "qa-flaky": ".claude/skills/qa-flaky/SKILL.md",
};
const PLACEBO = path.join(
  ROOT,
  "control-standard",
  "commands",
  "help-articles.md",
);
// Words the placebo must not contain (CONTROL.md, "Silent on testing"). Matched whole-word, any case.
const BANNED = [
  "test",
  "tests",
  "testing",
  "tester",
  "testers",
  "tested",
  "testable",
  "QA",
  "quality",
  "ISTQB",
  "CTFL",
  "acceptance",
  "criteria",
  "criterion",
  "defect",
  "defects",
  "bug",
  "bugs",
  "failure",
  "failures",
  "fail",
  "fails",
  "failed",
  "severity",
  "priority",
  "risk",
  "risks",
  "boundary",
  "boundaries",
  "partition",
  "partitions",
  "equivalence",
  "decision table",
  "transition",
  "transitions",
  "Gherkin",
  "scenario",
  "scenarios",
  "coverage",
  "flaky",
  "quarantine",
  "accessibility",
  "accessible",
  "a11y",
  "WCAG",
  "aria",
  "alt",
  "screen reader",
  "contract",
  "OpenAPI",
  "schema",
  "assert",
  "assertion",
  "expected",
  "verify",
  "verification",
  "validate",
  "validation",
  "checklist",
  "review",
  "reviews",
  "error",
  "errors",
  "regression",
  "gate",
  "story",
  "stories",
  "requirement",
  "requirements",
  "BDD",
  "TDD",
  "audit",
  "inspection",
  "oracle",
];

function die(message) {
  console.error(`build.js: ${message}`);
  process.exit(1);
}

// ─── PROMPTS.md ───────────────────────────────────────────────────────────────

function fencedBlocks(text) {
  // Top-level ```text blocks only; ~~~ fences inside them are content.
  const blocks = [];
  const re = /^```text\n([\s\S]*?)\n```$/gm;
  let m;
  while ((m = re.exec(text)) !== null)
    blocks.push({ index: m.index, body: m[1] });
  return blocks;
}

function sectionAfter(text, heading) {
  const start = text.indexOf(`\n${heading}\n`);
  if (start < 0) die(`PROMPTS.md has no "${heading}" heading`);
  const rest = text.slice(start + heading.length + 2);
  const next = rest.search(/^#{2,3} /m);
  return next < 0 ? rest : rest.slice(0, next);
}

function readPrompts() {
  const text = fs
    .readFileSync(path.join(ROOT, "PROMPTS.md"), "utf8")
    .replace(/\r\n/g, "\n");
  const preamble = {};
  for (const c of CONDITIONS) {
    const sec = sectionAfter(text, `### ${c}`);
    const blocks = fencedBlocks(sec);
    if (blocks.length === 0) {
      if (!/^\s*\(none\)\s*$/m.test(sec))
        die(`preamble ${c} has neither a text block nor "(none)"`);
      preamble[c] = "";
    } else {
      preamble[c] = blocks[0].body.trim();
    }
  }
  const closingBlocks = fencedBlocks(sectionAfter(text, "## Common closing"));
  if (closingBlocks.length !== 1)
    die("the common closing must be one text block");
  const closing = closingBlocks[0].body.trim();

  const tasks = [];
  const re = /^## Task (\d+): ([a-z0-9-]+)\n/gm;
  let m;
  while ((m = re.exec(text)) !== null) {
    const sec = text.slice(m.index + m[0].length).split(/^## /m)[0];
    const cmd = /^D invokes: `([a-z0-9-]+)`$/m.exec(sec);
    if (!cmd) die(`task ${m[2]} has no "D invokes" line`);
    if (!D_FILE[cmd[1]]) die(`task ${m[2]} invokes unknown command ${cmd[1]}`);
    const blocks = fencedBlocks(sec);
    if (blocks.length !== 1)
      die(`task ${m[2]} must have exactly one text block`);
    tasks.push({
      number: Number(m[1]),
      id: m[2],
      command: cmd[1],
      template: blocks[0].body,
    });
  }
  if (tasks.length === 0) die("PROMPTS.md lists no tasks");
  tasks.forEach((t, i) => {
    if (t.number !== i + 1)
      die(
        `tasks must be numbered 1..n in order (found ${t.number} at ${i + 1})`,
      );
  });
  return { preamble, closing, tasks };
}

function taskPrompt(task) {
  const dir = path.join(ROOT, "fixtures", task.id);
  return task.template
    .replace(/^\{\{fixture:([^}]+)\}\}$/gm, (_, file) => {
      const p = path.join(dir, file);
      if (!fs.existsSync(p)) die(`task ${task.id}: fixture ${file} not found`);
      return fs
        .readFileSync(p, "utf8")
        .replace(/\r\n/g, "\n")
        .replace(/\n+$/, "");
    })
    .trim();
}

function message(prompts, condition, task) {
  const pre = prompts.preamble[condition].replace("{{command}}", task.command);
  const body = taskPrompt(task);
  return `${pre ? `${pre} ` : ""}${body}\n\n${prompts.closing}`;
}

// ─── Graders ──────────────────────────────────────────────────────────────────

function parseScalar(raw) {
  const v = raw.trim();
  if (v.startsWith("'")) {
    if (!v.endsWith("'") || v.length < 2)
      die(`unterminated single-quoted value: ${v.slice(0, 40)}`);
    return v.slice(1, -1).replace(/''/g, "'");
  }
  if (v.startsWith('"')) return JSON.parse(v);
  return v;
}

function readGrader(file) {
  const text = fs.readFileSync(file, "utf8").replace(/\r\n/g, "\n");
  const m = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/.exec(text);
  if (!m) die(`${file}: no frontmatter`);
  const g = { name: path.basename(file, ".md"), body: m[2].trim() };
  for (const line of m[1].split("\n")) {
    const kv = /^([a-z_]+):\s*(.*)$/.exec(line);
    if (!kv) die(`${file}: cannot read frontmatter line "${line}"`);
    g[kv[1]] = parseScalar(kv[2]);
  }
  if (!/^(con|fmt|jdg)-/.test(g.name))
    die(`${file}: a grader name starts with con-, fmt- or jdg-`);
  if (g.name.startsWith("jdg-") !== (g.type === "llm"))
    die(`${file}: jdg- graders and only they are llm`);
  if (g.type === "regex") {
    try {
      g.re = new RegExp(g.pattern, `${(g.flags || "").replace(/g/g, "")}g`);
    } catch (e) {
      die(`${file}: ${e.message}`);
    }
  } else if (g.type !== "llm") {
    die(`${file}: type must be regex or llm`);
  }
  return g;
}

function graderFiles(task) {
  const dir = path.join(ROOT, "graders", task.id);
  if (!fs.existsSync(dir)) die(`no graders for task ${task.id}`);
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".md"))
    .sort()
    .map((f) => path.join(dir, f));
}

// The same verdict claude plugin eval gives: contains (default), not_contains, or count:N.
function verdict(g, text) {
  g.re.lastIndex = 0;
  const matches = text.match(g.re);
  const n = matches ? matches.length : 0;
  const mode = g.match || "contains";
  if (mode === "contains") return n > 0;
  if (mode === "not_contains") return n === 0;
  const c = /^count:(\d+)$/.exec(mode);
  if (c) return n === Number(c[1]);
  die(`${g.name}: unknown match mode ${mode}`);
  return false;
}

// ─── Build and digest ─────────────────────────────────────────────────────────

function caseFrontmatter(condition, task) {
  return [
    "---",
    `name: ${condition}-${task.id}`,
    `description: "Plan 048 benchmark, condition ${condition}, task ${task.number} (${task.id}). Built by benchmark/build.js; do not edit."`,
    `tags: [benchmark, cond-${condition.toLowerCase()}, ${task.id}]`,
    `plugins: ["${PLUGIN[condition]}"]`,
    "max_turns: 15",
    "timeout_seconds: 600",
    "allowed_tools: [Read, Glob, Grep, Skill]",
    "---",
    "",
  ].join("\n");
}

function build(outDir) {
  const prompts = readPrompts();
  const files = {};
  for (const condition of CONDITIONS) {
    for (const task of prompts.tasks) {
      const rel = `${condition}/${task.id}`;
      files[`${rel}/prompt.md`] =
        `${caseFrontmatter(condition, task)}\n${message(prompts, condition, task)}\n`;
      for (const g of graderFiles(task)) {
        files[`${rel}/graders/${path.basename(g)}`] = fs
          .readFileSync(g, "utf8")
          .replace(/\r\n/g, "\n");
      }
    }
  }
  fs.rmSync(outDir, { recursive: true, force: true });
  for (const [rel, content] of Object.entries(files)) {
    const p = path.join(outDir, rel);
    fs.mkdirSync(path.dirname(p), { recursive: true });
    fs.writeFileSync(p, content);
  }
  const hash = crypto.createHash("sha256");
  for (const rel of Object.keys(files).sort()) {
    hash.update(`${rel}\0${files[rel]}\0`);
  }
  return {
    prompts,
    digest: hash.digest("hex"),
    count: Object.keys(files).length,
  };
}

// ─── Checks ───────────────────────────────────────────────────────────────────

function checkGraders(prompts) {
  const generic = fs.readFileSync(
    path.join(ROOT, "graders", "generic-wrong.txt"),
    "utf8",
  );
  let failures = 0;
  let checks = 0;
  for (const task of prompts.tasks) {
    const graders = graderFiles(task).map(readGrader);
    const sampleDir = path.join(ROOT, "graders", task.id, "samples");
    const correctPath = path.join(sampleDir, "correct.txt");
    if (!fs.existsSync(correctPath))
      die(`task ${task.id} has no samples/correct.txt`);
    const correct = fs.readFileSync(correctPath, "utf8");
    for (const g of graders.filter((x) => x.type === "regex")) {
      checks += 2;
      if (!verdict(g, correct)) {
        console.error(`  ✘ ${task.id}/${g.name}: fails on the correct sample`);
        failures++;
      }
      if ((g.match || "contains") !== "not_contains" && verdict(g, generic)) {
        console.error(
          `  ✘ ${task.id}/${g.name}: passes on the generic wrong answer`,
        );
        failures++;
      }
    }
    const negatives = graders.filter(
      (x) => x.type === "regex" && x.match === "not_contains",
    );
    if (negatives.length > 0) {
      const wrongPath = path.join(sampleDir, "wrong.txt");
      if (!fs.existsSync(wrongPath))
        die(
          `task ${task.id} has not_contains graders but no samples/wrong.txt`,
        );
      const wrong = fs.readFileSync(wrongPath, "utf8");
      checks++;
      if (negatives.every((g) => verdict(g, wrong))) {
        console.error(
          `  ✘ ${task.id}: no not_contains grader fails on samples/wrong.txt`,
        );
        failures++;
      }
    }
  }
  return { failures, checks };
}

function checkPlacebo(prompts) {
  const text = fs.readFileSync(PLACEBO, "utf8");
  const hits = [];
  for (const word of BANNED) {
    const re = new RegExp(
      `(?<![A-Za-z0-9])${word.replace(/ /g, "\\s+")}(?![A-Za-z0-9])`,
      "gi",
    );
    const found = text.match(re);
    if (found) hits.push(`${word} (${found.length})`);
  }
  for (const re of [/\bAC-\d/g, /\bTC-[A-Z]/g, /\bDR-[A-Z]/g, /§/g]) {
    if (re.test(text)) hits.push(re.source);
  }
  const size = Buffer.byteLength(text);
  const sizes = prompts.tasks.map(
    (t) => fs.statSync(path.join(REPO, D_FILE[t.command])).size,
  );
  const mean = sizes.reduce((a, b) => a + b, 0) / sizes.length;
  const ratio = size / mean;
  return { hits, size, mean, ratio, sizes };
}

function main() {
  const args = process.argv.slice(2);
  const check = args.includes("--check");
  const write = args.includes("--write-digest");
  const unknown = args.filter((a) => a !== "--check" && a !== "--write-digest");
  if (unknown.length) die(`unknown option ${unknown[0]}`);

  const outDir = check
    ? fs.mkdtempSync(path.join(os.tmpdir(), "qa-instinct-benchmark-"))
    : path.join(ROOT, "cases");
  const { prompts, digest, count } = build(outDir);
  console.log(
    `${count} files in ${prompts.tasks.length * CONDITIONS.length} cases, SHA-256 ${digest}`,
  );
  const digestFile = path.join(ROOT, "cases.sha256");
  if (write) fs.writeFileSync(digestFile, `${digest}\n`);
  if (!check) return;

  let failed = false;
  const frozen = fs.existsSync(digestFile)
    ? fs.readFileSync(digestFile, "utf8").trim()
    : "(none)";
  if (frozen !== digest) {
    console.error(
      `  ✘ case tree digest ${digest} differs from benchmark/cases.sha256 (${frozen})`,
    );
    failed = true;
  }
  const g = checkGraders(prompts);
  console.log(
    `grader samples: ${g.checks - g.failures} of ${g.checks} checks as expected`,
  );
  if (g.failures) failed = true;
  const p = checkPlacebo(prompts);
  console.log(
    `placebo: ${p.size} bytes, ${(p.ratio * 100).toFixed(1)}% of the ${Math.round(p.mean)}-byte mean file D loads; ` +
      `banned words: ${p.hits.length ? p.hits.join(", ") : "none"}`,
  );
  if (p.hits.length) failed = true;
  if (p.ratio < 0.75 || p.ratio > 1.25) {
    console.error(
      "  ✘ placebo size is not within 25% of the mean file D loads",
    );
    failed = true;
  }
  fs.rmSync(outDir, { recursive: true, force: true });
  if (failed) die("check failed");
  console.log("✔ benchmark build check passed");
}

module.exports = { readGrader, verdict, graderFiles, readPrompts };

if (require.main === module) main();
