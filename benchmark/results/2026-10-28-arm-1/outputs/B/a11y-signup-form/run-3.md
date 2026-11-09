# Accessibility Audit: Sign-up Page

## Critical Issues

**1. Focus Outline Removed**
- **Issue**: CSS rule `:focus { outline: none; }` eliminates all keyboard navigation indicators
- **Impact**: Keyboard and screen reader users cannot see which element has focus
- **WCAG Level**: Fails 2.4.7 Focus Visible (Level AA)
- **Fix**: Remove this rule or replace with visible focus styling (border, background, or box-shadow)

**2. Button is Not a Button**
- **Issue**: Submit control is a `<div class="btn">` with `onclick`, not a `<button>`
- **Impact**: Not keyboard accessible; screen readers won't announce it as interactive; no native form submission
- **WCAG Level**: Fails 4.1.2 Name, Role, Value (Level A)
- **Fix**: Replace with `<button type="submit" class="btn">Create account</button>`

**3. No Labels for Form Inputs**
- **Issue**: Email and password inputs rely on `placeholder` text only; no associated `<label>` elements
- **Impact**: Screen readers cannot announce input purpose; placeholder disappears when user starts typing
- **WCAG Level**: Fails 1.3.1 Info and Relationships (Level A)
- **Fix**: Add explicit labels:
  ```html
  <label for="email">Email</label>
  <input type="email" id="email" placeholder="Email">
  ```

**4. Duplicate Input IDs**
- **Issue**: Both email and password inputs have `id="email"`
- **Impact**: Invalid HTML; form submission may target wrong field; programmatic associations fail
- **WCAG Level**: Fails 4.1.1 Parsing (Level A)
- **Fix**: Change password field to `id="password"`

## Major Issues

**5. Hardcoded Tab Order**
- **Issue**: Link has `tabindex="3"` while form fields have no explicit tabindex, breaking tab sequence
- **Impact**: Keyboard users navigate in confusing, non-intuitive order
- **WCAG Level**: Fails 2.4.3 Focus Order (Level A)
- **Fix**: Remove hardcoded `tabindex`; rely on document order

**6. Missing Language Declaration**
- **Issue**: `<html>` tag has no `lang` attribute
- **Impact**: Screen readers cannot determine page language for proper pronunciation
- **WCAG Level**: Fails 3.1.1 Language of Page (Level A)
- **Fix**: Add `<lang="en">` (or appropriate language code)

**7. Logo Missing Alt Text**
- **Issue**: `<img src="/img/logo-2024-final.png">` has no `alt` attribute
- **Impact**: Assumption: logo is decorative. If it's content, screen reader users cannot access it
- **WCAG Level**: Fails 1.1.1 Non-text Content (Level A)
- **Fix**: Add `alt=""` if decorative, or descriptive `alt="Company Logo"` if it conveys meaning

**8. Hint Text Not Associated**
- **Issue**: "At least 8 characters" hint is not programmatically connected to password field
- **Impact**: Screen reader users won't know the hint applies to the password requirement
- **WCAG Level**: Fails 1.3.1 Info and Relationships (Level A)
- **Fix**: Add `aria-describedby="password-hint"` to password input and `id="password-hint"` to hint paragraph

## Minor Issues

**9. Contrast Close to Minimum**
- **Issue**: Hint text (#595959) on white background has ~5.8:1 contrast ratio
- **Impact**: Passes WCAG AA (4.5:1) but provides minimal safety margin; may be difficult for low-vision users
- **WCAG Level**: Passes Level AA; borderline (Level AAA requires 7:1)
- **Fix**: Darken hint text to #404040 or darker for better readability

**10. Inaccessible Form Submission**
- **Issue**: JavaScript `onclick` handler; no fallback if JavaScript fails or is disabled
- **Impact**: Form cannot be submitted without JavaScript
- **WCAG Level**: Fails 2.1.1 Keyboard (Level A)
- **Fix**: Use `<button type="submit">` to enable native form submission

**11. Checkbox Label Lacks Visual Separation**
- **Issue**: Checkbox label text runs directly after checkbox with no spacing/punctuation
- **Impact**: Minor readability issue; text could be clearer
- **Fix**: Add spacing or punctuation for clarity

## Summary

| Severity | Count |
|----------|-------|
| Critical | 4 |
| Major | 7 |
| Minor | 3 |

**WCAG Conformance**: Does not meet Level A (legal minimum for accessibility)

**Keyboard Navigation**: Fails (hardcoded tabindex + non-button submit + no focus indicators)

**Screen Reader**: Fails (unlabeled inputs, non-semantic button, missing alt text)
