# Demo recording script

> **Superseded, 2026-10-18 (plan 049).** The demo is now scripted and rendered with VHS from
> [`demo/qa-instinct.tape`](../demo/qa-instinct.tape) (`demo/bem-te-vi.tape` until plan 065); see
> [`demo/README.md`](../demo/README.md) to re-record it. This storyboard for recording by hand is
> kept as the record of plan 019 phase 7.

For recording the README's demo GIF yourself (plan 019 phase 7). An interactive AI session can't be
recorded from a script, so this is a storyboard to follow by hand. Until the GIF exists, the
README's "See It Work" section shows real output from [`serverest/`](serverest/).

## Setup

```bash
# Tools: asciinema to record, agg to turn the recording into a GIF
pipx install asciinema           # or: brew install asciinema
cargo install --git https://github.com/asciinema/agg   # or download a release binary

# A clean, empty project
mkdir -p ~/demo/serverest-cart && cd ~/demo/serverest-cart && git init -q

# Terminal: about 100x30 characters, a large font, a dark theme, a short prompt
export PS1='$ '
```

## Storyboard (about 60-90 seconds)

| # | On screen | Command | Hold |
| --- | --- | --- | --- |
| 1 | Install into the empty project | `npx @marcoamaral/bem-te-vi init --editor claude` | Let the "installed" summary show |
| 2 | Show what was installed | `ls .claude` | 2 s |
| 3 | Start Claude Code | `claude` | — |
| 4 | Ask for a static review of a real spec | `/qa-static review the cart rules in https://serverest.dev/swagger.json (the /carrinhos section)` | Scroll to the findings table and the verdict |
| 5 | Ask for test cases | `/qa-cases a customer can't add the same product to the cart twice (ServeRest /carrinhos)` | Let two or three TC blocks show |
| 6 | Exit | `/exit` | — |

Keep it real: no edited output, and say in the README which model and date it was recorded with.

## Record and convert

```bash
asciinema rec demo.cast          # follow the storyboard, then exit the shell to stop
agg --theme monokai --font-size 20 --speed 1.5 demo.cast demo.gif
```

Then add `demo.gif` (keep it under ~5 MB) to the repository and reference it at the top of the
README's "See It Work" section, above the two `<details>` blocks.
