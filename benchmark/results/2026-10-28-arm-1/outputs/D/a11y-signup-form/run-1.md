# Accessibility Audit: Sign-up Page

**Audit Date:** 2026-10-28  
**Target:** WCAG 2.2 AA  
**Scope Limitation:** Static code review only. No browser instance available for automated scanning or manual testing.

## Scope

| Aspect | Value |
|--------|-------|
| **Pages audited** | Sign-up page: default state only |
| **Viewports** | Not tested; assumed standard viewport, narrow viewport, and 200% zoom would be needed in practice |
| **Tool unavailable** | axe-core (requires browser instance); manual checks limited to code inspection |
| **Assumption: Default font size** | 16px (browser default) |
| **Assumption: Image purpose** | Logo is decorative branding |
| **Assumption: Form submission** | POST to /signup (not visible in HTML) |

## Automated Scan — Not Performed

A live axe-core scan would require opening the page in a browser. Based on static analysis, these violations would likely be flagged:

- **image-alt**: Logo image lacks `alt` attribute (1.1.1 Non-text Content)
- **duplicate-id**: Email input and password input both have `id="email"` (4.1.1 parsing) — invalid; form control locators would fail
- **button-name**: `<div class="btn">` lacks semantic button role; no accessible name (4.1.2 Name, Role, Value)
- **focus-visible-style**: CSS rule `:focus { outline: none; }` removes all focus indicators (2.4.7 Focus Visible)

## Manual Checks

| Check | Page State | Verdict | Finding |
|-------|-----------|---------|---------|
| **Keyboard navigation** | Default | Not checked | Cannot test without browser. Issue: form lacks semantic button; onclick handler on div may not respond to Enter key or Space. `tabindex="3"` on link suggests hardcoded tab order — should start at 0 or omit. |
| **Focus order and visibility** | Default | Fail (code review) | `:focus { outline: none; }` removes all focus indicators. No visible focus ring in any theme. Elements: email input, password input, checkbox, link, button. |
| **Contrast ratio check** | Default | Fail (code review) | `.hint` text is `#595959` (rgb 89,89,89) on white background: contrast = 2.77:1. Fails WCAG AA 4.5:1 for normal text (needs 7:1 for AAA). At 0.9rem ≈ 14.4px, still normal text. |
| **Modal/escape behavior** | Not applicable | N/A | No modal on this page. |

## Findings

