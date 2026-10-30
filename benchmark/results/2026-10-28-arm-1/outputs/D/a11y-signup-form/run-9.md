# Accessibility Audit: Sign-up Page

## 1. Scope

| Attribute | Value |
| --- | --- |
| Target | WCAG 2.2 AA |
| Blocking threshold | Critical and serious violations block release (assumed) |
| Pages × states | Sign-up page, default state only. **Not audited**: validation error state, success state, focus on each form control (static source, no rendering). |
| Viewports | 1440×900 (assumed standard). Narrow viewport and 200% zoom not tested (source only). |
| Versions | Source code analysis only. Axe-core scan not performed (cannot open in browser). |

**Assumption**: Page renders without JavaScript errors; logo image is present; colors display as specified.

---

## 2. Automated Scan

**Status**: Not performed. Cannot open page in browser to run `@axe-core/playwright`.

**Impact**: Automated checks for 1.3.1 (Info and Relationships), 1.4.1 (Use of Color), 3.1.1 (Language of Page), 4.1.3 (Status Messages), and parsing errors cannot be verified. Static code analysis alone cannot assess rendered contrast, focus visibility, or layout reflow.

---

## 3. Manual Checks & Static Code Analysis

| Criterion | Check | Finding | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | Image alt text | **FAIL**: `<img src="/img/logo-2024-final.png">` has no `alt` attribute. Cannot determine intent or whether it is decorative. | Line 17 |
| 1.4.3 Contrast (Minimum) | Contrast ratio | **CANNOT VERIFY**: Hint text `color: #595959` on `background: #fff` cannot be measured without rendering. Requires manual measurement. | Line 6 (CSS) |
| 2.1.1 Keyboard | Whole task completable without pointer | **FAIL**: "Create account" button is a `<div>` with `onclick` handler, not a `<button>`. Cannot be activated with keyboard (no Enter key support). Form submission requires pointer. | Line 25 |
| 2.1.2 No Keyboard Trap | Focus escape | **CANNOT VERIFY**: No keyboard trap apparent in code, but `tabindex="3"` on link suggests custom tab order; full reachability requires testing. | Line 23 |
| 2.4.3 Focus Order | Tab order matches reading order | **FAIL**: `<a href="/terms" tabindex="3">` uses explicit `tabindex` > 0, which creates non-logical tab order. Email input (no tabindex, default order 1), password input (no tabindex, default order 2), checkbox (no tabindex, default order 3?), link `tabindex="3"` (explicitly 3), div button (no tabindex, unfocusable). Actual order is unpredictable. | Line 23 |
| 2.4.7 Focus Visible | Focus indicator present | **FAIL**: CSS rule `:focus { outline: none; }` removes browser default focus ring with no replacement. Focused element will be invisible. | Line 6 (CSS) |
| 3.3.1 Error Identification | Field labels | **FAIL**: Email input `<input type="email" placeholder="Email" id="email">` has no `<label>` element or `aria-label`. Placeholder is not an accessible label per WCAG 2.2. Same issue for password field. | Lines 20–21 |
| 3.3.1 Error Identification | Hint associated with field | **FAIL**: `<p class="hint">At least 8 characters.</p>` is not associated with password input via `aria-describedby`. Unclear which field it describes. | Lines 21–22 |
| 3.3.8 Accessible Authentication (Minimum) | Password manager & paste | **CANNOT VERIFY**: Password field permits paste (no `onpaste` block visible), but form security and authentication flow cannot be assessed from HTML alone. | Line 21 |
| 4.1.2 Name, Role, Value | Button semantics | **FAIL**: `<div class="btn" onclick="submitForm()">Create account</div>` is not a `<button>`. Has no implicit role, no keyboard support, no semantic meaning. Expose custom `role="button"`, `aria-pressed` state, keyboard handler for Enter/Space. Screen reader announces as generic div. | Line 25 |
| 4.1.2 Name, Role, Value | Input names & roles | **FAIL**: Password input has `id="email"` (duplicate of email input's id), no `<label>`, no `aria-label`. Name and role cannot be determined by assistive tech. | Line 21 |

**Checklist items (static code inspection)**:

- **Tab test (keyboard-only navigation)**: Cannot test without rendering. Based on code: email → password → checkbox → link (tabindex=3 breaks order) → div button (unreachable by keyboard).
- **Modal trap & Escape key**: No modal present in scope.
- **Colour-blindness simulation**: Requires rendering and contrast verification.
- **Screen reader announcement**: Cannot test without rendering. Email and password inputs lack labels; "Create account" will announce as "Create account" (the text) with no button role.

---

## 4. Findings

| ID | Criterion | Page & State | Element | Observed / Expected | User Impact | Source | Evidence | Suggested Fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | Default | `<img src="/img/logo-2024-final.png">` | No alt attribute. Expected: descriptive alt text or `alt=""` if decorative. | Screen reader users cannot understand the image's purpose. | Static code | Line 17 | Add `alt="Company logo"` or `alt=""` if decorative. | Critical |
| A11Y-SIGNUP-002 | 2.4.7 Focus Visible | Default | `:focus { outline: none; }` | Focus ring removed; no replacement indicator. Expected: visible focus indicator on all interactive elements. | Keyboard users cannot see which element has focus, making navigation impossible. | Static code | Line 6 (CSS) | Remove `:focus { outline: none; }` or add `outline: 2px solid` or custom focus style. | Critical |
| A11Y-SIGNUP-003 | 2.1.1 Keyboard | Default | `<div class="btn" onclick="submitForm()">Create account</div>` | Div with onclick, not a button. Cannot be activated by keyboard. Expected: `<button>` element or `role="button"` with `onkeydown` handler. | Keyboard-only users cannot submit the form. | Static code | Line 25 | Change to `<button type="submit">Create account</button>` and remove onclick. | Critical |
| A11Y-SIGNUP-004 | 3.3.1 Error Identification | Default | `<input type="email" placeholder="Email" id="email">` | Placeholder used as label; no `<label>` element. Expected: `<label for="email">Email</label>`. | Screen reader users cannot identify field purpose; visual users without placeholder support cannot find field labels. | Static code | Line 20 | Add `<label for="email">Email</label>` before input. | Serious |
| A11Y-SIGNUP-005 | 4.1.2 Name, Role, Value | Default | `<input type="password" placeholder="Password" id="email">` | Duplicate id="email" (conflicts with email input); no label or aria-label. Expected: unique id and associated label. | Screen reader users cannot identify this as a password field; form structure corrupted; form submission may fail. | Static code | Line 21 | Change `id="email"` to `id="password"`, add `<label for="password">Password</label>`. | Serious |
| A11Y-SIGNUP-006 | 3.3.1 Error Identification | Default | `<p class="hint">At least 8 characters.</p>` near password input | Hint text not associated with password field. Expected: `aria-describedby="hint-id"` on password input, `id="hint-id"` on hint paragraph. | Screen reader users unaware that "8 characters" requirement applies to password field. | Static code | Lines 21–22 | Add `id="hint-id"` to `<p>`, add `aria-describedby="hint-id"` to password input. | Serious |
| A11Y-SIGNUP-007 | 2.4.3 Focus Order | Default | `<a href="/terms" tabindex="3">Read the terms</a>` | Custom `tabindex="3"` on link creates non-logical tab order. Expected: no explicit tabindex (or tabindex="0" only). | Keyboard users encounter link out of reading order, causing confusion. | Static code | Line 23 | Remove `tabindex="3"` attribute. | Serious |
| A11Y-SIGNUP-008 | 1.4.3 Contrast (Minimum) | Default | `.hint { color: #595959; }` on white background | Contrast ratio cannot be calculated without rendering. Appears to be gray on white. Expected: ≥4.5:1 for normal text, ≥3:1 for large text. | Low-vision users may not be able to read hint text. | Static code + visual inspection needed | Line 6 (CSS) | Measure rendered contrast; if below threshold, darken text to ≥#424242 or lighter. | Serious (if fail) |

---

## 5. Report

**Automated scan**: Not performed (source-only audit; axe-core requires browser rendering).

**Criteria checked**:
- **By scanner**: None (not performed).
- **By hand**: 1.1.1, 1.4.3, 2.1.1, 2.1.2, 2.4.3, 2.4.7, 3.3.1, 3.3.8, 4.1.2.
- **Not checked at all**: 1.3.1 (Info and Relationships — requires automated scan), 1.4.1 (Use of Color), 1.4.4 (Resize Text — requires rendering at 200%), 1.4.11 (Non-text Contrast), 2.4.11 (Focus Not Obscured), 2.5.7 (Dragging Movements), 2.5.8 (Target Size), 3.1.1 (Language of Page), 3.2.1 (On Focus), 3.2.2 (On Input), 3.2.6 (Consistent Help), 3.3.3 (Error Suggestion), 3.3.7 (Redundant Entry), 4.1.3 (Status Messages).

**Pages and states not audited**: Validation error state, success state, focus states (requires rendering).

**Conformance claim**: **Not conformant to WCAG 2.2 AA.** Static code analysis alone identifies 8 failures across keyboard accessibility (2.1.1, 2.4.3, 2.4.7), semantic meaning (4.1.2), form labeling (3.3.1), and image alt text (1.1.1). Rendering required to confirm contrast (1.4.3) and assess focus visibility in context (2.4.7). 22 criteria remain untested. This page requires remediation before a conformance assessment is possible.
