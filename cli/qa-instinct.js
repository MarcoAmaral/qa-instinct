#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const os = require("os");
const crypto = require("crypto");

// ─── Paths ────────────────────────────────────────────────────────────────────

const PKG_DIR = path.resolve(__dirname, "..");
const PKG_CLAUDE = path.join(PKG_DIR, ".claude");
const ADAPTERS_DIR = path.join(PKG_DIR, "adapters");
const EDITOR_MAP_FILE = path.join(PKG_DIR, ".qa-instinct-editor-map");

const SUBDIRS = ["commands", "rules", "skills", "agents", "hooks"];

// ─── Editor targets ─────────────────────────────────────────────────────────
// `claude` copies the raw .claude/ source tree (handled separately, see
// installClaudeEditor). Every other editor gets its generated rule files from
// adapters/<editor>/rules/ in its rules folder and the one Agent Skills tree
// adapters/skills/ in its skills folder (plan 047). `null` means the editor has
// no such folder for that scope; an editor installs for a scope only when it
// has a skills folder there. A skills column may name several folders separated
// by "," (Antigravity's App and IDE share one global folder, its CLI reads
// another; plan 058), so `skills` is a list. Single source of truth for this mapping is
// .qa-instinct-editor-map, shared with install.sh and install.ps1 — see that
// file's header comment there for the on-disk format. Read once at startup
// instead of hardcoded here, so all three installers stay in sync automatically.

function loadEditorMap() {
  const raw = fs.readFileSync(EDITOR_MAP_FILE, "utf8").replace(/^\uFEFF/, "");
  const targets = {};
  const labels = {};
  const folder = (v) => (v === "-" ? null : v);
  const folders = (v) => (v === "-" ? null : v.split(","));
  for (const rawLine of raw.split("\n")) {
    const line = rawLine.replace(/\r$/, "");
    if (!line) continue;
    const [
      editor,
      projectRules,
      globalRules,
      projectSkills,
      globalSkills,
      label,
    ] = line.split("\t");
    targets[editor] = {
      project: { rules: folder(projectRules), skills: folders(projectSkills) },
      global: { rules: folder(globalRules), skills: folders(globalSkills) },
    };
    labels[editor] = label;
  }
  return { targets, labels };
}

const { targets: EDITOR_TARGETS, labels: EDITOR_LABELS } = loadEditorMap();

const ALL_EDITORS = ["claude", ...Object.keys(EDITOR_TARGETS)];

// ─── Colors ───────────────────────────────────────────────────────────────────

const NO_COLOR = process.env.NO_COLOR || !process.stdout.isTTY;
const c = {
  green: (s) => (NO_COLOR ? s : `\x1b[32m${s}\x1b[0m`),
  yellow: (s) => (NO_COLOR ? s : `\x1b[33m${s}\x1b[0m`),
  cyan: (s) => (NO_COLOR ? s : `\x1b[36m${s}\x1b[0m`),
  red: (s) => (NO_COLOR ? s : `\x1b[31m${s}\x1b[0m`),
  bold: (s) => (NO_COLOR ? s : `\x1b[1m${s}\x1b[0m`),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

// Never through a link: a linked hooks folder was skipped by installFile, and a linked hook file
// is left as it is. The mode is set through a descriptor opened with O_NOFOLLOW, so a hook swapped
// for a link after the check is not followed either (plan 033 item 1).
function chmodHooks(targetClaude) {
  const hooksDir = path.join(targetClaude, "hooks");
  if (!fs.existsSync(hooksDir) || isSymlink(hooksDir)) return;
  for (const f of fs.readdirSync(hooksDir)) {
    if (!f.endsWith(".sh")) continue;
    const hook = path.join(hooksDir, f);
    if (isSymlink(hook)) {
      console.log(
        c.yellow(
          `  ! Skipped ${toPosix(path.relative(path.dirname(targetClaude), hook))} — it is a symbolic link; its mode was not changed`,
        ),
      );
      continue;
    }
    try {
      const fd = fs.openSync(
        hook,
        fs.constants.O_RDONLY | (fs.constants.O_NOFOLLOW || 0),
      );
      try {
        // A folder of the user's named like a hook is skipped on install and keeps its mode.
        if (fs.fstatSync(fd).isFile()) fs.fchmodSync(fd, 0o755);
      } finally {
        fs.closeSync(fd);
      }
    } catch (_) {}
  }
}

// The options each command accepts. Anything else is refused before a file is written, so a
// typo such as --globl never falls back to a default (plan 033 item 4).
const COMMAND_OPTIONS = {
  init: ["--global", "--editor"],
  uninstall: ["--global", "--editor"],
  update: ["--global", "--editor"],
  link: ["--global"],
  unlink: ["--global"],
};

// Returns { global, editor } for one command's arguments; editor is null when --editor is
// absent. Exits 1 on an unknown option or an invalid --editor value.
function parseArgs(command, args) {
  const allowed = COMMAND_OPTIONS[command];
  const opts = { global: false, editor: null };
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (!allowed.includes(arg)) {
      console.error(
        c.red(
          `Error: unknown option '${arg}'. Run 'qa-instinct help' for usage.`,
        ),
      );
      process.exit(1);
    }
    if (arg === "--global") {
      opts.global = true;
      continue;
    }
    const value = args[++i];
    if (!value || (!ALL_EDITORS.includes(value) && value !== "all")) {
      console.error(
        c.red(
          `Error: invalid --editor value '${value || ""}'. Use: ${ALL_EDITORS.join(", ")}, or all.`,
        ),
      );
      process.exit(1);
    }
    opts.editor = value;
  }
  return opts;
}

function resolveTarget(opts) {
  return opts.global ? os.homedir() : process.cwd();
}

// Names .claude/ only when Claude Code is the run's one editor; every other editor's own
// "✓" line names its folders (plan 062).
function label(opts, editors = ["claude"]) {
  const claudeOnly = editors.length === 1 && editors[0] === "claude";
  return opts.global
    ? c.cyan("global") +
        c.yellow(claudeOnly ? ` (~/.claude/)` : ` (your home folder)`)
    : c.cyan("project") +
        c.yellow(claudeOnly ? ` (./.claude/)` : ` (this folder)`);
}

// Walks upward from `dir`, removing each directory only while it's empty, and
// never removes `stopBase` itself — cleans up an editor's now-empty folders
// (e.g. .cursor/rules, then .cursor) after uninstall. Stops at the first level
// that does not exist, as install.sh and install.ps1 do: a folder above a
// missing one was not emptied by this run, so it may be the user's (plan 047).
function removeEmptyDirChain(dir, stopBase) {
  const base = path.resolve(stopBase);
  let current = path.resolve(dir);
  while (current !== base && (current + path.sep).startsWith(base + path.sep)) {
    if (!fs.existsSync(current)) break;
    let entries;
    try {
      entries = fs.readdirSync(current);
    } catch (_) {
      break;
    }
    if (entries.length > 0) break;
    // A linked folder is the user's: on Windows rmdir removes a link instead of failing.
    if (isSymlink(current)) break;
    try {
      fs.rmdirSync(current);
    } catch (_) {
      break;
    }
    current = path.dirname(current);
  }
}

// ─── Install manifest ─────────────────────────────────────────────────────────
// Every file this CLI writes is recorded in <base>/.qa-instinct-manifest as
// "<sha256>  <editor>  <path relative to base>" (editor is always "claude" here).
// This is the exact on-disk contract shared with install.sh / install.ps1: no BOM,
// LF line endings, forward-slash paths, two spaces between fields. Reads tolerate a
// leading UTF-8 BOM, a trailing \r, and backslash separators, so a manifest written
// by either shell installer — or an older release — still parses correctly.

function manifestFile(base) {
  return path.join(base, ".qa-instinct-manifest");
}

