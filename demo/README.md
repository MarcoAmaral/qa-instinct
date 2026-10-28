# The README demo

`qa-instinct.gif` (shown at the top of the README) and `qa-instinct.mp4` are rendered from
[`qa-instinct.tape`](qa-instinct.tape) by [VHS](https://github.com/charmbracelet/vhs), so the demo can be
made again for each release with one command instead of being re-recorded by hand (plan 049).

## What it shows

One clip, in one terminal, from an empty folder:

1. `qa-instinct init --editor claude` installs the package into the project.
2. `cat story.md` shows the story: the ServeRest cart story the [examples](../examples/README.md)
   use, cut to three acceptance criteria ([`story.md`](story.md)).
3. `claude -p --model sonnet "/qa-cases story.md. Save the test cases as TC-CART.md."` runs the
   `/qa-cases` command in Claude Code's print mode, which prints the model's final reply.
4. `grep '^## TC-' TC-CART.md` lists the test cases it wrote.
5. `.claude/hooks/validate-tc-format.sh TC-CART.md`, the package's own format hook, passes on them.

The model's reply and the file are real output of one live run, not edited. The one cut is the
model's wait: the tape hides the frames between pressing Enter and the prompt coming back (about 79
seconds of a blank screen in the recorded run). [`TC-CART.md`](TC-CART.md) is the file that run
wrote, committed as written.

## The last recording

| Item | Value |
| ---- | ----- |
| Date | 2026-10-25 |
| Package | 4.2.0, the first release named QA Instinct (`main` at `de5e010`), packed from the tree with `npm pack` |
| Claude Code | 2.1.291 |
| Model | Claude Sonnet 5.5 (`claude-sonnet-5-5`), the only model the run used |
| Run | 10 turns, 78.5 s, US$0.3096 (input 10 + cache write 43,459 + cache read 183,165 tokens; output 9,914) |
| Result | 9 test cases (3 from the acceptance criteria, 6 marked "Added by QA"); the hook passed |
| GIF | 1200 x 760, 25 fps, 43 s, 1.5 MB (1,492,303 bytes) |
| MP4 | the same clip, 1.2 MB (1,188,657 bytes), committed beside the GIF; GitHub does not play a repository video inside a README, so the README shows the GIF |

### Honest limits of the recorded run

- The model's reply says the format hook did not run, because the command needed approval; the
  clip runs it next, and it passes.
- Request shapes, status codes and message texts come from the model's general knowledge of
  ServeRest, not from the API: the file lists five unverified assumptions (A-1 to A-5) and the
  cases cite them, and no case quotes an error message's text.
- TC-CART-005 (same product, different quantities) rests on the model's reading of "the same
  product twice", which the reply leaves for the product owner; TC-CART-008's 401 is an assumption
  the story does not state; TC-CART-009 depends on assumption A-5, the cart removal endpoint.
- No tracker was named, so every Issue row reads `[ISSUE-ID]`, and the `@gate` marking is a
  proposal until a release gate is defined.
- The reply names the project folder (`/tmp/demo`), the throwaway folder `record.sh` creates.
- None of the nine cases was run against ServeRest. The hook checks the format (every field
  present and filled, a source for every case), not whether an expected result is right. Real runs
  against the live API are in [`examples/serverest/`](../examples/serverest/).
- A different run, or a different model, writes different cases: the clip shows one run. The
  previous recordings wrote nine cases (2026-10-20, Claude Sonnet 5.5, under the name Bem-te-vi)
  and six (2026-10-18, Claude Haiku 4.5).

## Re-record it

You need, on `PATH`: [VHS](https://github.com/charmbracelet/vhs) (v0.12.1 was used),
[ttyd](https://github.com/tsl0922/ttyd) (1.7.7), `ffmpeg`, a Chrome or Chromium (VHS drives it
headless), `node`, `npm`, and a signed-in Claude Code (`claude`). VHS and ttyd publish Linux
binaries with checksums on their GitHub releases; no root access is needed to put them in
`~/.local/bin`.

```bash
demo/record.sh
```

The script packs this tree with `npm pack`, installs the tarball into a temporary npm prefix
(nothing is installed globally), creates the throwaway project `/tmp/demo` (or `$DEMO_WORK`) with
`story.md` in it, and runs `vhs demo/qa-instinct.tape` from the repository root. It refuses to reuse an
existing project folder rather than delete it. At the end it prints the run's model, turns and
cost, and runs the hook again on the file the run wrote. Then watch the result before committing:
extract a few frames (`ffmpeg -i demo/qa-instinct.gif -vf fps=1/4 frame-%02d.png`) and check that the
text is legible and nothing private shows. Update "The last recording" above.

A run costs about US$0.25 on Claude Sonnet; [`shell.sh`](shell.sh) caps it at US$0.50.

## What the hidden setup does

The tape's first lines are hidden: they source [`shell.sh`](shell.sh), which sets a bare `$` prompt,
enters the project, and wraps `claude` so the recorded run ignores the recording machine's own
Claude Code configuration: only the project's settings (`--setting-sources project`), no MCP
servers (`--strict-mcp-config`), no session saved (`--no-session-persistence`), file writes without
a prompt (`--permission-mode acceptEdits`), and a cost cap (`--max-budget-usd 0.50`). The wrapper
asks for JSON output, saves it off screen for the numbers above, and prints only its `result`: the
model's reply exactly as plain print mode would print it.

`demo/` is not part of the npm package (`package.json` `files` does not list it).
