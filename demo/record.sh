#!/usr/bin/env bash
# demo/record.sh: renders the README demo (demo/qa-instinct.gif, .mp4, .webm) from
# demo/qa-instinct.tape (plan 049). Run it from anywhere; it works from the repository root.
#
# Needs on PATH: vhs, ttyd, ffmpeg, node, npm and a signed-in `claude`; VHS also needs a Chrome or
# Chromium. Costs one live Claude Code run on Claude Sonnet, capped at US$0.50 by demo/shell.sh.
#
# It packs this tree with `npm pack`, installs the tarball into a temporary npm prefix (nothing is
# installed globally), creates the throwaway project $DEMO_WORK (default /tmp/demo) with
# demo/story.md in it, and records. It refuses to reuse an existing $DEMO_WORK rather than delete it.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${DEMO_WORK:-/tmp/demo}"

for tool in vhs ttyd ffmpeg node npm claude; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "record.sh: '$tool' is not on PATH" >&2
    exit 1
  fi
done
if [ -e "$WORK" ]; then
  echo "record.sh: $WORK already exists; remove it or set DEMO_WORK to a new folder" >&2
  exit 1
fi

TOOLS="$(mktemp -d)"
(cd "$ROOT" && npm pack --ignore-scripts --silent --pack-destination "$TOOLS" >/dev/null)
npm install --prefix "$TOOLS" --ignore-scripts --no-audit --no-fund --silent "$TOOLS"/*.tgz

mkdir -p "$WORK"
cp "$ROOT/demo/story.md" "$WORK/story.md"

export PATH="$TOOLS/node_modules/.bin:$PATH"
export DEMO_WORK="$WORK" DEMO_SHELL="$ROOT/demo/shell.sh" DEMO_LOG="$TOOLS/claude-run.json"

cd "$ROOT"
vhs demo/qa-instinct.tape

# What the recorded run was: the numbers demo/README.md records.
node -e '
  const run = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  console.log("models:", Object.keys(run.modelUsage || {}).join(", "));
  console.log("turns:", run.num_turns, " duration_ms:", run.duration_ms,
    " cost_usd:", run.total_cost_usd);
' "$DEMO_LOG"

# The hook again, outside the recording: the demo must end on a file that passes it.
"$WORK/.claude/hooks/validate-tc-format.sh" "$WORK/TC-CART.md"
echo "Run JSON: $DEMO_LOG  Project: $WORK"
