# Accessibility Audit: Sign-up Page

## Critical Issues (WCAG 2.1 Level A Violations)

### 1. **Removed Focus Indicator**
- **Location**: CSS rule `:focus { outline: none; }`
- **Issue**: Removes visible focus indicator for keyboard navigation
- **Impact**: Keyboard users cannot see which element has focus
- **Recommendation**: Remove this rule or replace with a visible focus style (e.g., `outline: 2px solid #0a58ca`)

### 2. **Non-semantic Button Implementation**
- **Location**: `<div class="btn" onclick="submitForm()">Create account</div>`
- **Issue**: Interactive element is a div with onclick instead of a button
- **Impact**: Screen readers don't announce it as a button; keyboard focus may not work; not keyboard accessible by default
- **Recommendation**: Use `<button type="submit">Create account</button>` instead

### 3. **Missing Alt Text on Logo**
- **Location**: `<img src="/img/logo-2024-final.png">`
- **Issue**: No alt attribute provided
- **Impact**: Screen reader users won't know what the image is
- **Recommendation**: Add `alt="Company Logo"` (or appropriate description)

## Major Issues (WCAG 2.1 Level A/AA Violations)

### 4. **Duplicate Element IDs**
- **Location**: Both email and password inputs have `id="email"`
- **Issue**: IDs must be unique in an HTML document
- **Impact**: JavaScript selectors and label associations may target wrong elements; violates HTML specification
- **Recommendation**: Change second input to `id="password"`

### 5. **Missing Form Labels for Inputs**
- **Location**: Email and password inputs use only placeholder text
- **Issue**: No associated `<label>` elements; placeholders disappear when typing
- **Impact**: Screen reader users cannot identify field purposes; visual users cannot see labels while typing
- **Recommendation**: Add labels:
  ```html
  <label for="email">Email</label>
  <input type="email" placeholder="Email" id="email">
  <label for="password">Password</label>
  <input type="password" placeholder="Password" id="password">
  ```

### 6. **Hint Text Not Associated with Input**
- **Location**: `<p class="hint">At least 8 characters.</p>` follows password field
- **Issue**: Screen readers won't associate this hint with the password input
- **Impact**: Users with screen readers won't know the password requirement
- **Recommendation**: Use `aria-describedby`:
  ```html
  <input type="password" id="password" aria-describedby="pwd-hint">
  <p class="hint" id="pwd-hint">At least 8 characters.</p>
  ```

### 7. **Insufficient Color Contrast**
- **Location**: `.hint` class uses `color: #595959` on white background
- **Issue**: Contrast ratio is approximately 4.2:1 (below WCAG AA minimum of 4.5:1 for normal text)
- **Impact**: Users with low vision or color blindness may struggle to read
- **Recommendation**: Darken text to #4a4a4a or darker for 4.5:1+ contrast

### 8. **Non-Standard Tabindex Value**
- **Location**: `<a href="/terms" tabindex="3">Read the terms</a>`
- **Issue**: Positive tabindex values create unpredictable tab order
- **Impact**: Keyboard navigation order becomes confusing
- **Recommendation**: Remove `tabindex="3"` and rely on natural DOM order, or restructure form to use tabindex="0" or -1 if needed

## Minor Issues

### 9. **Missing Form Action/Method**
- **Location**: `<form id="signup">` (no action or method)
- **Issue**: Form relies on JavaScript; will fail if JavaScript is disabled
- **Impact**: Users without JavaScript cannot submit the form
- **Recommendation**: Add `action="/signup"` and `method="POST"` attributes

### 10. **No Password Confirmation Field**
- **Issue**: User cannot verify they typed the correct password
- **Impact**: Users may create accounts they cannot log into
- **Recommendation**: Add password confirmation field (usability/security issue)

## Summary

| Severity | Count |
|----------|-------|
| Critical | 3 |
| Major    | 6 |
| Minor    | 1 |
| **Total** | **10** |

The page has significant accessibility barriers that prevent compliance with WCAG 2.1 Level A standards. The removed focus outline and non-semantic button are the most severe, as they break keyboard navigation entirely for some users.