// The name every 4.x release wrote the manifest under (plan 066).
function legacyManifestFile(base) {
  return path.join(base, ".qa-skills-manifest");
}

function hashFile(file) {
  return crypto
    .createHash("sha256")
    .update(fs.readFileSync(file))
    .digest("hex");
}

// The package's own file with CRLF line endings (a Windows checkout with
// core.autocrlf, a Windows editor) is still the package's file. A file on disk
// therefore *matches* a hash if its bytes hash to it, or its bytes with every
// carriage return removed do — the same rule in install.sh and install.ps1
// (plans/017). Hashes are still recorded as the raw bytes.
function hashFileWithoutCR(file) {
  return crypto
    .createHash("sha256")
    .update(fs.readFileSync(file).filter((b) => b !== 13))
    .digest("hex");
}

// A file that exists but cannot be opened for reading: it can be neither hashed nor backed up, so
// nothing proves it is the package's (plan 053 I15). A missing file, or a link to one, is not.
function isUnreadable(file) {
  try {
    fs.closeSync(fs.openSync(file, "r"));
    return false;
  } catch (err) {
    return err.code === "EACCES" || err.code === "EPERM";
  }
}

function fileMatches(file, hash) {
  if (!hash) return false;
  return hashFile(file) === hash || hashFileWithoutCR(file) === hash;
}

// Whether some release shipped this file, by the same rule.
function isKnownFile(file, knownHashes) {
  return (
    knownHashes.has(hashFile(file)) || knownHashes.has(hashFileWithoutCR(file))
  );
}

function toPosix(p) {
  return p.split(path.sep).join("/");
}

// Reads a portable-format file (manifest or known-hash list) line by line,
// stripping a leading UTF-8 BOM, any trailing \r, and normalizing backslash path
// separators to forward slashes.
function readPortableLines(file) {
  if (!fs.existsSync(file)) return [];
  let text = fs.readFileSync(file, "utf8");
  if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
  text = text.replace(/\r/g, "").replace(/\\/g, "/");
  return text.split("\n").filter((l) => l.length > 0);
}

// Parses one manifest line as bash's `read -r HASH ENTRY_ED REL` would: the first
// two whitespace-separated tokens are the hash and editor, and the rest of the
// line (after the separating whitespace) is the path — preserving any spaces the
// path itself contains.
function parseManifestLine(line) {
  const m = line.match(/^(\S+)\s+(\S+)\s+(.*)$/);
  return m ? { hash: m[1], editor: m[2], rel: m[3] } : null;
}

// A manifest path must stay inside the base it was recorded under. The manifest is a plain
// file at the project root and is committed into consuming repositories, so its contents are
// attacker-controllable: a crafted entry such as "../../../.ssh/config" would otherwise make
// uninstall delete a file outside the install tree entirely. installFile refuses to *record*
// such a path; this refuses to act on one.
function isSafeManifestRel(base, rel) {
  if (!rel || path.isAbsolute(rel) || /^[A-Za-z]:/.test(rel)) return false;
  const segments = rel.split("/");
  if (segments.some((seg) => seg === ".." || seg === "")) return false;
  const resolved = path.resolve(base, ...segments);
  const root = path.resolve(base) + path.sep;
  return resolved.startsWith(root);
}

function manifestLookup(base, editor, rel) {
  for (const line of readPortableLines(manifestFile(base))) {
    const e = parseManifestLine(line);
    if (e && e.editor === editor && e.rel === rel) return e.hash;
  }
  return null;
}

// Every manifest write goes to a new temp file created exclusively beside the manifest ("wx" fails
// if anything, a planted link included, already has that name), then renamed over it; a rename
// replaces a symlinked manifest instead of writing through it (plan 033 item 2). A name already
// taken is passed over for another, up to 20, as install.sh does (plan 053 I10).
// With no entries left, the manifest is removed.
function writeManifest(mf, entries) {
  if (entries.length === 0) {
    fs.rmSync(mf, { force: true });
    return;
  }
  const body = entries
    .map((e) => `${e.hash}  ${e.editor}  ${e.rel}\n`)
    .join("");
  let tmp;
  let fd;
  for (let n = 1; ; n++) {
    tmp = `${mf}.tmp-${process.pid}-${crypto.randomBytes(6).toString("hex")}`;
    try {
      fd = fs.openSync(tmp, "wx");
      break;
    } catch (err) {
      if (err.code !== "EEXIST" || n >= 20) throw err;
    }
  }
  try {
    fs.writeFileSync(fd, body, "utf8");
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, mf);
}

// Moves a 4.x install's manifest to the current name, the same in all three installers (plan 066),
// before anything reads the manifest. Every entry of both files is kept; on the same editor and
// path the current manifest's entry wins. The new manifest is written the usual way, then the old
// name is removed: a symlink there is unlinked, never its target. A folder or an unreadable file at
// the old name is not a manifest this run can use, so it is left and reported.
function migrateManifest(base) {
  const old = legacyManifestFile(base);
  if (!fs.existsSync(old)) return;
  const name = path.basename(old);
  if (fs.statSync(old).isDirectory()) {
    console.log(
      c.yellow(`  ! Kept ${name} — it is a directory, not a manifest`),
    );
    return;
  }
  if (isUnreadable(old)) {
    console.log(c.yellow(`  ! Kept ${name} — it cannot be read`));
    return;
  }
  const mf = manifestFile(base);
  const entries = readPortableLines(mf).map(parseManifestLine).filter(Boolean);
  const keys = new Set(entries.map((e) => `${e.editor}  ${e.rel}`));
  for (const e of readPortableLines(old)
    .map(parseManifestLine)
    .filter(Boolean)) {
    if (!keys.has(`${e.editor}  ${e.rel}`)) entries.push(e);
  }
  writeManifest(mf, entries);
  fs.rmSync(old, { force: true });
}

function manifestRecord(base, editor, rel, hash) {
  const mf = manifestFile(base);
  const entries = readPortableLines(mf)
    .map(parseManifestLine)
    .filter((e) => e && !(e.editor === editor && e.rel === rel));
  entries.push({ hash, editor, rel });
  writeManifest(mf, entries);
}

// .qa-instinct-known-hashes ships in the npm package and records the SHA-256 of
// every file the package has ever shipped, across all tagged releases. It lets
// install tell its own older file from the user's edit with certainty instead
// of guessing: a destination whose hash appears there is the package's own file
// and is adopted silently; anything else is the user's and is backed up.
function loadKnownHashes() {
  const list = path.join(PKG_DIR, ".qa-instinct-known-hashes");
  const set = new Set();
  for (const line of readPortableLines(list)) {
    const m = line.match(/^(\S+)/);
    if (m) set.add(m[1]);
  }
  return set;
}

function utcTimestamp() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  return (
    `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}` +
    `T${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}Z`
  );
}

// Whether anything, a link included, has this name.
function pathTaken(p) {
  try {
    fs.lstatSync(p);
    return true;
  } catch (_) {
    return false;
  }
}

// If dest's content differs from src (and from what the manifest last recorded for
// it), decide whether it is the package's own older file (adopt, no backup) or the
// user's (back it up first). Returns { status: 'match' | 'adopted' | 'backup', path? }.
function backupDest(base, editor, rel, dest, src, knownHashes) {
  const srcHash = hashFile(src);
  const recorded = manifestLookup(base, editor, rel);
  // Raw bytes first; the carriage-return-free hash only when they match nothing
  // (see fileMatches).
  for (const hashDest of [hashFile, hashFileWithoutCR]) {
    const destHash = hashDest(dest);
    if (destHash === srcHash || destHash === recorded)
      return { status: "match" };
    if (knownHashes.has(destHash)) return { status: "adopted" };
  }

  // Created exclusively, like the manifest's temp file: a name already taken, a link planted there
  // included, is never opened (COPYFILE_EXCL); the next number is tried instead. On Windows a
  // junction or a folder at the name fails with EPERM, not EEXIST (plan 053 I10).
  const suffix = utcTimestamp();
  let backup = `${dest}.qa-instinct-backup-${suffix}`;
  for (let n = 1; ; n++) {
    try {
      fs.copyFileSync(dest, backup, fs.constants.COPYFILE_EXCL);
      return { status: "backup", path: backup };
    } catch (err) {
      const taken =
        err.code === "EEXIST" || (err.code === "EPERM" && pathTaken(backup));
      if (!taken || n >= 100) throw err;
    }
    backup = `${dest}.qa-instinct-backup-${suffix}-${n}`;
  }
}

