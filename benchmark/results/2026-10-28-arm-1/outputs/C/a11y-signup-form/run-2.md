---
title: Accessibility audit: Sign-up page
slug: sign-up-page-accessibility-audit
article_type: reference
product_area: Development
audience: Developer, QA
plan_availability: None
reading_time: 5 min
related_articles: []
last_updated: 2026-10-28
---

# Accessibility audit: Sign-up page

This page has 10 accessibility issues that block screen reader users and keyboard-only users from signing up.

| Issue | Severity | Element | Fix |
|-------|----------|---------|-----|
| Logo image missing alternative text | Critical | `<img src="/img/logo-2024-final.png">` | Add `alt="Company logo"` |
| Email input lacks associated label | Critical | `<input type="email" placeholder="Email">` | Add `<label for="email">Email</label>` before input |
| Password input lacks associated label | Critical | `<input type="password" placeholder="Password">` | Add `<label for="password">Password</label>` before input |
| Password input has duplicate ID | Critical | Second `id="email"` | Change to `id="password"` |
| Placeholder text is not a label substitute | Critical | Both inputs use placeholder only | Visible labels required; placeholders alone fail WCAG |
| Submit button is not a button | Critical | `<div class="btn" onclick="submitForm()">` | Replace with `<button type="submit">Create account</button>` and remove onclick handler |
| Focus outline removed globally | Critical | `:focus { outline: none; }` | Remove this rule; add visible focus styles instead (e.g., `outline: 2px solid #0a58ca;`) |
| Confusing tab order | Major | `tabindex="3"` on link only | Remove explicit tabindex; let DOM order define tab sequence |
| Hint text may fail contrast | Major | `.hint { color: #595959; }` on white | Change to `#404040` or darker for 7:1 WCAA AAA contrast |
| Form missing action and method | Major | `<form id="signup">` | Add `action="/signup"` and `method="post"` (or appropriate endpoint) |

**Assumptions made:**
- The logo is decorative only; if it's linked, use `alt="Company home"` and wrap in an anchor.
- The hint "At least 8 characters" applies to the password field; associate it with `aria-describedby="password-hint"` and id it on the paragraph.
- The form action and method are unknown; adjust the values to match your backend.

**Testing checklist to verify fixes:**
- [ ] All form inputs have visible associated labels
- [ ] Logo alt text is present
- [ ] Tab key navigates fields in logical order (top to bottom, left to right)
- [ ] Focused elements show a visible outline or other indicator
- [ ] Submit action works with keyboard (Enter key in last field or Tab to button and Enter)
- [ ] Screen reader announces all labels and hint text
- [ ] Color contrast between text and background is at least 4.5:1 for normal text
