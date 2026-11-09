# Accessibility Audit Report: Sign-up Page

## Scope

| Item | Value |
|------|-------|
| **Target** | WCAG 2.2 AA |
| **Blocking threshold** | Assumed: Critical and Serious only |
| **Analysis method** | Static code review (no browser access) |
| **Pages audited** | Sign-up page, default state |
| **Viewports** | Not testable without browser rendering |
| **Version** | Static HTML source only; no axe-core scan possible |

**Assumptions:**
- "Create your account" is the primary task on this page.
- The logo image is decorative (not functional).
- Blocking threshold: critical and serious issues only (moderate/low for information).
- The form submit will use POST (not specified in HTML).

---

## Findings

| ID | Criterion | Element | Observed | Expected | User impact | Source | Severity |
|---|---|---|---|---|---|---|---|
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | `<img src="/img/logo-2024-final.png">` | Missing `alt` attribute; no text alternative for logo image | Logo image must have an `alt` attribute: either descriptive text if functional or empty string `alt=""` if decorative | Screen reader users cannot identify the logo or understand its purpose | Static code inspection | Moderate |
| A11Y-SIGNUP-002 | 1.3.1 Info and Relationships | `<input type="email" id="email">` | No `<label>` associated; placeholder used only | Email input must have a `<label>` with `for="email"` attribute | Screen reader users cannot reliably identify this as an email field; keyboard-only users lack a clickable label | Static code inspection | Critical |
| A11Y-SIGNUP-003 | 1.3.1 Info and Relationships | `<input type="password" id="email">` | No `<label>` associated; duplicate `id` attribute (conflicts with email field); hint text not semantically tied to field | Password input must have a unique `id` (e.g., `id="password"`) and associated `<label for="password">`; hint must use `aria-describedby` or be inside the label | Screen readers cannot distinguish this from the email field; both inputs claim the same `id`, breaking DOM validity and assistive technology behavior | Static code inspection | Critical |
| A11Y-SIGNUP-004 | 1.3.1 Info and Relationships | `<p class="hint">At least 8 characters.</p>` | Hint is a separate paragraph; not linked to password field | Hint must be associated with the password input via `aria-describedby` attribute (e.g., `<input aria-describedby="pwd-hint">` and `<p id="pwd-hint">…</p>`) | Screen reader users will not hear the password requirement; users with cognitive disabilities may not see which field it applies to | Static code inspection | Moderate |
| A11Y-SIGNUP-005 | 2.1.1 Keyboard | `<div class="btn" onclick="submitForm()">Create account</div>` | `<div>` element mimics a button with `onclick` handler only; no `<button>` tag | Must be a `<button>` element: `<button type="submit">Create account</button>` | Keyboard-only users cannot activate the button; screen readers do not announce it as a button; `Enter` key will not submit the form | Static code inspection | Critical |
| A11Y-SIGNUP-006 | 2.1.2 No Keyboard Trap | `<a href="/terms" tabindex="3">Read the terms</a>` | Explicit `tabindex="3"` bypasses natural tab order | Tabindex values > 0 should be avoided; reorder elements in HTML or use `tabindex="0"` if necessary. Remove `tabindex="3"` and reorder the link in the DOM to the correct position | Keyboard-only users experience a confusing, non-sequential tab order; focus jumps unexpectedly | Static code inspection | Moderate |
| A11Y-SIGNUP-007 | 2.4.7 Focus Visible | `:focus { outline: none; }` | CSS rule removes all default focus indicators without replacement | Remove or replace the `:focus` rule with a visible focus indicator (e.g., `outline: 2px solid #0a58ca;` or `box-shadow`); provide a replacement in all states and themes | Keyboard-only users and users navigating by focus cannot see which element is active; navigation is impossible | Static code inspection | Critical |
| A11Y-SIGNUP-008 | 3.1.1 Language of Page | `<html>` (missing `lang` attribute) | No `lang` attribute on `<html>` tag | Must include language attribute: `<html lang="en">` (or appropriate language code) | Screen reader users will default to the user agent's language setting, causing incorrect pronunciation if language mismatches; search engines cannot identify page language | Static code inspection | Low |
| A11Y-SIGNUP-009 | 4.1.2 Name, Role, Value | `<div class="btn" onclick="submitForm()">Create account</div>` | `<div>` does not expose a semantic role; screen readers see text but not a button role | Replace with `<button type="submit">Create account</button>` or add `role="button"` + `tabindex="0"` + keyboard handler (not recommended; use native button) | Screen reader users do not hear "button" or understand the element is interactive; users with motor disabilities cannot rely on browser button behavior (form submission) | Static code inspection | Critical |
| A11Y-SIGNUP-010 | 1.4.3 Contrast (Minimum) | `.hint { color: #595959; }` on `background: #fff;` | Hint text color (#595959 ≈ 59% gray) on white background; rendered contrast not measurable without browser | Measure contrast at rendering; ensure ≥ 4.5:1 for normal text (14px+) or ≥ 3:1 for large text. Gray on white may be borderline. | Users with low vision or color blindness may struggle to read password requirements | Requires browser measurement | Low |

---

## Manual Checks Not Performed

| Check | Reason | Impact |
|-------|--------|--------|
| **2.1.1 Keyboard** – Full task completion | Cannot test keyboard navigation without a browser | Cannot confirm if form can be submitted via keyboard alone (button is a div; no replacement visible focus) |
| **2.1.2 No Keyboard Trap** – Tab/Escape behavior | Cannot test tab order or modal escape in browser | Cannot confirm if focus can leave all fields and if Escape closes any modals (none visible in source) |
| **2.4.7 Focus Visible** – Visibility at each step, both themes | Cannot render at default zoom, 200% zoom, or dark/light themes | Cannot confirm focus indicator is visible; CSS removes all focus outlines |
| **2.4.11 Focus Not Obscured** – Sticky headers/overlays | No overlays in source; nothing to test without rendering | Passes by inspection (no fixed/sticky elements found) |
| **1.4.3 Contrast (Minimum)** – Measured colors | Cannot measure rendered colors without browser | Hint text (#595959 on #fff) may fail; cannot verify |
| **1.4.4 Resize Text** – 200% zoom clipping | Cannot render at 200% zoom without browser | Cannot check if text, inputs, or button clip or overlap |
| **2.5.8 Target Size (Minimum)** – Pointer targets 24×24 CSS px | Cannot measure rendered dimensions without browser | Cannot confirm button and input sizes meet 24×24 px minimum |
| **3.2.1 / 3.2.2 On Focus, On Input** – Context changes | No JavaScript handlers that change context on focus/input visible in source | Passes by inspection (no input change handlers found) |
| **3.3.1 Error Identification** – Validation errors | No error state in source | Not audited; assume validation errors will be tested in error state variant |
| **Screen reader testing** | Out of scope for static code review | Not checked |

---

## Conclusion

**Automated scan results:** Not performed (static code analysis only; no axe-core).

**Checked by hand:**
- ✅ Semantic correctness: HTML structure, native elements, IDs, attributes
- ✅ WCAG 2.2 criteria checkable by code inspection: 1.1.1 (alt), 1.3.1 (labels, associations), 2.1.1 (keyboard), 2.1.2 (tab order), 2.4.7 (focus removal), 3.1.1 (language), 4.1.2 (role/name)

**Not checked (require browser):**
- ✅ 1.4.3 Contrast — measured rendering
- ✅ 1.4.4 Resize Text — 200% zoom
- ✅ 2.4.7 Focus Visible — actual focus ring visibility at all zoom levels and themes
- ✅ 2.4.11 Focus Not Obscured — sticky overlays
- ✅ 2.5.8 Target Size — pointer target dimensions
- ✅ Screen reader testing

**Not audited:**
- Error state of the form (validation failures, duplicate submission, network errors)
- Success state (post-submission page)
- Dark theme rendering (if applicable)

---

## Summary for the team

**5 critical findings** block this sign-up form from WCAG 2.2 AA compliance and basic keyboard/screen-reader accessibility:

1. **No visible focus indicator** (`outline: none`) — keyboard users cannot see which field has focus.
2. **Fake button** (a `<div>` with onclick) — not keyboard accessible, not announced by screen readers.
3. **Missing labels** (email and password inputs) — screen readers cannot identify the fields.
4. **Duplicate ID** (both inputs claim `id="email"`) — breaks DOM validity and assistive technology.
5. **Non-standard tab order** (tabindex="3" on the link) — keyboard navigation is unpredictable.

**4 moderate findings** reduce usability:

6. Missing `alt` on logo — screen readers cannot identify it.
7. Hint text not tied to password field — unclear which requirement applies to which input.
8. Contrast of hint text — verify measurement.
9. Missing `lang` attribute — screen readers may mispronounce.

**Recommendation:** Fix the 5 critical issues before testing. Provide a corrected HTML version and run an axe-core scan with browser rendering to test contrast, focus visibility, and target size, and to validate the fixes.
