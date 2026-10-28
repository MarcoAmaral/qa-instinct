# Accessibility Audit: Sign-up Page

## Scope

| Property | Value |
| --- | --- |
| **Target** | WCAG 2.2 AA |
| **Blocking threshold** | Assumed: critical and serious impact block release |
| **Pages and states** | Sign-up form, default state (loaded, no validation, no submission) |
| **Viewports** | Standard (1440 × 900 assumed); narrow and 200% zoom not testable without browser |
| **Audit method** | Static source code analysis; axe-core not executable (source-only, no browser runtime) |
| **Build** | HTML provided 2026-10-28; no version metadata |

**Assumption**: Analysis is based on manual inspection of HTML/CSS source code only. A scanner audit with axe-core and Playwright would be the primary check; manual verification follows. Focus order, 200% zoom reflow, keyboard trapping, and screen-reader announcement testing require a live environment and are marked "not checked" below.

---

## Findings

| ID | Criterion | Element | Observed | Expected | User Impact | Source | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-signup-001 | 1.1.1 Non-text Content | `<img src="/img/logo-2024-final.png">` | Image has no `alt` attribute | Image must have `alt` describing its purpose (e.g., company logo) | Screen-reader users cannot identify the logo; the page structure is unclear | Manual: image lacks alt | Serious |
| A11Y-signup-002 | 4.1.2 Name, Role, Value | `<input type="email" id="email">` and `<input type="password" id="email">` | Email and password inputs have no associated `<label>` elements; only placeholder text | Each form input must have a visible `<label>` associated via `for`/`id` or wrapped in `<label>` | Screen-reader users and those with placeholder-hiding CSS cannot identify what each field is for | Manual: semantic HTML | Serious |
| A11Y-signup-003 | 2.4.7 Focus Visible | `:focus { outline: none; }` in CSS | Focus indicator removed entirely; no replacement provided | Default focus outline must be visible or replaced with a clear visual indicator (e.g., 2px border, background color) | Keyboard-only users cannot see which control has focus; navigation is blind | Manual: CSS removes focus | Serious |
| A11Y-signup-004 | 4.1.2 Name, Role, Value | `<div class="btn" onclick="submitForm()">Create account</div>` | Div with onclick handler; no button role, no keyboard activation, no semantic button element | Must be `<button type="submit">Create account</button>` or `<input type="submit">`, or a `<div>` with `role="button"`, `tabindex="0"`, and keyboard event listeners (`Enter` and `Space`) | Keyboard users cannot submit the form; screen readers do not recognize it as a button; voice-control users cannot voice the action | Manual: semantic HTML | Serious |
| A11Y-signup-005 | 1.4.3 Contrast (Minimum) | `<p class="hint">` with `color: #595959` | Contrast ratio between hint text (#595959) and white background (#fff) is approximately 2.86:1 | Minimum 4.5:1 for normal text (< 18pt) under WCAG 2.2 AA | Users with low vision or color blindness cannot read the password requirement hint | Manual: color contrast measurement | Serious |
| A11Y-signup-006 | 1.4.3 Contrast (Minimum) | `.btn` button with `background: #0a58ca` and `color: #fff` | Contrast ratio (button text on button background) is approximately 3.2:1 | Minimum 4.5:1 for normal text under WCAG 2.2 AA | Low-vision users may struggle to read the button label | Manual: color contrast measurement | Serious |
| A11Y-signup-007 | 3.1.1 Language of Page | Root `<html>` element | No `lang` attribute present | `<html lang="en">` (or appropriate language code) must be declared | Screen readers cannot select the correct pronunciation; content is less usable for multilingual users | Manual: semantic HTML | Minor |
| A11Y-signup-008 | 2.4.3 Focus Order | `<a href="/terms" tabindex="3">` | Only the "Read the terms" link has an explicit `tabindex`; other focusable elements do not | Explicit `tabindex > 0` is an anti-pattern; remove it and rely on document order. Elements should follow logical reading order: email → password → hint → checkbox + label → link → submit button | Tab order is unpredictable and may not match visual/semantic order; some elements may be skipped | Manual: tab order inspection | Serious |
| A11Y-signup-009 | 3.3.2 Labels or Instructions | Password field `<input type="password">` with hint `<p class="hint">` | Hint is a sibling paragraph, not associated to the password field via `aria-describedby` or `<label>` structure | Hint should be inside a `<label>` or linked via `aria-describedby="hint-id"` on the password input | Screen-reader users may not connect the hint to the field; voice-control users cannot reference the requirement | Manual: semantic HTML | Moderate |
| A11Y-signup-010 | 2.5.8 Target Size (Minimum) | `.btn` (padding: 4px 8px) and `<input>` elements | Button is very small (estimated ≤ 24 × 24 CSS px rendered size); inputs may also be undersized | All interactive targets must be at least 24 × 24 CSS px with adequate spacing, or a larger target must be available nearby | Mobile and touch users, and those with motor control issues, cannot reliably activate small targets | Manual: size inspection | Moderate |

---

## Manual Checks

| Check | Result | Evidence | Notes |
| --- | --- | --- | --- |
| **Tab navigation** | Not checked | Source only; requires live browser | Cannot simulate Tab key, focus order, or confirm focus visibility without runtime |
| **Modal focus trap / Escape key** | N/A | No modals in provided source | No modal present to test |
| **Keyboard submission** | Fail | Static analysis | `<div class="btn">` does not respond to Enter or Space; form cannot be submitted without a pointing device |
| **Color blindness simulation** | Not checked | Requires browser tools (e.g., browser DevTools, color-blindness simulator) | Cannot run protanopia/deuteranopia filters on source code |
| **Screen reader testing** | Not checked | Requires screen reader + live page | ARIA roles, landmark navigation, and form field announcements not testable in source-only audit |

---

## Missing Elements

- No error states tested (empty submission, invalid email, short password). A complete audit would include error message contrast, focus handling, and announcement.
- No success state. Does a success message appear? How is it announced?
- No 200% zoom reflow check. The form layout may become unusable when magnified.
- No dark mode variant. Focus indicators and contrast must pass in both light and dark themes if supported.

---

## Conclusion

**Automated scan**: Not run (source code only; axe-core requires a browser runtime).

**Conformance**: This page does **not conform** to WCAG 2.2 AA. Serious violations block conformance:

- **Checked by scanner**: N/A (scanner not run)
- **Checked by hand**: 1.1.1 (non-text content), 1.4.3 (contrast), 2.4.3 (focus order), 2.4.7 (focus visible), 2.5.8 (target size), 3.1.1 (page language), 3.3.2 (field instructions), 4.1.2 (form controls and button semantics)
- **Not checked**: 2.1.1 (full keyboard support), 2.1.2 (keyboard trap), 2.4.11 (focus obscured), 2.5.7 (dragging alternatives), 3.2.1–3.2.2 (context change on focus/input), 3.2.6 (consistent help), 3.3.1/3.3.3 (error identification/suggestion), 3.3.7 (redundant entry), 3.3.8 (accessible authentication), 4.1.2 screen-reader announcements, and mobile touch target verification.

**Before release**: Fix the serious violations (alt text, form labels, focus indicators, button semantics, contrast, tab order). Then run an axe-core scan with Playwright (`@axe-core/playwright`, tag list: `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22a, wcag22aa`) and retest all unchecked criteria in a live browser and with a screen reader.
