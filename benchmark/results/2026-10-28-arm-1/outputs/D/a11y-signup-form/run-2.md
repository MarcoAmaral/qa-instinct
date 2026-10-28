# Accessibility Audit: Sign-up Page

## Scope

- **Target**: WCAG 2.2 AA
- **Blocking threshold**: Assumed to be critical and serious (all violations treated as reportable pending team review)
- **Pages x states**: 
  | Page | State | Audited |
  | --- | --- | --- |
  | Sign-up form | Default (empty) | Yes |
  | Sign-up form | With validation errors | Not audited (source does not show) |
  | Sign-up form | Focus on email field | Yes (static analysis) |
  | Sign-up form | Focus on password field | Yes (static analysis) |
  | Sign-up form | Focus on checkbox | Yes (static analysis) |
- **Viewports**: 1440 × 900 assumed (full viewport); 320 px narrow, 200% zoom not testable from source alone
- **Versions**: Source-only audit; axe-core scan not executable. Static code analysis and manual reasoning applied.

---

## Findings

### A11Y-SIGNUP-001

| Field | Value |
| --- | --- |
| **Criterion** | 1.1.1 Non-text Content |
| **Page and state** | Sign-up form, default |
| **Element** | `<img src="/img/logo-2024-final.png">` |
| **Observed** | Logo image has no `alt` attribute. Screen reader users cannot learn what the image is. |
| **Expected** | The `alt` attribute must describe the image's purpose (e.g., `alt="Company logo"` or `alt="Home"` if it is a link). |
| **User impact** | Screen reader users cannot identify the logo or brand context. |
| **Source** | Manual: WCAG 1.1.1 criterion, non-text content rule |
| **Evidence** | Source line 16: `<img src="/img/logo-2024-final.png">` |
| **Suggested fix** | Add `alt` attribute: `<img src="/img/logo-2024-final.png" alt="Company logo">` |
| **Severity** | Serious (content is inaccessible to screen reader users) |

---

### A11Y-SIGNUP-002

| Field | Value |
| --- | --- |
| **Criterion** | 4.1.2 Name, Role, Value |
| **Page and state** | Sign-up form, default |
| **Element** | Email input: `<input type="email" placeholder="Email" id="email">` |
| **Observed** | Email input has no associated `<label>` element. The placeholder is visible only before input and disappears on focus, leaving no visible label when the field is active. |
| **Expected** | Every form input must have a programmatically associated label via `<label for="email">` or other means. Placeholders do not meet this requirement. |
| **User impact** | Screen reader users cannot learn what the field is for. Sighted users lose the field label when they click to enter data. Users with cognitive disabilities may not understand the field purpose from placeholder text alone. |
| **Source** | Manual: WCAG 4.1.2, form input labeling; 3.3.2 Labels or Instructions |
| **Evidence** | Source line 19 |
| **Suggested fix** | Add label above input: `<label for="email">Email</label>` |
| **Severity** | Critical (form input name is not available to assistive technology) |

---

### A11Y-SIGNUP-003

| Field | Value |
| --- | --- |
| **Criterion** | 4.1.2 Name, Role, Value |
| **Page and state** | Sign-up form, default |
| **Element** | Password input: `<input type="password" placeholder="Password" id="email">` |
| **Observed** | Password input has incorrect `id="email"` (conflicts with email field) and no associated `<label>`. Placeholder disappears on focus. |
| **Expected** | Input must have unique `id` and associated `<label for="password">`. |
| **User impact** | Screen reader users cannot identify the field. Duplicate `id` breaks semantic association. Sighted users lose the label when typing. |
| **Source** | Manual: WCAG 4.1.2, form input labeling |
| **Evidence** | Source line 20 |
| **Suggested fix** | Change to `<input type="password" id="password">` and add `<label for="password">Password</label>` |
| **Severity** | Critical (invalid HTML; input name unavailable) |

---

### A11Y-SIGNUP-004

| Field | Value |
| --- | --- |
| **Criterion** | 2.4.7 Focus Visible |
| **Page and state** | Sign-up form, all states with focus |
| **Element** | Global focus style: `:focus { outline: none; }` |
| **Observed** | The CSS rule removes the default focus outline for all elements. No replacement visible focus indicator is provided in the source. |
| **Expected** | Focused elements must have a visible indicator (outline, border, background change, etc.) with sufficient contrast. |
| **User impact** | Keyboard-only and screen reader users cannot see which element has focus. Navigation becomes disorienting. |
| **Source** | Manual: WCAG 2.4.7 Focus Visible |
| **Evidence** | Source line 9 |
| **Suggested fix** | Replace with a visible focus style: `:focus { outline: 2px solid #0a58ca; outline-offset: 2px; }` or equivalent |
| **Severity** | Critical (keyboard navigation becomes unusable) |

