#!/usr/bin/env node
// benchmark/analysis/rescore.js: a labelled corrected re-score (RUNBOOK.md section 5). It applies the
// grader verdicts a read-through found wrong, listed with their reasons in <results dir>/corrections.json,
// and prints the runs as runs.jsonl lines for analyze.js. The collected runs.jsonl is never changed.
//
//   node benchmark/analysis/rescore.js <results dir> [--set-aside <grader>] > corrected.jsonl
//   node benchmark/analysis/analyze.js corrected.jsonl
//
// --set-aside removes a grader from every run, for a sensitivity reading; it is not a correction.
// Every correction must match a run whose collected verdict is the one it records, or nothing is printed.
"use strict";

const fs = require("fs");
const path = require("path");

function die(message) {
  console.error(`rescore.js: ${message}`);
  process.exit(1);
}

const args = process.argv.slice(2);
const dir = args[0];
let setAside = null;
if (args[1] === "--set-aside") setAside = args[2];
if (
  !dir ||
  (args.length > 1 &&
    (args[1] !== "--set-aside" || !setAside || args.length > 3))
) {
  die("usage: rescore.js <results dir> [--set-aside <grader>]");
}

const runs = fs
  .readFileSync(path.join(dir, "runs.jsonl"), "utf8")
  .split("\n")
  .filter((line) => line.trim())
  .map((line) => JSON.parse(line));
const { corrections } = JSON.parse(
  fs.readFileSync(path.join(dir, "corrections.json"), "utf8"),
);

for (const c of corrections) {
  const run = runs.find(
    (r) => r.task === c.task && r.condition === c.condition && r.run === c.run,
  );
  if (!run) die(`no run ${c.condition}/${c.task}/run-${c.run}`);
  if (run.graders[c.grader] !== c.collected) {
    die(
      `${c.condition}/${c.task}/run-${c.run} ${c.grader} was ${run.graders[c.grader]}, not ${c.collected}`,
    );
  }
  run.graders[c.grader] = c.corrected;
}

for (const run of runs) {
  if (setAside) delete run.graders[setAside];
  console.log(JSON.stringify(run));
}