// A symlinked folder below the editor's top-level folder (.claude/rules, .agents/skills, ...) is
// never written or deleted through: after `qa-instinct link` those folders are the package's own
// files, and any other link leads outside the install tree. The top-level folder itself (.claude
// as a link into a dotfiles repository) is followed, as the editor follows it (plan 033 item 1).
// Returns the first such folder, relative to base, or null.
function linkedAncestor(base, rel) {
  const segments = rel.split("/");
  for (let i = 2; i < segments.length; i++) {
    if (isSymlink(path.join(base, ...segments.slice(0, i))))
      return segments.slice(0, i).join("/");
  }
  return null;
}

// Says once per link and run why the files under it were left alone.
const reportedLinks = new Set();
function reportLinkedDir(base, dir, action, verb) {
  if (reportedLinks.has(dir)) return;
  reportedLinks.add(dir);
  const hint = isQaInstinctLink(
    path.join(base, ...dir.split("/")),
    path.basename(dir),
  )
    ? "; run 'qa-instinct unlink' first"
    : "";
  console.log(
    c.yellow(
      `  ! ${action} ${dir}/ — it is a symbolic link; nothing was ${verb} through it${hint}`,
    ),
  );
}

// Files installFile wrote in this run; an install that wrote none says so instead of "Done!".
let filesWritten = 0;

// Installs one file, never writing through a symlinked destination, backing up
// anything at dest that isn't the package's own unmodified file, and recording
// the result in the manifest. Returns true when it wrote the file, false when it skipped it.
function installFile(base, editor, src, dest, knownHashes) {
  const rel = toPosix(path.relative(base, dest));
  if (rel.startsWith("..") || path.isAbsolute(rel)) {
    throw new Error(
      `refusing to install ${dest} — it is not inside base ${base}, so it can never be recorded in the manifest.`,
    );
  }

  const linked = linkedAncestor(base, rel);
  if (linked) {
    reportLinkedDir(base, linked, "Skipped", "written");
    return false;
  }

  let lst = null;
  try {
    lst = fs.lstatSync(dest);
  } catch (_) {
    lst = null;
  }

  let target = null;
  try {
    target = lst && fs.statSync(dest);
  } catch (_) {
    target = null;
  }
  if (target && target.isDirectory()) {
    // A folder, or a link to one, stands where the package's file goes. It is the user's: nothing
    // is written into it, backed up or recorded, and the rest installs, as install.sh's [ -d ]
    // decides. Checked before the symlink branch, which would hash the folder (EISDIR) and stop
    // the run part-way (plan 061 B2).
    console.log(
      c.yellow(
        `  ! Skipped ${rel} — it is a directory; nothing was written into it`,
      ),
    );
    return false;
  }
  if (target && target.isFile() && isUnreadable(dest)) {
    // Nothing proves it is the package's, and it cannot be backed up: left as it is, like a
    // read-only one (plan 053 I15).
    console.log(
      c.yellow(
        `  ! Skipped ${rel} — destination cannot be read (existing file left untouched)`,
      ),
    );
    return false;
  }

  if (lst && lst.isSymbolicLink()) {
    // Never write through a symlinked destination — back up the link's own content
    // (following it) and record where it pointed, then replace the link itself.
    const linkTarget = fs.readlinkSync(dest);
    if (fs.existsSync(dest)) {
      const result = backupDest(base, editor, rel, dest, src, knownHashes);
      if (result.status === "adopted") {
        console.log(
          `  i ${rel} is a symlink to ${linkTarget} whose content matches an earlier release — updating (link target left untouched)`,
        );
      } else if (result.status === "backup") {
        try {
          fs.writeFileSync(`${result.path}.link-target`, `${linkTarget}\n`, {
            flag: "wx",
          });
        } catch (err) {
          if (err.code !== "EEXIST") throw err;
          console.log(
            c.yellow(
              `  ! Could not record the link target: ${path.basename(result.path)}.link-target already exists`,
            ),
          );
        }
        console.log(
          c.yellow(
            `  ! ${rel} is a symlink to ${linkTarget} — its content was backed up to ${path.basename(result.path)} (link target left untouched)`,
          ),
        );
      }
    } else {
      console.log(
        c.yellow(
          `  ! ${rel} is a broken symlink to ${linkTarget} — replacing with the package file`,
        ),
      );
    }
    fs.unlinkSync(dest);
  } else if (lst && lst.isFile()) {
    // A read-only destination is a deliberate signal not to overwrite it: skip the file and
    // keep installing the rest of the tree, the same way install.sh and install.ps1 do, and
    // the same way uninstallRecorded below keeps one. Checked before any backup, so a skipped
    // file leaves nothing behind. Without this, copyFileSync throws EACCES and aborts the whole
    // install part-way, leaving a half-written tree and manifest.
    let writable = true;
    try {
      fs.accessSync(dest, fs.constants.W_OK);
    } catch (_) {
      writable = false;
    }
    if (!writable) {
      console.log(
        c.yellow(
          `  ! Skipped ${rel} — destination is read-only (existing file left untouched)`,
        ),
      );
      return false;
    }
    const result = backupDest(base, editor, rel, dest, src, knownHashes);
    if (result.status === "adopted") {
      console.log(
        `  i ${rel} already existed and matches an earlier release — updating to the current version`,
      );
    } else if (result.status === "backup") {
      console.log(
        c.yellow(
          `  ! ${rel} already existed and differs — backed up to ${path.basename(result.path)}`,
        ),
      );
    }
  } else if (lst) {
    // A folder (Cline also reads a .clinerules folder) or anything else that is not a file is the
    // user's: nothing is written into it and nothing is recorded, and the rest still installs.
    // copyFileSync would throw EISDIR and stop the run, leaving later editors uninstalled.
    console.log(
      c.yellow(
        `  ! Skipped ${rel} — it is ${lst.isDirectory() ? "a directory" : "not a regular file"}; nothing was written into it`,
      ),
    );
    return false;
  }

  ensureDir(path.dirname(dest));
  fs.copyFileSync(src, dest);
  filesWritten++;
  manifestRecord(base, editor, rel, hashFile(dest));
  return true;
}

// File by file: installFile creates each folder it needs, and never one inside a linked folder.
// Returns whether it wrote at least one file.
function copyDirSafe(base, editor, src, dest, knownHashes) {
  let wrote = false;
  for (const file of walkFiles(src)) {
    if (
      installFile(
        base,
        editor,
        file,
        path.join(dest, path.relative(src, file)),
        knownHashes,
      )
    )
      wrote = true;
  }
  return wrote;
}

function walkFiles(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walkFiles(p));
    else out.push(p);
  }
  return out;
}

