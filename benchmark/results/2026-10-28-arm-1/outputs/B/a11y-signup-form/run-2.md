# Accessibility Audit: Sign-Up Page

## Summary
**Critical Issues: 6 | Major Issues: 4 | Minor Issues: 3**

This page has significant accessibility barriers that would prevent users with disabilities from completing sign-up. Multiple WCAG 2.1 Level A and Level AA violations require immediate remediation.

---

## Critical Issues

### 1. Logo Image Missing Alt Text (WCAG 2.1 Level A: 1.1.1)
- **Location:** `<img src="/img/logo-2024-final.png">`
- **Issue:** No `alt` attribute provided. Screen reader users receive no context about the image.
- **Impact:** Fails non-text content requirement; creates barrier for blind/low-vision users.
- **Fix:** Add descriptive alt text, e.g., `alt="Company Logo"`

### 2. Global Focus Outline Removed (WCAG 2.1 Level AA: 2.4.7)
- **Location:** `:focus { outline: none; }` in stylesheet
- **Issue:** Removes visible focus indicator for all interactive elements. Keyboard-only users cannot see which element has focus.
- **Impact:** Complete barrier for keyboard navigation users; violates keyboard accessibility.
- **Fix:** Remove this rule entirely. If custom focus styling desired, provide a visible focus indicator (e.g., `outline: 2px solid #0a58ca`).

### 3. Duplicate ID Attributes (HTML Validity & WCAG 2.1 Level A: 4.1.1)
- **Location:** Both `<input type="email" id="email">` and `<input type="password" id="email">`
- **Issue:** Two elements with identical `id="email"`. Invalid HTML; breaks label-to-input associations and JavaScript selectors.
- **Impact:** Screen readers may associate labels incorrectly; JavaScript targeting will only select first element.
- **Fix:** Change password input to `id="password"`

### 4. Non-Semantic Button (WCAG 2.1 Level A: 4.1.2)
- **Location:** `<div class="btn" onclick="submitForm()">Create account</div>`
- **Issue:** Submit action is implemented as a `<div>` instead of a `<button>`. Not recognized as clickable by assistive technology; not in tab order; no keyboard support (Enter key won't trigger).
- **Impact:** Screen reader users won't know it's actionable; keyboard users cannot submit form using standard methods.
- **Fix:** Replace with proper button: `<button type="submit">Create account</button>`

### 5. Missing Form Labels (WCAG 2.1 Level A: 1.3.1)
- **Location:** Email and password inputs use only `placeholder` attributes
- **Issue:** No associated `<label>` elements. Placeholders disappear on focus, leaving users uncertain of field purpose. Screen readers cannot reliably announce field names.
- **Impact:** Barrier for screen reader users and users with cognitive disabilities; poor UX for all.
- **Fix:** Add labels:
  ```html
  <label for="email">Email</label>
  <input type="email" id="email" placeholder="Email">
  <label for="password">Password</label>
  <input type="password" id="password" placeholder="Password">
  ```

### 6. Hint Text Not Associated with Input (WCAG 2.1 Level A: 1.3.1)
- **Location:** `<p class="hint">At least 8 characters.</p>` (applies to password field)
- **Issue:** Hint is visually near the password field but not programmatically associated. Screen reader users won't know this constraint applies to the password field.
- **Impact:** Users with disabilities may miss critical input requirements.
- **Fix:** Use `aria-describedby`: 
  ```html
  <input type="password" id="password" aria-describedby="pwd-hint">
  <p class="hint" id="pwd-hint">At least 8 characters.</p>
  ```

---

## Major Issues

### 7. Problematic Tab Index (WCAG 2.1 Level A: 2.4.3)
- **Location:** `<a href="/terms" tabindex="3">`
- **Issue:** Explicit positive `tabindex` values override natural DOM order, creating unpredictable tab sequence. Users expect logical left-to-right, top-to-bottom flow.
- **Impact:** Keyboard users experience confusing navigation order.
- **Fix:** Remove `tabindex="3"`. Allow natural tab order from DOM structure.

### 8. Insufficient Color Contrast for Hint Text (WCAG 2.1 Level AA: 1.4.3)
- **Location:** `.hint { color: #595959; }` on white background
- **Issue:** Contrast ratio is approximately 2.77:1. WCAG AA requires 4.5:1 for normal text.
- **Impact:** Barrier for users with low vision or color blindness.
- **Fix:** Darken text: `color: #404040` or darker (achieves ~6:1 contrast).

### 9. Form Missing Action and Method (HTML Validity)
- **Location:** `<form id="signup">` 
- **Issue:** No `action` attribute specified. Form submission won't work; server has no endpoint defined.
- **Impact:** Form cannot be successfully submitted.
- **Fix:** Add attributes: `<form id="signup" action="/signup" method="POST">`

### 10. No Password Visibility Toggle
- **Location:** Password input
- **Issue:** No show/hide password option for users who need to verify their entry (users with dyslexia, motor control issues, or cognitive disabilities).
- **Impact:** May cause user frustration and failed account creation attempts.
- **Fix:** Add optional show/hide password button (requires JavaScript to toggle input `type`).

---

## Minor Issues

### 11. Logo Not Wrapped in Link
- **Location:** `<img src="/img/logo-2024-final.png">` at top of page
- **Issue:** Common UX pattern for logos to link to homepage, but this image is not wrapped in an `<a>` tag. Users may not discover the link.
- **Fix:** Consider: `<a href="/"><img src="/img/logo-2024-final.png" alt="Company Logo"></a>` (if homepage link is desired).

### 12. No Visible Form Validation or Error Handling
- **Location:** Entire form
- **Issue:** No feedback mechanism for validation errors (e.g., invalid email format, password too short). Users won't know why submission failed.
- **Fix:** Add client-side validation with error messages that are announced to screen readers via ARIA live regions.

### 13. Terms Checkbox Label Clarity
- **Location:** `<label><input type="checkbox" id="terms"> I accept the terms</label>`
- **Issue:** While this has a proper label, there's no link or reference to which terms apply. The separate "Read the terms" link is not semantically connected to the checkbox.
- **Assumption:** Assuming the "Read the terms" link should open the terms document that this checkbox references.
- **Fix:** Consider improving the association: `I accept the <a href="/terms">terms</a>` inside the label, or add `aria-describedby`.

---

## Compliance Summary

| WCAG Level | Violations | Status |
|-----------|-----------|--------|
| **Level A** | 5 critical violations | ❌ **FAILS** |
| **Level AA** | 2 critical violations | ❌ **FAILS** |

**Recommendation:** Do not deploy this page in its current state. Remediate all critical issues before public release.
