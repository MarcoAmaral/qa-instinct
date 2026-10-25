# shellcheck shell=bash
# demo/shell.sh: sourced by the hidden setup of demo/qa-instinct.tape (plan 049). Not run directly.
#
# It sets a bare prompt, enters the throwaway project demo/record.sh prepared, and wraps `claude`
# so the recorded run is isolated from the recording machine's own Claude Code configuration:
#   --setting-sources project    only the project's .claude/ (the package just installed)
#   --strict-mcp-config          no MCP servers
#   --no-session-persistence     no session saved to disk
#   --permission-mode acceptEdits  may write TC-CART.md without a prompt
#   --max-budget-usd 0.50        a hard cost cap for the run
# The run's JSON (model, turns, cost) is saved to $DEMO_LOG, off screen; only its `result`, the
# model's reply exactly as print mode would show it, is printed.

PS1='$ '
cd "${DEMO_WORK:?set by demo/record.sh}" || return 1

claude() {
  command claude --setting-sources project --strict-mcp-config --no-session-persistence \
    --permission-mode acceptEdits --max-budget-usd 0.50 --output-format json "$@" \
    >"${DEMO_LOG:?set by demo/record.sh}"
  node -e '
    const run = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    process.stdout.write((run.result ?? JSON.stringify(run)) + "\n");
  ' "$DEMO_LOG"
}