// Removes only manifest entries for `editor` whose file still matches the recorded
// hash; anything the user changed (or made read-only) is left in place, warned
// about, and dropped from the manifest anyway since it is no longer "installed by
// us" in any trackable sense. Mirrors install.sh's uninstall_recorded exactly.
function uninstallRecorded(base, editor) {
  const mf = manifestFile(base);
  let removed = 0,
    kept = 0;
  const removedRels = [];
  if (!fs.existsSync(mf)) return { removed, kept, removedRels };

  const entries = readPortableLines(mf).map(parseManifestLine).filter(Boolean);
  const surviving = [];
  for (const e of entries) {
    if (e.editor !== editor) {
      surviving.push(e);
      continue;
    }
    if (!isSafeManifestRel(base, e.rel)) {
      console.log(
        c.red(
          `  ✘ Refusing ${e.rel} — it points outside ${base}. The manifest may have been tampered with.`,
        ),
      );
      surviving.push(e);
      continue;
    }
    const linked = linkedAncestor(base, e.rel);
    if (linked) {
      // Kept, and still recorded: the file is not ours to delete through a link.
      reportLinkedDir(base, linked, "Kept", "deleted");
      surviving.push(e);
      kept++;
      continue;
    }
    const file = path.join(base, ...e.rel.split("/"));
    let st;
    try {
      st = fs.statSync(file);
    } catch (_) {
      continue;
    }
    if (st.isDirectory()) {
      // A folder now stands at the recorded path: not the file this package installed. Kept, and
      // its entry dropped, as for any file kept because it changed (the wording install.ps1 uses).
      console.log(c.yellow(`  ! Kept ${e.rel} — it is a directory`));
      const note = oldLocationNote(base, editor, e.rel);
      if (note) console.log(c.yellow(note));
      kept++;
      continue;
    }
    if (!st.isFile()) continue;

    let writable = true;
    try {
      fs.accessSync(file, fs.constants.W_OK);
    } catch (_) {
      writable = false;
    }
    if (!writable) {
      console.log(c.yellow(`  ! Kept ${e.rel} — destination is read-only`));
      kept++;
    } else if (isUnreadable(file)) {
      console.log(c.yellow(`  ! Kept ${e.rel} — destination cannot be read`));
      kept++;
    } else if (fileMatches(file, e.hash)) {
      fs.rmSync(file);
      removed++;
      removedRels.push(e.rel);
    } else {
      console.log(
        c.yellow(`  ! Kept ${e.rel} — changed since it was installed`),
      );
      const note = oldLocationNote(base, editor, e.rel);
      if (note) console.log(c.yellow(note));
      kept++;
    }
  }

  writeManifest(mf, surviving);
  return { removed, kept, removedRels };
}

// Also true for a Windows directory junction, which Node reports as a symbolic link (readlink
// gives its target with a trailing separator, which path.resolve drops). So linkedAncestor,
// isQaInstinctLink, linkedIntoPackage and the empty-folder cleanup treat the junctions `link` makes
// without Developer Mode exactly as symlinks: checked on Windows by lifecycle Test 42b.
function isSymlink(p) {
  try {
    return fs.lstatSync(p).isSymbolicLink();
  } catch (_) {
    return false;
  }
}

// True when dest is a symlink whose real target lies inside this package's own
// .claude/ folder (a `qa-instinct link`). Walking such a dest would walk the package's
// own files, so uninstall must never treat it as an installed copy.
function linkedIntoPackage(dest) {
  try {
    if (!isSymlink(dest)) return false;
    const real = fs.realpathSync(dest);
    const pkgReal = fs.realpathSync(PKG_CLAUDE);
    return real === pkgReal || real.startsWith(pkgReal + path.sep);
  } catch (_) {
    return false;
  }
}

// True when dest is a symlink whose target path ends in `.claude/<sub>`: a link
// some qa-instinct package made, whichever package it was. Works on a dangling link.
function isQaInstinctLink(dest, sub) {
  try {
    if (!isSymlink(dest)) return false;
    const target = path.resolve(path.dirname(dest), fs.readlinkSync(dest));
    return target.endsWith(path.sep + path.join(".claude", sub));
  } catch (_) {
    return false;
  }
}

// Fallback for installs made before manifests existed: remove dest only if its
// content still matches what the package currently ships at src.
function removeIfMatches(base, src, dest) {
  const linked = linkedAncestor(base, toPosix(path.relative(base, dest)));
  if (linked) {
    reportLinkedDir(base, linked, "Kept", "deleted");
    return fs.existsSync(dest) ? "kept" : "skip";
  }
  if (!fs.existsSync(dest)) return "skip";
  if (fs.statSync(dest).isDirectory()) {
    console.log(c.yellow(`  ! Kept ${dest} — it is a directory`));
    return "kept";
  }
  if (isUnreadable(dest)) {
    console.log(c.yellow(`  ! Kept ${dest} — destination cannot be read`));
    return "kept";
  }
  if (fs.existsSync(src) && fileMatches(dest, hashFile(src))) {
    fs.rmSync(dest);
    return "removed";
  }
  console.log(
    c.yellow(
      `  ! Kept ${dest} — not installed by this package, or changed since install`,
    ),
  );
  return "kept";
}

// ─── Commands ─────────────────────────────────────────────────────────────────

// Copies the raw .claude/ source tree — the `claude` editor target. Unchanged
// from before --editor support existed; other editors never share this path.
function installClaudeEditor(targetBase, knownHashes) {
  const targetClaude = path.join(targetBase, ".claude");

  for (const sub of SUBDIRS) {
    const src = path.join(PKG_CLAUDE, sub);
    const dest = path.join(targetClaude, sub);
    if (!fs.existsSync(src)) continue;

    // A linked dest is skipped file by file by installFile, and reported there. A folder none of
    // whose files was written (linked, or every file read-only) is not reported (plan 053 I14).
    if (copyDirSafe(targetBase, "claude", src, dest, knownHashes))
      console.log(c.green(`  ✓ ${sub}/`));
  }

  chmodHooks(targetClaude);
}

// Every [package file, destination] pair a non-`claude` editor's install writes for one scope
// (plan 047): each generated rule file of adapters/<editor>/rules/ into the rules folder, when the
// scope has one, and every file of adapters/skills/ below the skills folder, in byte order. None
// when the scope has no skills folder. Each editor has its own folders, so uninstalling one never
// removes another editor's files.
function editorFilesFor(base, isGlobal, editor) {
  const cfg = EDITOR_TARGETS[editor];
  const where = cfg && (isGlobal ? cfg.global : cfg.project);
  if (!where || !where.skills) return [];
  const pairs = [];
  const byteOrder = (a, b) => Buffer.compare(Buffer.from(a), Buffer.from(b));
  const rulesSrc = path.join(ADAPTERS_DIR, editor, "rules");
  if (where.rules && fs.existsSync(rulesSrc)) {
    for (const name of fs.readdirSync(rulesSrc).sort(byteOrder)) {
      const src = path.join(rulesSrc, name);
      if (name.startsWith(".") || !fs.statSync(src).isFile()) continue;
      pairs.push([src, path.join(base, ...where.rules.split("/"), name)]);
    }
  }
  const skillsSrc = path.join(ADAPTERS_DIR, "skills");
  if (fs.existsSync(skillsSrc)) {
    const files = walkFiles(skillsSrc)
      .map((f) => toPosix(path.relative(skillsSrc, f)))
      .sort(byteOrder);
    for (const skills of where.skills)
      for (const rel of files)
        pairs.push([
          path.join(skillsSrc, ...rel.split("/")),
          path.join(base, ...skills.split("/"), ...rel.split("/")),
        ]);
  }
  return pairs;
}

// What a kept file at one of the locations plan 047 moved away from means for the editor, the same
// words as install.sh and install.ps1. The package never deletes it for the user:
// .clinerules/default-rules.md is not a path it recorded.
function oldLocationNote(base, editor, rel) {
  const key = `${editor}:${rel}`;
  if (key === "cline:.clinerules") {
    try {
      if (fs.statSync(path.join(base, ".clinerules")).isDirectory())
        return "    Cline moved the old rules to .clinerules/default-rules.md; delete that file if you no longer want them.";
    } catch (_) {
      // nothing there: nothing to say
    }
    return null;
  }
  if (key === "windsurf:.windsurfrules")
    return "    Windsurf still loads .windsurfrules in every conversation; delete it if you no longer want it.";
  if (key === "antigravity:.gemini/antigravity/skills/qa/SKILL.md")
    return "    The Antigravity IDE lists two qa skills while it stays; delete it if you no longer want it.";
  return null;
}

