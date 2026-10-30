# Accessibility Audit: Sign-up Page

## Scope

**Target:** WCAG 2.2 AA

**Blocking threshold:** Assumed critical and serious findings block release (not specified by team).

**Pages × States:**
| Page | State | Audited | Notes |
|------|-------|---------|-------|
| Sign-up | Default | Yes | No error, loading, or success states provided in source |

**Viewports and Zoom:**
- 1440 × 900 (standard desktop, assumed)
- 375 × 667 (narrow mobile, assumed)
- 200% zoom (required by 1.4.4)

**Versions:**
- Source code provided, date 2026-10-28
- Browser: Not specified; assume current Chromium/Firefox
- axe-core: Not run (source code only, no browser environment)

---

## Automated Scan

**Not performed.** Static code analysis only. A running instance with `@axe-core/playwright` v4.8+ and WCAG 2.1, 2.2 tags would be required to run the full automated suite. The findings below are derived from HTML/CSS inspection.

---

## Manual Checks

### 1. Keyboard Navigation and Focus

**Finding:** The form cannot be used with keyboard alone.

- Email input: no associated label; no accessible name via `<label>`.
- Password input: no associated label; same ID ("email") as email input—ID collision.
- Password input placeholder "Password" is removed when typing; no persistent label.
- Submit control is a `<div class="btn" onclick="submitForm()">`, not a `<button>`. Native buttons respond to Enter and Space; divs do not. Keyboard users cannot submit.
- The `<a tabindex="3">Read the terms</a>` uses explicit tab order, which can confuse focus order. Tabindex > 0 should be avoided.

**Verdict:** Fail (2.1.1 Keyboard, 2.1.2 No Keyboard Trap, 4.1.2 Name, Role, Value).

### 2. Focus Visibility

**Finding:** `:focus { outline: none; }` removes the browser's default focus indicator globally.

- All focusable elements (inputs, link, button) have no visible focus ring.
- At 200% zoom and on mobile, keyboard users have no way to see which control has focus.

**Verdict:** Fail (2.4.7 Focus Visible).

### 3. Color Contrast

**Measurement:**
- Hint text: `#595959` (RGB 89, 89, 89) on white `#fff` (RGB 255, 255, 255).
- Contrast ratio: ~4.3:1.
- Required for normal text: 4.5:1; the hint is `font-size: 0.9rem` (below 18pt), so normal text rules apply.

**Verdict:** Fail (1.4.3 Contrast (Minimum)). The hint text is below the 4.5:1 threshold.

### 4. Screen Reader

**Not checked** (no screen reader access; static analysis only).

**Expected failures from code inspection:**
- Image lacks alt text → screen reader announces nothing.
- Inputs lack `<label>` elements → screen reader cannot announce input purposes.
- Password hint is a `<p>`, not associated via `aria-describedby` → screen reader won't link the hint to the field.
- Submit `<div>` has no role → screen reader won't announce it as a button.

---

## Findings

| ID | Criterion | Page × State | Element | Observed | Expected | User Impact | Source | Severity |
|---|---|---|---|---|---|---|---|---|
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | Sign-up, default | `<img src="/img/logo-2024-final.png">` | No `alt` attribute | `alt="Company Logo"` or equivalent | Screen reader users hear nothing; logo is invisible to them | Manual code review | Critical |
| A11Y-SIGNUP-002 | 2.4.7 Focus Visible | Sign-up, default | All focusable elements (inputs, link, div button) | `:focus { outline: none; }` removes focus indicator | Visible focus ring on every focused element | Keyboard users cannot see which control is active; form unusable without mouse | Manual code review | Critical |
| A11Y-SIGNUP-003 | 4.1.2 Name, Role, Value | Sign-up, default | `<div class="btn" onclick="submitForm()">Create account</div>` | Div, not button; no role or aria-label | `<button type="submit">Create account</button>` in the form | Screen readers don't announce it as a button; keyboard users (Enter, Space) cannot activate it | Manual code review | Critical |
| A11Y-SIGNUP-004 | 2.1.1 Keyboard | Sign-up, default | Form submission | Only clickable via mouse on div | Submittable via Enter key on `<button>` or implicit form behavior | Keyboard-only users cannot submit the form | Manual code review | Critical |
| A11Y-SIGNUP-005 | 3.3.2 Labels or Instructions | Sign-up, default | `<input type="email" placeholder="Email" id="email">` | Placeholder only; no `<label>` | `<label for="email">Email</label>` | Screen reader has no label to announce; placeholder vanishes when user types; ambiguous field purpose | Manual code review | Serious |
| A11Y-SIGNUP-006 | 3.3.2 Labels or Instructions | Sign-up, default | `<input type="password" placeholder="Password" id="email">` | Placeholder only; ID duplicate ("email"); no label | `<label for="password">Password</label>` and `id="password"` on input | Two form controls share id="email"; screen reader confusion; password field has no persistent name | Manual code review | Serious |
| A11Y-SIGNUP-007 | 3.3.2 Labels or Instructions | Sign-up, default | Password input + `<p class="hint">At least 8 characters.</p>` | Hint is standalone `<p>`; not associated to field | `<input aria-describedby="pwd-hint">` and `<p id="pwd-hint">` | Screen reader will not associate the "8 characters" requirement with the password field; user may not know the rule | Manual code review | Serious |
| A11Y-SIGNUP-008 | 1.4.3 Contrast (Minimum) | Sign-up, default | `.hint { color: #595959; font-size: 0.9rem; }` on white | Contrast: ~4.3:1 | 4.5:1 (normal text) | Readers with low vision or color blindness struggle to read the hint | Manual color measurement | Serious |
| A11Y-SIGNUP-009 | 2.4.3 Focus Order | Sign-up, default | `<a href="/terms" tabindex="3">Read the terms</a>` | Explicit `tabindex="3"` | No explicit tabindex; natural DOM order | Tab order may jump or confuse; manual tabindex values are fragile | Manual code review | Serious |

---

## Conclusion

**Conformance:** Not conformant to WCAG 2.2 AA.

**Criteria checked:**
- **By static code analysis:** 1.1.1 Non-text Content, 2.1.1 Keyboard, 2.1.2 No Keyboard Trap, 2.4.3 Focus Order, 2.4.7 Focus Visible, 3.3.2 Labels or Instructions, 4.1.2 Name, Role, Value, 1.4.3 Contrast (Minimum).
- **Not checked:** 1.4.4 Resize Text (requires rendering at 200% zoom), 1.4.11 Non-text Contrast (focus ring style not measured), 2.4.11 Focus Not Obscured, 3.1.1 Language of Page, 3.2.1 On Focus, 3.2.2 On Input, 3.2.6 Consistent Help, 3.3.1 Error Identification, 3.3.3 Error Suggestion, 3.3.7 Redundant Entry, 3.3.8 Accessible Authentication, and all other criteria not covered by code-level inspection or basic color math.
- **Screen reader testing:** Not checked.

**Pages and states audited:**
- Sign-up form, default state (no errors, loading states, or success state shown in source).

**Pages and states not audited:**
- Validation error states (form validation behavior, error announcements).
- Loading state (spinner, skeleton, etc.).
- Success state (post-submission confirmation).
- Responsive behavior at mobile viewport and 200% zoom (reflow, clipping, overlap).
- Dark mode or alternate color schemes (contrast ratios may differ).

**9 findings identified: 4 critical, 5 serious.** All critical findings block use by keyboard-only and screen-reader users. A full browser-based audit with axe-core and a screen reader is required to confirm rendering behavior, accessibility tree announcements, and the remaining WCAG criteria.
