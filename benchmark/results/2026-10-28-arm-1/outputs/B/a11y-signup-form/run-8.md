# Accessibility Audit: Sign-Up Page

## Critical Issues (Must Fix)

### 1. Non-semantic Form Submission Button
- **Issue**: Submit button is a `<div>` with `onclick` handler, not a `<button>` element
- **Impact**: Not keyboard accessible; screen readers won't identify it as a button; fails WCAG 2.1 Level A
- **Fix**: Change to `<button type="submit">Create account</button>`

### 2. Missing Focus Indicators
- **Issue**: `:focus { outline: none; }` removes all visual focus indicators
- **Impact**: Keyboard users cannot see which element is focused; fails WCAG 2.1 Level A
- **Fix**: Remove this rule; add visible focus styles (e.g., `outline: 2px solid #0a58ca;`)

### 3. Missing Form Labels
- **Issue**: Email and password inputs lack associated `<label>` elements
- **Impact**: Screen readers cannot announce field purposes; form is unusable with screen readers; fails WCAG 2.1 Level A
- **Fix**: Wrap each input with `<label>` or use `<label for="id">` pattern

### 4. Duplicate Input IDs
- **Issue**: Both email and password inputs have `id="email"`
- **Impact**: Script errors; duplicate IDs are invalid HTML; label associations break
- **Fix**: Change password input id to `id="password"`

### 5. Broken Tab Order
- **Issue**: `tabindex="3"` on "Read the terms" link disrupts natural tab order
- **Impact**: Keyboard navigation is unpredictable; fails WCAG 2.1 Level A
- **Fix**: Remove the `tabindex` attribute; rely on DOM order

### 6. Missing Image Alt Text
- **Issue**: Logo image has no `alt` attribute
- **Impact**: Screen reader users cannot identify the logo; fails WCAG 2.1 Level A
- **Fix**: Add meaningful alt text: `<img src="/img/logo-2024-final.png" alt="Company Logo">`

---

## Major Issues (Should Fix)

### 7. Hint Text Not Associated with Input
- **Issue**: "At least 8 characters" is visually near the password field but not programmatically linked
- **Impact**: Screen reader users may not associate the hint with the password field
- **Fix**: Add `aria-describedby="password-hint"` to password input; add `id="password-hint"` to the `<p>` tag

### 8. No Language Declaration
- **Issue**: `<html>` element lacks `lang` attribute
- **Impact**: Screen readers cannot determine page language; fails WCAG 2.1 Level A
- **Fix**: Add `<html lang="en">` (assuming English; adjust as needed)

### 9. Insufficient Color Contrast
- **Issue**: Hint text (#595959 on #fff) has contrast ratio ~5.5:1
- **Impact**: Borderline for WCAG AA (requires 4.5:1 for normal text); fails WCAG AAA (requires 7:1)
- **Assumption**: Text is not critical to form submission
- **Fix**: Darken to #404040 or darker for safer contrast

---

## Minor Issues (Nice to Have)

### 10. No Required Field Indicators
- **Issue**: No indication that email and password fields are required
- **Impact**: Users may not understand mandatory fields
- **Fix**: Add `required` attribute to inputs; add visual/text indicators (e.g., "* required")

### 11. Missing Error Handling
- **Issue**: No accessible error messages or validation feedback
- **Impact**: Users with assistive technology cannot understand submission failures
- **Fix**: Implement ARIA live regions for error messages; use `aria-invalid` and `aria-describedby`

### 12. Checkbox Label Placement
- **Issue**: Checkbox is inside the `<label>`, which is accessible but unconventional for some screen readers
- **Impact**: Minor; some screen readers may announce it differently
- **Fix**: Consider moving checkbox outside label for better compatibility (optional)

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 6 |
| Major | 3 |
| Minor | 3 |

**Assumption**: Form submits to a server endpoint without client-side validation visible in the source.

**WCAG Conformance**: Current page likely fails WCAG 2.1 Level A due to missing labels, inaccessible button, and removed focus indicators.