// Installs a non-`claude` editor's rules and skills through the same installFile() safety layer
// (backups, known-hash provenance, symlink/read-only protection) as the claude tree, recorded
// under that editor's own name.
function installNonClaudeEditor(targetBase, isGlobal, editorName, knownHashes) {
  const cfg = EDITOR_TARGETS[editorName];
  const where = isGlobal ? cfg.global : cfg.project;
  if (!where.skills) {
    console.log(
      c.yellow(
        `  ⚠ ${EDITOR_LABELS[editorName]} only supports project-level install — skipping global.`,
      ),
    );
    return;
  }

  if (!fs.existsSync(path.join(ADAPTERS_DIR, "skills", "qa", "SKILL.md"))) {
    console.log(
      c.red(
        `  ✘ Missing adapter for ${EDITOR_LABELS[editorName]} — run ./generate-adapters.sh first.`,
      ),
    );
    return;
  }

  let installed = false;
  for (const [src, dest] of editorFilesFor(targetBase, isGlobal, editorName))
    if (installFile(targetBase, editorName, src, dest, knownHashes))
      installed = true;
  if (!installed) return;
  const folders = [where.rules, ...where.skills]
    .filter(Boolean)
    .map((f) => `${f}/`)
    .join(" and ");
  console.log(c.green(`  ✓ ${EDITOR_LABELS[editorName]}: `) + c.cyan(folders));
}

// Prompts an interactive multi-select menu, used only when init is invoked
// with no --editor flag on a TTY. An empty selection is refused and the prompt
// stays open, as the shell installers' menus ask again on an invalid answer.
async function promptEditors() {
  const { checkbox } = require("@inquirer/prompts");
  return checkbox({
    message: "Which editors do you want to install QA Instinct for?",
    required: true,
    choices: [
      { name: "Claude Code", value: "claude", checked: true },
      { name: "Cursor / Trae", value: "cursor" },
      { name: "Windsurf", value: "windsurf" },
      { name: "GitHub Copilot", value: "copilot" },
      { name: "Cline", value: "cline" },
      { name: "Gemini / Antigravity", value: "antigravity" },
    ],
  });
}

async function cmdInit(opts) {
  const targetBase = resolveTarget(opts);
  migrateManifest(targetBase);
  const isGlobal = opts.global;
  const editorFlag = opts.editor;

  let editors;
  if (editorFlag) {
    editors = editorFlag === "all" ? ALL_EDITORS : [editorFlag];
  } else if (process.stdout.isTTY) {
    editors = await promptEditors();
  } else {
    // No flag, no TTY (CI, piped): preserve pre-existing behavior exactly —
    // install claude only, no prompt, no hang.
    editors = ["claude"];
  }

  console.log(
    `\n${c.bold("qa-instinct")} — installing to ${label(opts, editors)}\n`,
  );
  const knownHashes = loadKnownHashes();

  for (const editor of editors) {
    if (editor === "claude") {
      installClaudeEditor(targetBase, knownHashes);
    } else {
      installNonClaudeEditor(targetBase, isGlobal, editor, knownHashes);
    }
  }

  if (filesWritten === 0) {
    // Every destination was skipped (linked, a folder, unreadable or read-only): nothing to use.
    console.log(
      `\n${c.yellow("Nothing was installed: every destination was skipped (see above).")}\n`,
    );
    return;
  }
  // The words install.sh and install.ps1 print; each editor's line says how to start (plan 062).
  console.log(`\n${c.green("Done!")} Next steps:\n`);
  for (const editor of editors) {
    if (editor === "claude") printClaudeHint();
    else console.log(editorHint(editor, isGlobal));
  }
}

// The next-steps line of a non-Claude editor, the same words as install.sh and install.ps1. A
// global install writes rules for Claude Code and Cline only; the other editors get skills.
function editorHint(editor, isGlobal) {
  const rules = isGlobal
    ? "skills only (a global install writes no rules)"
    : "qa-instinct rules always on";
  // Antigravity's launcher in a plain WSL terminal opens a Windows window whose agent cannot
  // read the folder; a WSL window works (plan 062).
  const wslTip = process.env.WSL_DISTRO_NAME
    ? `\n              : in WSL, open the folder in a WSL window: antigravity-ide --remote wsl+${process.env.WSL_DISTRO_NAME} ${isGlobal ? "<folder>" : process.cwd()}`
    : "";
  const lines = {
    cursor: `  Cursor/Trae : ${rules}; every command, skill and agent is a skill (/qa-cases)`,
    windsurf: `  Windsurf    : ${rules}; every command, skill and agent is a skill (@qa-cases)`,
    copilot: `  Copilot     : ${isGlobal ? rules : "rules in .github/copilot-instructions.md"}; every command, skill and agent is a skill (/qa-cases)`,
    cline:
      "  Cline       : qa-instinct rules always on; every command, skill and agent is a skill (/qa-cases)",
    antigravity: `  Antigravity : ${rules}; every command, skill and agent is a skill (ask for qa-cases)${wslTip}`,
  };
  return lines[editor];
}

// Lists what the package ships, read from its own .claude/ at run time, so a new command, skill
// or agent shows up here with no edit. The same block in install.sh and install.ps1 (plan 033
// item 8). Rules are counted, not named.
function printClaudeHint() {
  const names = (sub, keep) =>
    fs
      .readdirSync(path.join(PKG_CLAUDE, sub), { withFileTypes: true })
      .filter(keep)
      .map((e) => e.name.replace(/\.md$/, ""))
      .sort();
  const isMd = (e) => e.isFile() && e.name.endsWith(".md");
  const commands = names(
    "commands",
    (e) => isMd(e) && e.name.startsWith("qa-"),
  ).map((n) => `/${n}`);
  const skills = names("skills", (e) => e.isDirectory());
  const agents = names("agents", isMd);
  const rules = names("rules", isMd).length;
  console.log("  Claude Code : type /qa to start");
  console.log(`              : commands : ${commands.join(" ")}`);
  console.log(`              : skills   : ${skills.join(" ")}`);
  console.log(`              : agents   : ${agents.join(" ")}`);
  console.log(
    `              : rules    : ${rules} files in .claude/rules/ (always loaded)\n`,
  );
}

