# Test Evidence Rules & Guidelines

> **Evidence Is a Deliverable** | Viewport Screenshots | Reviewed Recordings | ASCII-Only Names

This ruleset governs the evidence a test produces: the screenshots and recordings that prove to a
reviewer that a test ran and passed. The `code-style-qa` rule covers how test code is
written; this rule covers what the run leaves behind. AI agents must apply it whenever they write
automation that captures screenshots or video, or hand evidence to a reviewer.

**A green run is not evidence of the recording.** A test can pass and still leave an unreadable,
empty or misleading artifact. The artifact has to be opened and looked at.

---

## Hard Rules

1. **Viewport, not full page**: one fixed viewport size (default 1440×900); never `fullPage: true`.
2. **No element crops**: never a locator's own `.screenshot()`.
3. **Visible pointer and case label** in every frame; the capture helper fails loudly without them.
4. **Open every recording** (look at a mid-video frame) before calling it evidence.
5. **ASCII-only file names**, e.g. `TC-CART-001-total.png`.
6. **Run the checker** first: `check-test-evidence.sh <spec-dir>` (Claude Code: `.claude/hooks/`; not installed: check the specs by reading them and say it was not run). With `--runner-standard` it also flags `page.goto(` without a `goto-ok:` reason and bare `.click(`; a probe (reconnaissance) never captures evidence.

Code examples, the skipped-test recording trap and pacing: the `qa-reference` skill's `references/evidence-capture.md`.
