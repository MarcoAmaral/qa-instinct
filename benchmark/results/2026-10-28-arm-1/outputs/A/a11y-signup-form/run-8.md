# Accessibility Audit: Sign-Up Page

## Critical Issues

### 1. Removed Focus Indicator
- **Issue:** CSS rule `:focus { outline: none; }` removes all focus visible indicators
- **Impact:** Keyboard users cannot see which element has focus, making the form unusable
- **WCAG:** 2.4.7 Focus Visible (Level AA)
- **Fix:** Remove this rule and implement visible focus styles (outline, background color change, etc.)

### 2. Non-Semantic Button
- **Issue:** "Create account" is a `<div>` with `onclick` handler, not a `<button>` element
- **Impact:** Not keyboard accessible; screen readers won't announce it as a button; Enter key won't submit
- **WCAG:** 2.1.1 Keyboard (Level A)
- **Fix:** Replace with `<button type="submit">Create account</button>`

### 3. Missing Form Labels
- **Issue:** Email and password inputs lack associated `<label>` elements; rely only on placeholders
- **Impact:** Screen readers won't associate labels with inputs; placeholder text disappears when user types
- **WCAG:** 1.3.1 Info and Relationships (Level A), 3.3.2 Labels or Instructions (Level A)
- **Fix:** Add explicit labels: `<label for="email">Email</label><input type="email" id="email">`

### 4. Duplicate Input ID
- **Issue:** Password input has `id="email"` (should be `id="password"`)
- **Impact:** Incorrect form structure; focus management and programmatic labeling will fail
- **Fix:** Change password input ID to `id="password"` and add corresponding label

## Major Issues

### 5. Missing Alt Text on Logo
- **Issue:** `<img src="/img/logo-2024-final.png">` has no alt attribute
- **Impact:** Screen reader users won't know what the image is; decorative intent unclear
- **WCAG:** 1.1.1 Non-text Content (Level A)
- **Fix:** Add `alt="Company Logo"` or `alt=""` if purely decorative

### 6. Missing Language Attribute
- **Issue:** `<html>` tag lacks `lang` attribute
- **Impact:** Assistive technologies can't set proper language for pronunciation
- **WCAG:** 3.1.1 Language of Page (Level A)
- **Fix:** Add `<html lang="en">`

### 7. Explicit Tab Index
- **Issue:** `tabindex="3"` on "Read the terms" link forces manual tab order
- **Impact:** Breaks logical keyboard navigation; creates confusion about form flow
- **WCAG:** 2.4.3 Focus Order (Level A)
- **Fix:** Remove tabindex; rely on source order in HTML

## Moderate Issues

### 8. Insufficient Color Contrast on Hint Text
- **Issue:** Hint text color `#595959` on white background has ~4.5:1 contrast
- **Assumption:** Text is regular weight; if so, this meets AA but not AAA standard
- **Impact:** Hard to read for users with low vision
- **WCAG:** 1.4.3 Contrast (Minimum) (Level AA requires 4.5:1)
- **Fix:** Darken hint color to `#404040` (~7:1 contrast) or increase font size

### 9. Insufficient Font Size for Hint
- **Issue:** Hint text is 0.9rem, smaller than body text
- **Impact:** Reduced readability; small text is harder for low-vision users
- **WCAG:** Not explicit, but violates intent of 1.4.4 Resize Text
- **Fix:** Use at least 1rem for all body text, or make hint same size as body

### 10. Missing Form Method/Action
- **Issue:** `<form id="signup">` has no `action` or `method` attributes
- **Assumption:** Form submits via JavaScript, but this should be explicit for accessibility
- **Impact:** Confusing to screen reader users; semantically incomplete
- **Fix:** Add explicit attributes or enhance `submitForm()` function with ARIA feedback

## Minor Issues

### 11. Checkbox Label Accessibility
- **Issue:** Checkbox label is present but inline; relies on proximity rather than `for` attribute
- **Impact:** Works for visual users but not ideal for assistive tech; larger click target would help
- **Fix:** Use `<label for="terms"><input type="checkbox" id="terms"> I accept the terms</label>` with CSS for styling

### 12. Missing Input Validation Messaging
- **Issue:** No aria-invalid, aria-describedby, or error messages
- **Impact:** If form submission fails, users won't know why
- **WCAG:** 3.3.1 Error Identification (Level A)
- **Fix:** Add validation feedback with `aria-live="polite"` regions

## Summary
**Accessibility Level:** Fails WCAG 2.1 Level A

**Priority Fixes:** Remove focus outline removal, convert div button to real button, add form labels, fix duplicate ID, add alt text, add lang attribute.
