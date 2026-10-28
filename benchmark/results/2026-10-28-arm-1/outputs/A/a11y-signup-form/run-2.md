# Accessibility Audit: Sign-up Page

## Critical Issues (Must Fix)

**1. Non-semantic Submit Button**
- The submit action uses `<div class="btn" onclick="submitForm()">` instead of a `<button>` element
- **Impact**: Not keyboard accessible (can't activate with Enter/Space), not announced as a button to screen readers, fails touch targets on some devices
- **Fix**: Replace with `<button type="submit" form="signup">Create account</button>`

**2. Missing Form Labels**
- Email and password inputs use `placeholder` as the only label; `<label>` elements are absent
- Password field has `id="email"` (duplicate ID, wrong field identifier)
- **Impact**: Screen reader users won't hear field names; placeholder text vanishes when typing, leaving users confused
- **Fix**: Add `<label for="email">Email</label>` and `<label for="password">Password</label>` elements; change password `id` to `"password"`

**3. Removed Focus Indicator**
- `:focus { outline: none; }` removes the only visible focus indicator
- **Impact**: Keyboard and screen reader users cannot see which element has focus
- **Fix**: Remove this rule or replace with a visible focus style (e.g., `outline: 2px solid #0a58ca;`)

**4. Logo Image Missing Alt Text**
- `<img src="/img/logo-2024-final.png">` has no `alt` attribute
- **Impact**: Screen reader users hear "image" with no context; decorative intent is unclear
- **Assumption**: Logo is decorative; if it's functional, provide descriptive alt text
- **Fix**: Add `alt=""` for decorative images, or `alt="Company Name"` if functional

## Major Issues

**5. Hint Text Not Associated with Field**
- Password requirement "At least 8 characters" appears in `<p class="hint">` but has no connection to the password input
- **Impact**: Screen reader users may not learn this requirement; hint is visually separate
- **Fix**: Use `<label for="password">Password</label> <input id="password" type="password" aria-describedby="pwd-hint">` with `<p id="pwd-hint" class="hint">At least 8 characters.</p>`

**6. Insufficient Color Contrast**
- Hint text uses `color: #595959` (RGB 89, 89, 89) on white background
- **Contrast ratio: ~2.86:1** (fails WCAG AA; requires 4.5:1 for normal text)
- **Impact**: Low-vision users may struggle to read hints
- **Fix**: Use darker color (e.g., `#333` for ~7:1 contrast) or increase font size to 18px+ (3:1 acceptable for large text)

## Minor Issues

**7. Tab Order Anti-pattern**
- `<a href="/terms" tabindex="3">` uses explicit positive tabindex
- **Impact**: Creates confusing navigation flow; natural DOM order is clearer
- **Fix**: Remove `tabindex="3"` and place link after checkbox in HTML

**8. Checkbox Label Wrapping**
- `<label><input type="checkbox"> I accept the terms</label>` is correct but could be more semantic
- **Issue**: Link to terms is outside the label, so clicking it doesn't toggle the checkbox
- **Better**: Keep label for checkbox; link should be separate (already is)

## Missing Assumptions

- **Form submission**: No `action` or `method` on `<form id="signup">` (assumes JavaScript handles or action is added server-side)
- **Error handling**: No error messages visible (assumes validation added post-submission)
- **Required fields**: No `required` attributes (assumes optional or enforced via JavaScript)

## Summary

**Fixes required before launch**: #1, #2, #3, #4, #5
**Recommended before launch**: #6, #7

The page currently fails WCAG 2.1 Level A in keyboard navigation, semantic HTML, and screen reader compatibility.