| ID | Criterion | Element | Observed | Expected | User Impact | Source | Severity |
|---|---|---|---|---|---|---|---|
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | `<img src="/img/logo-2024-final.png">` | No alt attribute | Alt text describing logo purpose (e.g., `alt="Company logo"`) | Screen reader users hear nothing; logo is invisible to assistive tech. If logo is decorative, alt="" is acceptable. If functional, inaccessible. | Manual: missing alt | Serious |
| A11Y-SIGNUP-002 | 4.1.1 Parsing | `<input type="password" id="email">` | Duplicate id="email" on password input | Unique id for each form control (e.g., `id="password"`) | Assistive tech and scripts cannot reliably target the password field; labels and aria-describedby associations fail. | Manual: duplicate ID | Serious |
| A11Y-SIGNUP-003 | 4.1.2 Name, Role, Value | `<div class="btn" onclick="submitForm()">Create account</div>` | Div with onclick; no button role or semantic semantics | `<button type="submit">Create account</button>` or `<div role="button" tabindex="0" ...>` | Keyboard users cannot activate the button (onclick only fires on click, not Enter/Space in div). Screen readers announce it as a generic div, not a button. | Manual: non-semantic button | Serious |
| A11Y-SIGNUP-004 | 2.4.7 Focus Visible | `<style> :focus { outline: none; } </style>` | Focus outline removed globally; no replacement focus style | Remove `:focus { outline: none; }` or replace with a visible focus style (border, background, outline). Default browser outline is accessible. | All users (especially keyboard-only) cannot see which element has focus. Invisible focus state blocks keyboard navigation. | Manual: removed focus indicator | Critical |
| A11Y-SIGNUP-005 | 1.3.1 Info and Relationships | `<input type="email" placeholder="Email">` `<input type="password" placeholder="Password">` | Inputs lack associated `<label>` elements; placeholder only | Add `<label for="email">Email</label>` (adjust id on password) and `<label for="password">Password</label>` | Screen reader users do not hear field labels; placeholder text disappears on focus or input, leaving no persistent label. | Manual: placeholder-only labels | Serious |
| A11Y-SIGNUP-006 | 1.4.3 Contrast (Minimum) | `<p class="hint">At least 8 characters.</p>` | Color #595959 (89,89,89) on white: contrast 2.77:1 | Minimum 4.5:1 for normal text at WCAG AA (7:1 for AAA). Try #404040 (64,64,64) for ~4.5:1, or darken further. | Low-vision users and users with color blindness struggle to read hint text; it is too faint. | Manual: measured contrast | Serious |
| A11Y-SIGNUP-007 | 2.4.3 Focus Order | `<a href="/terms" tabindex="3">Read the terms</a>` | Link has `tabindex="3"` (hardcoded numeric value > 0) | Remove `tabindex` attribute (let DOM order prevail) or use `tabindex="0"` if needed. Numeric tabindex > 0 is an anti-pattern. | Tab order becomes unpredictable if any other element uses numeric tabindex; reading order may not match visual/logical order. | Manual: hardcoded tabindex | Moderate |
| A11Y-SIGNUP-008 | 3.3.3 Error Suggestion, 3.3.1 Error Identification | Form (entire) | No error states, validation messages, or success feedback shown in HTML | Add `<div role="alert" aria-live="polite">` for client-side validation errors tied to each field; example: "Email: must be a valid email address" | Users do not know if form submission failed or why; no guidance on fixing errors. | Manual: no error handling visible | Moderate |

## Report

### Automated Scan
Not performed. Source code only, no browser instance available.

### Manual Code Review — Findings Summary

**Criteria checked by code review (static analysis):**
- 1.1.1 Non-text Content: ✗ Fail (missing alt)
- 1.3.1 Info and Relationships: ✗ Fail (no labels)
- 1.4.3 Contrast (Minimum): ✗ Fail (hint text 2.77:1)
- 2.4.3 Focus Order: ✗ Fail (numeric tabindex)
- 2.4.7 Focus Visible: ✗ Fail (outline: none)
- 4.1.1 Parsing: ✗ Fail (duplicate id)
- 4.1.2 Name, Role, Value: ✗ Fail (non-semantic button)
- 3.3.1 Error Identification, 3.3.3 Error Suggestion: ✗ Not visible in code (assumed fail)

**Criteria not audited (require browser or runtime behavior):**
- 2.1.1 Keyboard (full keyboard test cannot run without browser)
- 2.1.2 No Keyboard Trap (cannot test Escape key without browser)
- 2.4.7 Focus Visible (cannot verify visibility without rendering)
- 2.4.11 Focus Not Obscured (Minimum) (requires viewport rendering)
- 2.5.8 Target Size (Minimum) (requires layout rendering)
- 3.2.1 On Focus, 3.2.2 On Input (cannot test state changes without browser)
- 3.3.7 Redundant Entry (form flow unknown; code does not show full process)
- 3.3.8 Accessible Authentication (code does not show auth method)
- Manual checklist: Tab test, modal trap, color-blindness simulation, screen reader test — **not checked**

### Conformance Claim
**No claim of conformance can be made.** This audit is a static code review only. It identified 8 findings: 5 serious, 1 critical, 2 moderate. To complete the audit, this page must be rendered and tested with:
- axe-core in a browser (at standard, narrow, and 200% zoom)
- Keyboard-only navigation (Tab, Enter, Space, Escape)
- Screen reader (NVDA, JAWS, or VoiceOver)
- Focus visibility verification in light and dark themes
- Contrast ratio measurement (especially gradient or overlapping backgrounds)

**Pages not audited:** Validation error state, success confirmation, password reset flow, terms page.