function cmdUninstallInit(opts) {
  const targetBase = resolveTarget(opts);
  const targetClaude = path.join(targetBase, ".claude");
  const isGlobal = opts.global;
  const editorFlag = opts.editor;
  // No flag: uninstall only `claude`, matching init's own backward-compatible
  // default — a bare `qa-instinct uninstall` behaves exactly as it always has.
  const editors = editorFlag
    ? editorFlag === "all"
      ? ALL_EDITORS
      : [editorFlag]
    : ["claude"];

  console.log(
    `\n${c.bold("qa-instinct")} — uninstalling from ${label(opts, editors)}\n`,
  );

  migrateManifest(targetBase);
  const hadManifest = fs.existsSync(manifestFile(targetBase));
  let removed = 0,
    kept = 0;

  for (const editor of editors) {
    const result = uninstallRecorded(targetBase, editor);
    removed += result.removed;
    kept += result.kept;
    const removedRels = [...result.removedRels];

    if (editor === "claude" && !hadManifest) {
      // Installed before manifests existed: fall back to removing only files whose
      // content still matches the package's current copy. Only for `claude`: the
      // other editors' destinations were never written without a manifest (the
      // shell installers wrote other paths before 2.3.3), so a match there could
      // only be a copy the user made (plan 047, review of #193).
      for (const sub of SUBDIRS) {
        const src = path.join(PKG_CLAUDE, sub);
        if (!fs.existsSync(src)) continue;
        if (linkedIntoPackage(path.join(targetClaude, sub))) {
          console.log(
            c.cyan(
              `  i Skipped ${sub}/ — it is a link to the package; run 'qa-instinct unlink' instead`,
            ),
          );
          continue;
        }
        for (const file of walkFiles(src)) {
          const relToSub = path.relative(src, file);
          const dest = path.join(targetClaude, sub, relToSub);
          const result2 = removeIfMatches(targetBase, file, dest);
          if (result2 === "removed") {
            removed++;
            removedRels.push(toPosix(path.relative(targetBase, dest)));
          } else if (result2 === "kept") kept++;
        }
      }
    }

    if (removedRels.length > 0) {
      // The folders this run emptied, up to the base and never inside a linked one: those of
      // each file it removed and the package's own folders of this editor (for Claude Code, its
      // five folders and .claude). A folder of an editor with nothing removed is never touched,
      // nor one this run did not empty (plan 047; for Claude Code, plan 061 L1).
      const own =
        editor === "claude"
          ? SUBDIRS.map((sub) => `.claude/${sub}/-`)
          : editorFilesFor(targetBase, isGlobal, editor).map(([, dest]) =>
              toPosix(path.relative(targetBase, dest)),
            );
      const rels = [...removedRels, ...own];
      for (const rel of rels) {
        if (!linkedAncestor(targetBase, rel))
          removeEmptyDirChain(
            path.dirname(path.join(targetBase, ...rel.split("/"))),
            targetBase,
          );
      }
    }
  }

  if (kept > 0) {
    console.log(
      c.yellow(
        `\n  ! Partially uninstalled — removed ${removed} file(s), kept ${kept}.`,
      ),
    );
  } else if (removed === 0) {
    console.log(c.cyan("\n  i Nothing to remove (not installed)."));
  } else {
    console.log(c.green(`\n  ✓ Removed ${removed} file(s).`));
  }
  console.log("");
}

// Windows creates a symlink only with Developer Mode on or in an elevated shell, and answers
// EPERM otherwise. There, link falls back to a directory junction, which needs no privilege on an
// NTFS drive; Node reports a junction as a symbolic link (lstat, readlink, realpath), so unlink,
// uninstall and every linked-folder check treat it as one (plan 046 item 4). One throwaway link,
// made before link changes anything, finds out which kind can be made, so a refusal never leaves a
// new .claude folder or a removed stale link behind (plan 037). Returns "dir", "junction", or
// { error } when neither can be made.
function dirLinkType(dir) {
  const probe = path.join(
    fs.existsSync(dir) ? dir : os.tmpdir(),
    `.qa-instinct-link-probe-${process.pid}-${crypto.randomBytes(6).toString("hex")}`,
  );
  const types = process.platform === "win32" ? ["dir", "junction"] : ["dir"];
  let error = null;
  for (const type of types) {
    try {
      fs.symlinkSync(PKG_CLAUDE, probe, type);
    } catch (err) {
      // A junction that fails for any reason (a drive that is not NTFS, a package on a network
      // share) leaves nothing else to try.
      if (err.code !== "EPERM" && type !== "junction") throw err;
      error = err;
      continue;
    }
    fs.rmSync(probe);
    return type;
  }
  return { error };
}

function cmdLink(opts) {
  const targetBase = resolveTarget(opts);
  const targetClaude = path.join(targetBase, ".claude");

  console.log(`\n${c.bold("qa-instinct")} — linking to ${label(opts)}\n`);
  const linkType = dirLinkType(targetBase);
  if (typeof linkType !== "string") {
    const why =
      process.platform === "win32"
        ? `Windows allows them only with Developer Mode on or in an elevated shell, and a directory junction could not be made either (${linkType.error.code || linkType.error.message}; junctions need an NTFS drive): turn Developer Mode on and run link again, or run 'qa-instinct init' to install copies instead.`
        : "this system refused one (EPERM): run 'qa-instinct init' to install copies instead.";
    console.error(
      c.red(
        `Error: cannot create symbolic links here. ${why} Nothing was linked.`,
      ),
    );
    process.exit(1);
  }
  if (linkType === "junction") {
    console.log(
      c.cyan(
        "  i Symbolic links need Developer Mode or an elevated shell here, so the folders are linked with directory junctions instead.",
      ),
    );
  }
  ensureDir(targetClaude);

  for (const sub of SUBDIRS) {
    const src = path.join(PKG_CLAUDE, sub);
    const dest = path.join(targetClaude, sub);
    if (!fs.existsSync(src)) continue;

    if (fs.existsSync(dest) || isSymlink(dest)) {
      if (isSymlink(dest)) {
        if (!isQaInstinctLink(dest, sub)) {
          console.log(
            c.yellow(
              `  ! Kept ${sub}/ — the link does not point to a qa-instinct package`,
            ),
          );
          continue;
        }
        fs.rmSync(dest); // stale link — refresh
      } else {
        console.log(
          c.yellow(
            `  ⚠ skipped ${sub}/ (already exists as a real directory — remove or rename it first; 'qa-instinct uninstall' removes an install made with init)`,
          ),
        );
        continue;
      }
    }

    fs.symlinkSync(src, dest, linkType);
    console.log(c.green(`  ✓ ${sub}/`) + c.cyan(` → ${src}`));
  }

  console.log(
    `\n${c.green("Done!")} Updating the npm package will automatically reflect here.\n`,
  );
}

function cmdUnlink(opts) {
  const targetBase = resolveTarget(opts);
  const targetClaude = path.join(targetBase, ".claude");

  console.log(`\n${c.bold("qa-instinct")} — unlinking from ${label(opts)}\n`);

  let removed = 0;
  for (const sub of SUBDIRS) {
    const dest = path.join(targetClaude, sub);
    if (isSymlink(dest)) {
      if (!linkedIntoPackage(dest)) {
        console.log(
          c.yellow(
            `  ! Kept ${sub}/ — the link does not point to this package`,
          ),
        );
        continue;
      }
      fs.rmSync(dest);
      console.log(c.green(`  ✓ removed symlink: ${sub}/`));
      removed++;
    }
  }

  if (removed === 0) {
    console.log(c.yellow("  No qa-instinct symlinks found.\n"));
  } else {
    console.log(`\n${c.green("Done!")}\n`);
  }
}

// Maps a `claude` manifest entry back to the package file it came from, so update
// can tell "still shipped, refresh it" from "dropped, remove it". `rel` is the
// manifest's own relative-to-base path (e.g. ".claude/rules/foo.md"). A
// non-claude editor's entries are looked up in editorFilesFor instead.
function editorSourcePath(editor, rel) {
  if (editor === "claude") {
    const relInClaude = rel.split("/").slice(1); // drop the leading ".claude"
    return path.join(PKG_CLAUDE, ...relInClaude);
  }
  return null;
}

// The hash of what is installed at `file`, or null when nothing is: a missing file, and a symlink,
// which update replaces without reading through it, so the file is reported restored, as in
// install.sh and install.ps1.
function installedHash(file) {
  try {
    return fs.lstatSync(file).isFile() ? hashFile(file) : null;
  } catch (_) {
    return null;
  }
}

// Rewrites the manifest with the named (editor, rel) entries removed — used
// when update drops a file the package no longer ships. Whether the file
// itself was removed or kept (because the user changed it), it is no longer
// "installed by us" in any trackable sense, mirroring uninstallRecorded's
// own reasoning above.
function removeManifestEntries(base, editor, rels) {
  const mf = manifestFile(base);
  if (rels.length === 0 || !fs.existsSync(mf)) return;
  const drop = new Set(rels);
  const entries = readPortableLines(mf)
    .map(parseManifestLine)
    .filter((e) => e && !(e.editor === editor && drop.has(e.rel)));
  writeManifest(mf, entries);
}

