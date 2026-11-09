---
title: Accessibility audit of sign-up page
slug: accessibility-audit-signup-page
article_type: reference
product_area: Web Forms
audience: Developer, QA
plan_availability: All plans
reading_time: 5 min
related_articles: None – standalone audit
last_updated: 2026-10-28
---

# Accessibility audit of sign-up page

This audit identifies WCAG 2.1 Level A and AA violations in the sign-up form HTML.

## Critical issues (fix immediately)

| Issue | Location | Impact | Fix |
|-------|----------|--------|-----|
| Missing `alt` text | `<img src="/img/logo-2024-final.png">` | Screen reader users cannot identify the logo | Add `alt="Company logo"` or appropriate text |
| Focus outline removed | `:focus { outline: none; }` | Keyboard users cannot see which control has focus | Remove this CSS rule or replace with visible focus indicator |
| Button is not a button | `<div class="btn" onclick="submitForm()">` | Not keyboard accessible; screen readers read it as text | Change to `<button type="submit">` |
| Duplicate input IDs | Both inputs have `id="email"` | Forms are broken; labels cannot find their inputs | Assign unique IDs (`id="email"` and `id="password"`) |

## Moderate issues

| Issue | Location | Impact | Fix |
|-------|----------|--------|-----|
| Missing `<label>` elements | Email and password inputs | Form labels missing for screen readers; placeholder is not a substitute | Add `<label for="email">Email</label>` before email input; add `<label for="password">Password</label>` before password input |
| Tab order out of order | `<a href="/terms" tabindex="3">` | Keyboard navigation skips the submit button or creates confusion | Remove `tabindex` attribute to restore natural tab order, or set all tabbable elements explicitly starting from 1 |
| Hint text not associated | `<p class="hint">At least 8 characters.</p>` | Screen reader users don't know this applies to the password field | Add `id="hint-password"` to the `<p>` and `aria-describedby="hint-password"` to the password input |
| Possible color contrast issue | `.hint { color: #595959; }` on white background | Text may be too faint for users with low vision | Verify contrast ratio of #595959 on white is ≥4.5:1 (Level AA); if not, darken to #595959 or darker |
| Missing form attributes | `<form id="signup">` | No declared submission method or target | Add `method="POST"` and `action="/signup"` to the form tag |

## Minor issues

| Issue | Location | Impact | Fix |
|-------|----------|--------|-----|
| No `required` attributes | Email and password inputs | Users cannot know fields are mandatory before submission | Add `required` attribute to both inputs |
| Checkbox label is vague | `<label><input type="checkbox" id="terms"> I accept the terms</label>` | Unclear what "terms" means in context | Change to `<label><input type="checkbox" id="terms" required> I accept the <a href="/terms">terms of service</a></label>` to link and clarify |
| No validation messaging | Form lacks error output | Screen reader users won't hear validation errors | Add an `aria-live="polite"` region to announce submission errors |

## Assumed labels

- Image alt text assumed as "Company logo" (adjust to match actual logo function).
- Form submission method and action assumed as POST; actual values may differ.
- "Terms" link text assumed to mean "terms of service"; verify product labeling.