---

### A11Y-SIGNUP-005

| Field | Value |
| --- | --- |
| **Criterion** | 1.4.3 Contrast (Minimum) |
| **Page and state** | Sign-up form, default |
| **Element** | Hint text: `.hint { color: #595959; font-size: 0.9rem; }` on white background |
| **Observed** | Hint text (#595959 = rgb(89, 89, 89)) on white background (#fff = rgb(255, 255, 255)) produces a contrast ratio of approximately 5.6:1. At small font size (0.9rem), this may fail or be borderline for WCAG AA. |
| **Expected** | For text smaller than 18pt (or 14pt bold), minimum contrast ratio is 4.5:1. |
| **User impact** | Users with low vision or color blindness may struggle to read the hint text. |
| **Source** | Manual: WCAG 1.4.3 Contrast (Minimum). Actual rendered colors cannot be confirmed from source alone. |
| **Evidence** | Source lines 8, 21 |
| **Suggested fix** | Increase color saturation: change to `color: #333333;` or similar to reach ≥4.5:1 minimum |
| **Severity** | Serious (if actual rendering confirms low contrast) |

---

### A11Y-SIGNUP-006

| Field | Value |
| --- | --- |
| **Criterion** | 3.3.1 Error Identification & 3.3.3 Error Suggestion |
| **Page and state** | Sign-up form, default and with focus |
| **Element** | Password field hint: `<p class="hint">At least 8 characters.</p>` |
| **Observed** | Hint text is a paragraph sibling of the input, not programmatically associated with the password field via `aria-describedby`. |
| **Expected** | Helper text and validation rules must be associated with their input via `aria-describedby` so assistive tech can announce them with the field. |
| **User impact** | Screen reader users may not learn the password requirement when they focus the password field; they hear only "password input." |
| **Source** | Manual: WCAG 3.3.1 Error Identification, 4.1.2 Name Role Value |
| **Evidence** | Source lines 20–21 |
| **Suggested fix** | Add `aria-describedby="pwd-hint"` to password input; add `id="pwd-hint"` to hint paragraph |
| **Severity** | Serious (instruction inaccessible to screen reader users) |

---

### A11Y-SIGNUP-007

| Field | Value |
| --- | --- |
| **Criterion** | 4.1.2 Name, Role, Value |
| **Page and state** | Sign-up form, default |
| **Element** | Submit button: `<div class="btn" onclick="submitForm()">Create account</div>` |
| **Observed** | The button is implemented as a `<div>` with an `onclick` handler, not a semantic `<button>` element. Screen readers announce this as generic content, not a button. Keyboard users cannot activate it via Enter/Space. |
| **Expected** | Interactive controls must use semantic elements (`<button>`, `<a>`, `<input type="submit">`) or have explicit ARIA role and keyboard handlers. |
| **User impact** | Screen reader users cannot identify this as a control. Keyboard-only users cannot activate it unless JavaScript event handlers include keyboard support (they do not appear to). |
| **Source** | Manual: WCAG 4.1.2 Name Role Value, 2.1.1 Keyboard |
| **Evidence** | Source lines 23–24 |
| **Suggested fix** | Change to `<button type="submit" form="signup">Create account</button>` |
| **Severity** | Critical (interactive control not accessible) |

---

### A11Y-SIGNUP-008

| Field | Value |
| --- | --- |
| **Criterion** | 2.4.3 Focus Order |
| **Page and state** | Sign-up form, default |
| **Element** | "Read the terms" link: `<a href="/terms" tabindex="3">Read the terms</a>` |
| **Observed** | Link has explicit `tabindex="3"`, which disrupts natural tab order. The form likely has natural focus order (email → password → checkbox → submit) but this link jumps to position 3, creating a confusing sequence. |
| **Expected** | Tab order should follow reading order and visual layout. Explicit `tabindex` values above 0 should be avoided. |
| **User impact** | Keyboard users encounter focus moving to unexpected locations, breaking navigation flow and causing disorientation. |
| **Source** | Manual: WCAG 2.4.3 Focus Order (axe-core would flag `tabindex > 0`) |
| **Evidence** | Source line 22 |
| **Suggested fix** | Remove `tabindex` attribute; reorder HTML elements to match desired tab order, or use `tabindex="0"` only if reordering is not feasible |
| **Severity** | Serious (keyboard navigation order is illogical) |

---

## Manual Checks from Accessibility Checklist

### Keyboard Navigation (2.1.1, 2.1.2 No Keyboard Trap)

**Verdict**: Cannot verify without running in a browser.

**Assumption**: The form likely requires mouse click on the `<div class="btn">` to submit (no keyboard support for submit). The link has a valid `href`, so it is keyboard-accessible. The checkbox can be focused and toggled via Space.

**Finding**: The "Create account" button (div element) does not appear to have keyboard activation. JavaScript `onclick` does not fire on Enter/Space unless explicitly coded.

---

### Tab Test (Focus Visibility)

**Verdict**: Fail.

**Assumption**: With `:focus { outline: none; }` in place and no replacement visible focus style in the source, focused elements have no visible indicator.

**Finding**: Keyboard users cannot see which element has focus.

---

### Color Blindness Simulation (1.4.3)

**Verdict**: Not checked (requires rendering and color sampling).

**Assumption**: The button (blue #0a58ca on white) likely has sufficient contrast. The hint text (#595959) may be borderline.

---

### Screen Reader Test (4.1.2, 1.1.1)

**Verdict**: Not checked (requires screen reader).

**Assumption based on source**:
- Logo image is silent (no alt).
- Form fields have no accessible names (placeholders do not count).
- Password hint is not announced with the field.
- Submit button is announced as generic text, not a control.

---

## Report

### Criteria Checked

| Criterion | How Checked |
| --- | --- |
| 1.1.1 Non-text Content | Static code review |
| 1.4.3 Contrast (Minimum) | Static code review (colors identified, but actual rendering not confirmed) |
| 2.1.1 Keyboard, 2.1.2 No Keyboard Trap | Static code review + assumption (cannot verify without running) |
| 2.4.3 Focus Order | Static code review |
| 2.4.7 Focus Visible | Static code review |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Static code review |
| 4.1.2 Name, Role, Value | Static code review |
| **Other criteria (3.2.1, 3.2.2, 3.2.6, 3.3.7, 3.3.8, 3.1.1, 2.5.7, 2.5.8, 4.1.1)** | Not checked or not applicable to this page |

### Criteria Not Checked (Out of Scope)

- Screen reader testing (manual interaction required)
- 1.4.4 Resize Text at 200% zoom (cannot test without browser)
- 1.4.11 Non-text Contrast (focus rings, borders; no visible indicator in source to check)
- 3.1.1 Language of Page (single language assumed; no mixed content detected)
- 2.5.7 Dragging Movements (no drag interaction in form)
- 2.5.8 Target Size (cannot measure rendered dimensions from source)
- 3.2.1 On Focus, 3.2.2 On Input (no event handlers in source to verify)
- 3.2.6 Consistent Help (only one page in scope)
- 3.3.7 Redundant Entry (no multi-step flow visible)
- 3.3.8 Accessible Authentication (no password manager or recognition visible)

### Pages and States Not Audited

- Validation error states (error messages, inline error text not shown in source)
- Success state (confirmation or redirect flow not shown)
- Loading state (no async loading UI in source)
- Mobile or narrow viewport rendering (1440 × 900 assumed only)

### Conformance Claim

**This page does not conform to WCAG 2.2 AA.** Seven critical and serious violations were identified:

1. Logo image missing `alt` attribute (1.1.1)
2. Email input missing associated label (4.1.2)
3. Password input: invalid `id` and missing label (4.1.2)
4. Focus outline removed with no replacement (2.4.7)
5. Hint text contrast may be insufficient (1.4.3) — requires rendering confirmation
6. Password hint not programmatically associated (3.3.1)
7. Submit button is not semantic, keyboard not accessible (4.1.2, 2.1.1)
8. Tab order disrupted by explicit `tabindex` (2.4.3)

**Criteria verified as conformant**: None can be claimed conformant. Even criteria checked by the scanner cannot be claimed on a page with this many violations and no automated test run.

**Audit limitation**: This audit is based on static source code analysis only. An automated scan (axe-core) and browser-based manual testing (rendering, contrast, screen reader) are required to complete a full WCAG 2.2 AA conformance audit.