// Item 1 + 2 of plan 013: for one editor's manifest entries, refresh every
// file the current package still ships (through installFile, so the safety
// contract — backup, known-hash adoption, read-only skip, symlink guard — is
// inherited rather than reimplemented), and remove the ones it no longer
// ships, but only when the file on disk is still exactly what was installed.
// A file the user changed is left alone and reported, whether or not the
// package still ships it.
function updateManifestEditor(base, isGlobal, editor, knownHashes, report) {
  const mf = manifestFile(base);
  if (!fs.existsSync(mf)) return;
  // For a non-claude editor, "still shipped" is "a destination this install writes" (plan 047):
  // every other recorded path, the old merged adapters and .bem-te-vi/ included, is not.
  const shipped = new Map(
    editor === "claude"
      ? []
      : editorFilesFor(base, isGlobal, editor).map(([src, dest]) => [
          toPosix(path.relative(base, dest)),
          src,
        ]),
  );

  const entries = readPortableLines(mf)
    .map(parseManifestLine)
    .filter((e) => e && e.editor === editor);

  const dropFromManifest = [];

  for (const e of entries) {
    if (!isSafeManifestRel(base, e.rel)) {
      console.log(
        c.red(
          `  ✘ Refusing ${e.rel} — it points outside ${base}. The manifest may have been tampered with.`,
        ),
      );
      continue;
    }
    const dest = path.join(base, ...e.rel.split("/"));
    const src =
      editor === "claude"
        ? editorSourcePath(editor, e.rel)
        : shipped.get(e.rel) || null;
    const linked = linkedAncestor(base, e.rel);

    if (!src || !fs.existsSync(src)) {
      if (linked) {
        // Kept, and still recorded: the file is not ours to delete through a link.
        reportLinkedDir(base, linked, "Kept", "deleted");
        report.keptSkipped++;
        continue;
      }
      // The package no longer ships this file — item 2.
      if (!fs.existsSync(dest)) {
        dropFromManifest.push(e.rel); // already gone; just drop the stale record
        continue;
      }
      if (fs.statSync(dest).isDirectory()) {
        // Never hashed, entered or deleted (plan 047): Cline turns its .clinerules file into a
        // folder. Kept and forgotten, like any changed file the package stopped shipping.
        report.keptDirectory.push(e.rel);
        const note = oldLocationNote(base, editor, e.rel);
        if (note) report.notes.push(note);
        dropFromManifest.push(e.rel);
        continue;
      }
      let unchanged = false;
      try {
        unchanged = fileMatches(dest, e.hash);
      } catch (_) {
        // unreadable: treat as changed, and keep it
      }
      let writable = true;
      try {
        fs.accessSync(dest, fs.constants.W_OK);
      } catch (_) {
        writable = false;
      }
      if (!writable) {
        // Read-only is a deliberate signal, on removal as on install (see uninstallRecorded).
        report.keptReadOnly.push(e.rel);
      } else if (isUnreadable(dest)) {
        report.keptUnreadable.push(e.rel);
      } else if (unchanged) {
        fs.rmSync(dest);
        report.removed.push(e.rel);
        // Its folders go while they are empty, up to the base (plan 047); none is a link, as
        // linkedAncestor found none above.
        if (editor !== "claude") removeEmptyDirChain(path.dirname(dest), base);
      } else {
        report.keptModified.push(e.rel);
        const note = oldLocationNote(base, editor, e.rel);
        if (note) report.notes.push(note);
      }
      dropFromManifest.push(e.rel);
      continue;
    }

    if (linked) {
      reportLinkedDir(base, linked, "Skipped", "written");
      report.keptSkipped++;
      continue;
    }

    // Still shipped — refresh it. installFile backs up a user edit, adopts a
    // known-hash match silently, skips a read-only destination, and never
    // writes through a symlink; it also re-records the manifest hash itself.
    const beforeHash = installedHash(dest);
    const written = installFile(base, editor, src, dest, knownHashes);
    const afterHash = installedHash(dest);
    if (!written && afterHash === null)
      report.keptSkipped++; // a folder, never written into
    else if (beforeHash === null) report.restored.push(e.rel);
    else if (beforeHash === afterHash) report.upToDate.push(e.rel);
    else report.refreshed.push(e.rel);
  }

  // Every file the package now ships that this install predates is installed the same way init
  // would install it, so a colliding user file is backed up (decided 2026-10-14, plan 033 item 3).
  // Only for an editor the manifest records: update never installs a new editor.
  if (entries.length > 0) {
    const recorded = new Set(entries.map((e) => e.rel));
    for (const [src, dest] of packageFilesFor(base, isGlobal, editor)) {
      const rel = toPosix(path.relative(base, dest));
      if (recorded.has(rel)) continue;
      installFile(base, editor, src, dest, knownHashes);
      if (manifestLookup(base, editor, rel)) report.added.push(rel);
    }
  }

  removeManifestEntries(base, editor, dropFromManifest);
  if (editor === "claude") chmodHooks(path.join(base, ".claude"));
}

// Every [package file, destination] pair init installs for one editor.
function packageFilesFor(base, isGlobal, editor) {
  if (editor === "claude") {
    const pairs = [];
    for (const sub of SUBDIRS) {
      const src = path.join(PKG_CLAUDE, sub);
      if (!fs.existsSync(src)) continue;
      for (const file of walkFiles(src))
        pairs.push([
          file,
          path.join(base, ".claude", sub, path.relative(src, file)),
        ]);
    }
    return pairs;
  }
  return editorFilesFor(base, isGlobal, editor);
}

// Item 3 of plan 013: pre-manifest install. Only ever touches a destination
// that already exists — update must never create a file that isn't already
// there, which is what would turn "adopt" into a silent install. A file is
// adopted only when its hash proves the package shipped it (identical to the
// current package file, or a hash in the known-hash list); anything else at
// that path is the user's, untouched, and not even reported (it was never
// ours to report on).
function detectAdoptOne(base, editor, src, dest, knownHashes, report) {
  const linked = linkedAncestor(base, toPosix(path.relative(base, dest)));
  if (linked) {
    if (fs.existsSync(dest)) {
      reportLinkedDir(base, linked, "Skipped", "written");
      report.keptSkipped++;
    }
    return;
  }
  if (!fs.existsSync(dest)) return;
  let known = false;
  try {
    known = fileMatches(dest, hashFile(src)) || isKnownFile(dest, knownHashes);
  } catch (_) {
    // unreadable: not provably ours, so leave it alone
  }
  if (!known) return;
  installFile(base, editor, src, dest, knownHashes);
  report.adopted.push(toPosix(path.relative(base, dest)));
}

function detectAndAdoptEditor(base, isGlobal, editor, knownHashes, report) {
  if (editor === "claude") {
    const targetClaude = path.join(base, ".claude");
    for (const sub of SUBDIRS) {
      const src = path.join(PKG_CLAUDE, sub);
      if (!fs.existsSync(src)) continue;
      for (const file of walkFiles(src)) {
        const relToSub = path.relative(src, file);
        const dest = path.join(targetClaude, sub, relToSub);
        detectAdoptOne(base, "claude", file, dest, knownHashes, report);
      }
    }
    chmodHooks(targetClaude);
    return;
  }

  for (const [src, dest] of editorFilesFor(base, isGlobal, editor))
    detectAdoptOne(base, editor, src, dest, knownHashes, report);
}

