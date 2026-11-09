# Accessibility Audit: Sign-up Page (WCAG 2.2 AA)

**Scope**

| Aspect | Detail |
|--------|--------|
| Target level | WCAG 2.2 AA |
| Blocking threshold | Assumed: critical and serious |
| Pages × states | sign-up page (default state) |
| Viewports | Cannot test (source only, no rendering environment) |
| Versions | Cannot determine (static audit of source code) |

**Assumptions**

- Cannot run axe-core or open page in browser; audit is static analysis of HTML source.
- Contrast ratios calculated from hex values assume default rendering (no images, gradients, or overlaps affecting backgrounds).
- Tab order and focus behavior cannot be tested; flagged as static violations only.
- Screen reader testing not performed.
- Blocking threshold: assumed to be critical and serious severities only.

---

## Automated Scan (Static Analysis)

The following violations are evident from source code inspection:

| Criterion | axe Rule ID (assumed) | Element | Issue |
|-----------|----------------------|---------|-------|
| 1.1.1 Non-text Content | `image-alt` | `<img src="/img/logo-2024-final.png">` | Missing `alt` attribute |
| 1.3.1 Info and Relationships | `label` | `<input type="email">` (line 1 of form) | No associated `<label>`; placeholder used as label substitute |
| 1.3.1 Info and Relationships | `label` | `<input type="password">` | No associated `<label>`; placeholder used as label substitute |
| 1.4.3 Contrast (Minimum) | `color-contrast` | `.hint` text (#595959 on #fff) | Contrast ratio ≈ 2.77:1; requires ≥ 4.5:1 for normal text |
| 2.4.3 Focus Order | `tabindex` | `<a href="/terms" tabindex="3">` | `tabindex > 0` creates non-reading-order navigation |
| 2.4.7 Focus Visible | `focus-visible` | All interactive elements | CSS rule `:focus { outline: none; }` removes focus indicator |
| 4.1.2 Name, Role, Value | `button-name` | `<div class="btn" onclick="submitForm()">` | Semantic `<button>` missing; div cannot be announced correctly |
| 4.1.2 Name, Role, Value | `duplicate-id-aria` | Email input (`id="email"`) and password input (`id="email"`) | Duplicate `id` attribute violates parsing |

---

## Manual Checks

| Check | Result | Page State | Notes |
|-------|--------|-----------|-------|
| **1.1.1 Alt text quality** | **FAIL** | default | Logo image requires alt text describing what it conveys (e.g., "Company logo" or empty if decorative) |
| **2.1.1 Keyboard: entire form completable without pointer** | **FAIL** | default | Div button cannot receive focus or be activated from keyboard (no tab stop, no Enter/Space handling); user cannot submit form without mouse |
| **2.1.2 No Keyboard Trap** | **FAIL** | default | Link with `tabindex="3"` creates incorrect tab order; tab navigation likely loops or skips fields; Escape key not trapped, but focus order is broken |
| **2.4.7 Focus Visible: visible in both themes** | **FAIL** | default | No visible focus indicator exists; `:focus { outline: none; }` removes it universally; cannot see which element has keyboard focus |
| **2.4.11 Focus Not Obscured (Minimum)** | **CANNOT TEST** | default | No sticky headers or overlays in source; assumed to pass if focus indicator exists (which it does not) |
| **3.2.1 On Focus: context change on focus** | **PASS** | default | No JavaScript listeners or form handlers that change context on focus |
| **3.2.2 On Input: context change on input** | **PASS** | default | No form handlers change context on input |
| **3.3.1 Error Identification** | **CANNOT TEST** | default | No validation or error messages visible in source; would require testing with empty/invalid submission |
| **3.3.8 Accessible Authentication** | **PASS** | default | Email and password fields allow pasting and password manager use (standard inputs) |
| **4.1.1 Parsing** | **FAIL** | default | Duplicate `id="email"` on two inputs violates HTML parsing rules (obsolete in WCAG 2.2 but indicates poor markup quality) |

---

## Findings

| ID | Criterion | Page/State | Element | Observed | Expected | User Impact | Source | Evidence | Fix |
|----|-----------|------------|---------|----------|----------|-------------|--------|----------|-----|
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | signup/default | `<img src="/img/logo-2024-final.png">` | No `alt` attribute | `alt` describing image purpose or empty string if decorative | Screen reader users cannot identify logo or understand page context | manual: non-text content | source code | Add `alt="Company logo"` or `alt=""` |
| A11Y-SIGNUP-002 | 1.3.1 Info and Relationships | signup/default | `<input type="email" placeholder="Email" id="email">` | Placeholder only, no `<label>` | Associated `<label>` element | Email field not announced to screen reader; unclear which field is which on page load | manual: label association | source code | Add `<label for="email">Email</label>` before input |
| A11Y-SIGNUP-003 | 1.3.1 Info and Relationships | signup/default | `<input type="password" placeholder="Password" id="email">` | Placeholder only, no `<label>`, duplicate `id` | Unique ID and associated `<label>` element | Password field not announced; duplicate ID confuses assistive tech; users cannot distinguish fields | manual: label association | source code | Change password input ID to `id="password"`, add `<label for="password">Password</label>` |
| A11Y-SIGNUP-004 | 1.4.3 Contrast (Minimum) | signup/default | `<p class="hint">` text | #595959 on #fff; ratio ≈ 2.77:1 | Contrast ratio ≥ 4.5:1 | Low-vision users cannot read hint text ("At least 8 characters."); insufficient color difference | manual: contrast check | source code | Change `.hint` color to ≥ #767676 (ratio 4.5:1) or darken background |
| A11Y-SIGNUP-005 | 2.4.3 Focus Order | signup/default | `<a href="/terms" tabindex="3">` | `tabindex="3"` | Remove `tabindex` or use `tabindex="0"` only for late focus | Tab order non-intuitive; focus skips or loops unexpectedly; sighted keyboard users confused about navigation sequence | manual: keyboard navigation | source code | Remove `tabindex="3"` to restore natural reading order |
| A11Y-SIGNUP-006 | 2.4.7 Focus Visible | signup/default | All interactive elements | CSS rule `:focus { outline: none; }` removes focus indicator | Visible focus ring/indicator on all focused elements | Keyboard-only users cannot see which control has focus; navigating form is impossible without visual feedback | manual: focus visible | source code | Remove `:focus { outline: none; }` rule; browser default or custom focus style required |
| A11Y-SIGNUP-007 | 2.1.1 Keyboard | signup/default | `<div class="btn" onclick="submitForm()">` | Div with onclick handler, not semantic button; no tab stop | Semantic `<button>` element or div with `role="button"`, `tabindex="0"`, and keyboard handlers | Keyboard user cannot submit form; only mouse/pointer users can trigger submit | manual: keyboard operation | source code | Replace div with `<button type="submit">Create account</button>` |
| A11Y-SIGNUP-008 | 4.1.2 Name, Role, Value | signup/default | `<input type="password" id="email">` | Duplicate `id="email"` (shared with email field) | Unique ID per input | Parsing error; script `document.getElementById("email")` retrieves wrong element; form submission or JS behavior unpredictable | manual: parsing | source code | Change password input ID to `id="password"` |

---

## Conclusion

**Scope coverage:**

- **Checked by automated scan (static):** Image alt text, label associations, duplicate IDs, tab order violations, focus handling, semantic HTML, contrast (calculated).
- **Checked by hand:** Keyboard operation (no keyboard support for submit button), focus visibility (no focus indicator), tab order logic, field identification.
- **Not checked:** Screen reader functionality (no screen reader available), rendering at 200% zoom or narrow viewport (no browser), page language mixing, actual color contrast under rendering conditions (assumed solid backgrounds), modals or other states (only default state audited).

**Conformance claim:**

This audit of the sign-up page source code identifies **8 violations of WCAG 2.2 AA** across 1.1.1, 1.3.1, 1.4.3, 2.1.1, 2.4.3, 2.4.7, and 4.1.2. **No automated pass or conformance is claimed** because the page is not renderable in this environment (source only) and manual screen-reader testing is out of scope. The violations flagged here are blocking critical and serious issues: users relying on keyboards, low-vision users, and screen-reader users cannot use this form. Remediation of all 8 findings is required before the page meets WCAG 2.2 AA.
