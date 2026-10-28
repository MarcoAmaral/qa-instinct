# Accessibility Audit: Sign-up Page

## Critical Issues

### 1. Focus Outline Removed
**WCAG 2.4.7 (Level AA)** — The CSS rule `:focus { outline: none; }` removes all focus indicators.
- **Impact:** Keyboard users cannot see which element has focus, making the page unusable without a mouse.
- **Fix:** Remove this rule or replace with a visible focus style (e.g., `outline: 2px solid #0a58ca;`).

### 2. Non-Button Submit Control
**WCAG 4.1.2 (Level A)** — The submit is a `<div class="btn">` with an onclick handler, not a `<button>`.
- **Impact:** Not keyboard-accessible (can't activate with Enter/Space), not announced as a button to screen readers, bypasses form semantics.
- **Fix:** Replace with `<button type="submit">Create account</button>`.

### 3. Duplicate Element ID
**HTML validity** — Two inputs have `id="email"` (the password field should be `id="password"`).
- **Impact:** Invalid HTML; breaks form association and JavaScript selectors.
- **Fix:** Change password input to `id="password"`.

### 4. Missing Labels for Form Inputs
**WCAG 1.3.1 (Level A)** — Email and password inputs use only placeholder text; no `<label>` elements.
- **Impact:** Screen readers can't reliably associate labels with inputs; placeholders disappear on focus or when field is pre-filled.
- **Fix:** Add labels:
  ```html
  <label for="email">Email</label>
  <input type="email" id="email" required>
  
  <label for="password">Password</label>
  <input type="password" id="password" required>
  ```

### 5. Image Missing Alt Text
**WCAG 1.1.1 (Level A)** — Logo image has no alt attribute.
- **Impact:** Screen reader users don't know what the image represents.
- **Assumption:** Logo is decorative/branding. **Fix:** `<img src="/img/logo-2024-final.png" alt="">` or `<img src="/img/logo-2024-final.png" alt="Company logo">` if it provides context.

## Major Issues

### 6. Explicit Tab Order Manipulation
**WCAG 2.4.3 (Level A)** — The "Read the terms" link has `tabindex="3"`, forcing manual tab order.
- **Impact:** Confuses keyboard navigation flow; implies hidden focusable elements with tabindex 1–2.
- **Fix:** Remove `tabindex` and ensure DOM order matches intended tab order.

### 7. Low Contrast Hint Text
**WCAG 1.4.3 (Level AA)** — Hint text uses `#595959` (gray) on white background.
- **Impact:** Contrast ratio ~6.3:1; barely meets AA, fails stricter AAA requirements. Hard to read for users with vision impairments.
- **Assumption:** Using #222 (body text color) instead. **Fix:** Change `.hint { color: #222; }` or use a darker shade like `#404040` for better readability.

## Minor Issues

### 8. No Required/Validation Attributes
**WCAG 3.3.1, 3.3.3** — Form fields lack `required` attribute or validation feedback.
- **Impact:** No built-in validation hints; users get no feedback before clicking submit.
- **Fix:** Add `required` to email and password inputs.

### 9. Placeholder Overuse
**WCAG 2.4.4** — Password field uses placeholder ("Password") as its only label.
- **Impact:** Users with certain assistive technology or cognitive disabilities may forget what the field is for once they start typing.
- **Fix:** Use `<label>` instead of relying on placeholder.

### 10. Form Has No Submit Button in Native Form
**WCAG 4.1.2** — Form submission happens via JavaScript/onclick, not a form button.
- **Impact:** Breaks browser autocomplete, password managers, and default form submission behavior.
- **Fix:** Use `<button type="submit">` inside the form.

## Assumptions Made
- The logo is decorative branding; it can use `alt=""`.
- The hint text ("At least 8 characters") is supplemental info, not a label; it should use the body text color for readability.
- No form-level error messages are shown; this audit assumes error handling exists elsewhere.

## Summary
**8 accessibility violations** (1 critical for keyboard users, 3 blocking for screen readers, 1 HTML validity issue). The page is not usable without a mouse and lacks proper form semantics for assistive technology.
