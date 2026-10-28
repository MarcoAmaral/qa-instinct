---
description: >-
  Formal test cases for a short story must come out in the package's TC-CODE-NNN format, the one
  .claude/hooks/validate-tc-format.sh accepts. A bare model has no way to know that format.
expected_outcome: >-
  A Markdown document that starts with the frontmatter block (feature, feature_code, tc_count,
  tracker_issues, risk_level, runbook, implementation_pack, spec, last_updated) and holds exactly
  three "## TC-CODE-NNN:" cases, each with all eleven field rows filled and a Source that names an
  acceptance criterion or "Added by QA (reason)".
tags: [qa-cases, format]
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

/qa-instinct:qa-cases Write exactly three test cases for the user story below. Reply with the
test-case document only, as Markdown, starting at its first line, with no introduction and no code
fence around it.

Story PWD-7: As a registered user, I want to reset my password by email, so that I can sign in
again when I forget it.

- AC-1: Submitting a registered email on the "Forgot password" form shows "If that email is
  registered, a reset link has been sent."
- AC-2: The reset link expires 30 minutes after it is sent.
- AC-3: The new password must be 8 to 64 characters long.