// Reports what happened, in the same three-outcome shape as
// cmdUninstallInit's summary: nothing there / all clean / partial with
// counts. "Everything is up to date" is only ever printed when a manifest
// (or a pre-manifest install) actually exists — otherwise nothing was
// installed in the first place, and update must say so rather than imply
// there was something to be up to date about.
function printUpdateReport(report) {
  for (const rel of report.refreshed)
    console.log(c.green(`  ✓ Refreshed ${rel}`));
  for (const rel of report.restored)
    console.log(c.green(`  ✓ Restored ${rel} (was missing)`));
  for (const rel of report.added) console.log(c.green(`  ✓ Added ${rel}`));
  for (const rel of report.adopted) console.log(c.green(`  ✓ Adopted ${rel}`));
  for (const rel of report.removed)
    console.log(c.yellow(`  - Removed ${rel} (no longer shipped)`));
  for (const rel of report.keptModified)
    console.log(c.yellow(`  ! Kept ${rel} — changed since it was installed`));
  for (const rel of report.keptReadOnly)
    console.log(c.yellow(`  ! Kept ${rel} — destination is read-only`));
  for (const rel of report.keptUnreadable)
    console.log(c.yellow(`  ! Kept ${rel} — destination cannot be read`));
  for (const rel of report.keptDirectory)
    console.log(
      c.yellow(
        `  ! Kept ${rel} — it is a directory now, not the file that was installed`,
      ),
    );
  for (const note of report.notes) console.log(c.yellow(note));

  const changed =
    report.refreshed.length +
    report.restored.length +
    report.added.length +
    report.adopted.length +
    report.removed.length;
  const keptAsIs =
    report.keptModified.length +
    report.keptReadOnly.length +
    report.keptUnreadable.length +
    report.keptDirectory.length +
    report.keptSkipped;
  const total = changed + report.upToDate.length + keptAsIs;
  console.log("");
  if (total === 0) {
    console.log(
      c.cyan("  i Nothing installed — run 'qa-instinct init' first.\n"),
    );
    return;
  }
  if (keptAsIs > 0) {
    console.log(
      c.yellow(
        `  ! Update complete — ${keptAsIs} file(s) kept as-is (see above).\n`,
      ),
    );
  } else if (changed === 0) {
    console.log(c.green("  ✓ Everything is up to date.\n"));
  } else {
    console.log(c.green("  ✓ Update complete.\n"));
  }

  // update refreshes files from whatever version of the package is running
  // this command right now — it has no way to check or fetch a newer release
  // of itself. Only worth saying when something was actually written or
  // removed; on "up to date" or "nothing installed" there is nothing stale
  // to warn about.
  if (changed > 0) {
    console.log(
      c.cyan("  Note: ") +
        "this refreshed files from the qa-instinct version currently running " +
        "this command — it cannot update the package itself. To pick up a " +
        "newer release, run 'npm update -g qa-instinct' first, " +
        "then 'qa-instinct update' again.\n",
    );
  }
}

function cmdUpdate(opts) {
  const targetBase = resolveTarget(opts);
  const isGlobal = opts.global;
  const editorFlag = opts.editor;
  const knownHashes = loadKnownHashes();
  migrateManifest(targetBase);
  const hasManifest = fs.existsSync(manifestFile(targetBase));

  // With no editor named, update refreshes every editor the manifest records.
  const labelEditors =
    editorFlag && editorFlag !== "all" ? [editorFlag] : ALL_EDITORS;
  console.log(
    `\n${c.bold("qa-instinct update")} — refreshing ${label(opts, labelEditors)}\n`,
  );

  const report = {
    refreshed: [],
    restored: [],
    upToDate: [],
    removed: [],
    keptModified: [],
    keptReadOnly: [],
    keptUnreadable: [],
    keptDirectory: [],
    notes: [],
    keptSkipped: 0,
    added: [],
    adopted: [],
  };

  if (hasManifest) {
    // No --editor: every editor the manifest actually records — not every
    // editor this package supports, since most were never installed here.
    const manifestEditors = [
      ...new Set(
        readPortableLines(manifestFile(targetBase))
          .map(parseManifestLine)
          .filter(Boolean)
          .map((e) => e.editor),
      ),
    ];
    const editors = editorFlag
      ? editorFlag === "all"
        ? ALL_EDITORS
        : [editorFlag]
      : manifestEditors;

    for (const editor of editors) {
      updateManifestEditor(targetBase, isGlobal, editor, knownHashes, report);
    }
  } else {
    // No manifest: either a pre-manifest install (adopt it) or nothing
    // installed at all (do nothing) — detectAndAdoptEditor tells those apart
    // by only ever touching a destination that already exists.
    const editors = editorFlag
      ? editorFlag === "all"
        ? ALL_EDITORS
        : [editorFlag]
      : ALL_EDITORS;

    for (const editor of editors) {
      detectAndAdoptEditor(targetBase, isGlobal, editor, knownHashes, report);
    }
  }

  printUpdateReport(report);
}

function cmdHelp(print = console.log) {
  const { version } = require("../package.json");
  print(`
${c.bold("qa-instinct")} v${version} — QA skills for AI editors

${c.bold("Usage:")}
  qa-instinct init      [--global] [--editor <name>]
  qa-instinct uninstall [--global] [--editor <name>]
  qa-instinct update    [--global] [--editor <name>]
  qa-instinct link      [--global]
  qa-instinct unlink    [--global]
  qa-instinct --version

${c.bold("Commands:")}
  ${c.cyan("init")}       Copy QA skills into your editor(s) (project or global)
  ${c.cyan("uninstall")}  Remove files copied by init/update, keeping anything you changed
  ${c.cyan("link")}       Symlink QA skills into .claude/ — stays up-to-date with npm updates
  ${c.cyan("unlink")}     Remove qa-instinct symlinks from .claude/
  ${c.cyan("update")}     Refresh installed files to this package's version, add files it now ships, drop ones it no longer ships

${c.bold("Flags:")}
  ${c.cyan("--global")}          Target ~/.claude/ (or the editor's own global path) instead of the current project
  ${c.cyan("--editor <name>")}   ${ALL_EDITORS.join(", ")}, or all. Default: claude for init and uninstall.
                    With no --editor, 'init' shows an interactive menu on a
                    TTY, or installs claude only when not (CI, piped).
                    'update' defaults differently: every editor recorded in
                    the manifest, or (with no manifest) every supported
                    editor's known path, scanned to detect a pre-manifest
                    install. It never installs an editor that wasn't already
                    installed — with nothing installed, it does nothing.
                    Refreshing does not check npm for a newer release; run
                    'npm update -g qa-instinct' first for that.
  ${c.cyan("--version, -v")}     Print the version and exit (alone, before any command)

${c.bold("Examples:")}
  qa-instinct init                    # interactive menu on a TTY, claude-only otherwise
  qa-instinct init --editor cursor    # copy to current project for Cursor
  qa-instinct init --editor all       # copy for every supported editor
  qa-instinct init --global           # copy to ~/.claude/ (all projects)
  qa-instinct uninstall               # remove claude files copied by init/update
  qa-instinct uninstall --editor all  # remove every installed editor's files
  qa-instinct update                  # refresh whatever editors the manifest records
  qa-instinct update --global         # refresh ~/.qa-instinct-manifest's install instead
  qa-instinct link                    # symlink in current project
  qa-instinct link --global           # symlink in ~/.claude/
  qa-instinct unlink                  # remove symlinks from current project
`);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

const [, , command, ...args] = process.argv;

(async () => {
  if (command === undefined || ["help", "--help", "-h"].includes(command)) {
    cmdHelp();
    return;
  }
  // Only as the first word: after a command it is an unknown option, refused by parseArgs.
  if (["--version", "-v"].includes(command)) {
    console.log(`qa-instinct ${require("../package.json").version}`);
    return;
  }
  if (!Object.hasOwn(COMMAND_OPTIONS, command)) {
    console.error(c.red(`Error: unknown command '${command}'`));
    cmdHelp(console.error);
    process.exit(1);
  }
  const opts = parseArgs(command, args);
  switch (command) {
    case "init":
      await cmdInit(opts);
      break;
    case "uninstall":
      cmdUninstallInit(opts);
      break;
    case "link":
      cmdLink(opts);
      break;
    case "unlink":
      cmdUnlink(opts);
      break;
    case "update":
      cmdUpdate(opts);
      break;
  }
})();
