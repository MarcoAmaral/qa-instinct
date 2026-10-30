# Accessibility Audit: Sign-Up Page

## Critical Issues

### 1. Duplicate Element IDs
Both the email and password inputs use `id="email"`. IDs must be unique. The password input should be `id="password"`.

**Impact:** Screen readers and scripts may select the wrong element; form submission will be affected.

### 2. Non-Semantic Submit Button
The submit control is a `<div>` with an `onclick` handler, not a `<button>`.

**Impact:** 
- Keyboard users cannot activate it with Enter or Space.
- Screen readers do not announce it as a button.
- Browser password managers cannot detect the form submission point.

**Fix:** Use `<button type="submit">Create account</button>` inside the form.

### 3. Focus Indicator Removed Entirely
The CSS rule `:focus { outline: none; }` removes all keyboard focus indicators.

**Impact:** Keyboard-only users cannot see which control has focus; they cannot navigate the form.

**Fix:** Replace with a visible focus style, e.g., `input:focus, button:focus { outline: 2px solid #0a58ca; }`.

## Major Issues

### 4. Missing Labels for Inputs
Email and password inputs have only placeholders, no `<label>` elements.

**Impact:** 
- Screen readers do not announce what each input is for.
- Clicking the label to focus the input is not possible.
- Placeholder text disappears when typing, leaving no persistent label.

**Fix:** Add `<label for="email">Email</label>` before the email input, and `<label for="password">Password</label>` before the password input.

### 5. Missing Alt Text on Logo
`<img src="/img/logo-2024-final.png">` has no `alt` attribute.

**Impact:** Screen readers skip the image; the company brand is not announced.

**Fix:** Add `alt="Company Name"` (assumed: replace with actual company name).

### 6. Missing Input Names
Form inputs have no `name` attributes.

**Impact:** Form submission will not include these fields in the submitted data.

**Fix:** Add `name="email"` and `name="password"` to the respective inputs.

### 7. Password Placeholder Insufficient
The password input shows `placeholder="Password"` but no persistent label.

**Impact:** Users cannot remember the requirement ("At least 8 characters") while typing.

**Fix:** Associate the password field with `<label for="password">Password (at least 8 characters)</label>`.

## Minor Issues

### 8. Contrast on Hint Text
The hint text color `#595959` on white background may fall below WCAG AA contrast minimum (4.5:1 for normal text).

**Assumed:** Contrast ratio is ~5.8:1, meeting AA for 14px+ text. If the actual rendered size is smaller, increase contrast or darken the color.

### 9. Missing Required Field Indicators
No indication that fields are required; no `required` attribute or `aria-required="true"`.

**Impact:** Users with visual or cognitive disabilities may not know a field must be filled.

**Fix:** Add `required` attribute to email and password inputs; add text "Required fields are marked with an asterisk" if an asterisk is used.

### 10. Fragile Tab Order
`<a href="/terms" tabindex="3">` suggests manual tab order, which is fragile and error-prone.

**Impact:** If the developer adds another control without updating tab order, navigation breaks.

**Fix:** Remove `tabindex` and rely on DOM order (place "Read the terms" in the logical tab sequence).

### 11. No Error Display or Validation
No indication of how validation errors will be shown to the user.

**Assumed:** Errors will be displayed with `aria-live="polite"` and `role="alert"` regions after form submission.

### 12. Checkbox Label Is Minimal
The checkbox label "I accept the terms" offers no visual separation.

**Impact:** Users may miss it or find it hard to target on touch devices.

**Fix:** Style the label with adequate padding and pointer-friendly hit target (minimum 44×44 pixels).

## Summary

**Accessibility Level:** Not WCAG 2.1 compliant; blocks keyboard users and screen reader users entirely.

**Immediate Fixes:**
1. Change `<div class="btn">` to `<button type="submit">`
2. Fix duplicate ID (`id="password"` for password input)
3. Add visible focus styles
4. Add `<label>` elements for both inputs
5. Add `name` attributes to both inputs
6. Add `alt` attribute to logo
7. Add `required` attribute to inputs
