# Accessibility Audit: Sign-up Page

## Critical Issues

### 1. **Missing Form Submit Button**
- **Issue**: The submit action uses a `<div>` styled as a button with an `onclick` handler instead of a proper `<button>` element.
- **Impact**: Screen readers won't recognize it as interactive; keyboard users can't activate it (only mouse/pointer users can).
- **WCAG Failure**: WCAG 2.1 Level A (4.1.2 Name, Role, Value; 2.1.1 Keyboard)
- **Fix**: Replace with `<button type="submit">Create account</button>`

### 2. **Removed Focus Indicators**
- **Issue**: CSS rule `:focus { outline: none; }` removes all visual focus indicators.
- **Impact**: Keyboard users cannot see which element is focused, making navigation impossible.
- **WCAG Failure**: WCAG 2.1 Level AA (2.4.7 Focus Visible)
- **Fix**: Remove the rule or replace with a visible focus style (e.g., `outline: 2px solid #0a58ca;`)

### 3. **Duplicate Input IDs**
- **Issue**: Both email and password fields have `id="email"`.
- **Impact**: Violates HTML spec; form labels and scripts targeting by ID will fail; assistive technology confusion.
- **Fix**: Change password field to `id="password"`

### 4. **Missing Form Labels**
- **Issue**: Email and password inputs lack associated `<label>` elements; only placeholder text provided.
- **Impact**: Screen readers cannot properly announce field purpose; placeholders disappear when user types.
- **WCAG Failure**: WCAG 2.1 Level A (3.3.2 Labels or Instructions)
- **Fix**: Add labels:
  ```html
  <label for="email">Email</label>
  <input type="email" id="email" name="email" placeholder="Email">
  ```

### 5. **Anti-pattern Tab Index**
- **Issue**: Link uses `tabindex="3"`, introducing an arbitrary tab order.
- **Impact**: Violates natural source-order tab sequence; confuses keyboard navigation flow.
- **WCAG Failure**: WCAG 2.1 Level A (2.4.3 Focus Order)
- **Fix**: Remove the `tabindex` attribute entirely

## Major Issues

### 6. **Missing Image Alt Text**
- **Issue**: Logo image has no `alt` attribute.
- **Impact**: Screen reader users won't know the image content; decorative intent unclear.
- **WCAG Failure**: WCAG 2.1 Level A (1.1.1 Non-text Content)
- **Assumption**: Logo is decorative; use `alt=""` or if meaningful, use `alt="Company logo"`

### 7. **Missing Language Declaration**
- **Issue**: HTML tag lacks `lang` attribute (e.g., `<html lang="en">`).
- **Impact**: Screen readers cannot select correct language pronunciation.
- **WCAG Failure**: WCAG 2.1 Level A (3.1.1 Language of Page)
- **Fix**: Add `lang="en"` to `<html>` tag

### 8. **Missing Name Attributes**
- **Issue**: Form inputs lack `name` attributes.
- **Impact**: Form data won't be submitted properly; required for any server-side processing.
- **Fix**: Add `name="email"` and `name="password"` to respective inputs; add `name="terms"` to checkbox

## Minor Issues

### 9. **Hint Text Styling**
- **Issue**: Hint text color (#595959) is relatively low-contrast on white background.
- **Impact**: Users with low vision or color blindness may struggle to read instructions.
- **WCAG Level**: Meets AA (5.9:1 ratio), but marginally. AAA (7:1) recommended for assistive guidance.
- **Suggestion**: Increase contrast to #4a4a4a or higher; consider adding icon or non-color indicator

### 10. **Missing Form Submission Feedback**
- **Issue**: No visible loading state, success message, or error handling.
- **Impact**: Users with cognitive disabilities or slow connections won't know submission status.
- **Assumption**: This is a static audit; functionality assumed to exist server-side.
- **Best Practice**: Add ARIA live regions (`aria-live="polite"`) for status updates

## Summary

**Accessibility Level**: Currently non-compliant with WCAG 2.1 Level A  
**Total Issues**: 10 (5 critical, 3 major, 2 minor)  
**Estimated Fix Time**: 20–30 minutes  
**Recommendation**: Address all critical and major issues before launch. Minor issues should be resolved in the next release cycle.
