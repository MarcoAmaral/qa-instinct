# Accessibility Audit Report: Sign-Up Page

## Critical Issues

### 1. **Duplicate Element IDs**
- **Location**: Email input and password input both have `id="email"`
- **Impact**: HIGH - Breaks form functionality and assistive technology mapping
- **WCAG**: 1.3.1 Info and Relationships (Level A)
- **Finding**: The password field should have `id="password"`. This breaks label associations and JavaScript references.

### 2. **Non-Semantic Button Element**
- **Location**: `<div class="btn" onclick="submitForm()">Create account</div>`
- **Impact**: HIGH - Not keyboard accessible, not recognized as a button by screen readers
- **WCAG**: 2.1.1 Keyboard (Level A), 4.1.2 Name, Role, Value (Level A)
- **Recommendation**: Replace with `<button type="submit">Create account</button>` and remove the onclick handler

### 3. **Removed Focus Indicators**
- **Location**: `:focus { outline: none; }` in CSS
- **Impact**: HIGH - Keyboard users cannot see which element has focus
- **WCAG**: 2.4.7 Focus Visible (Level AA)
- **Recommendation**: Remove this rule entirely or replace with visible focus styling (e.g., `outline: 2px solid #0a58ca; outline-offset: 2px;`)

### 4. **Missing Image Alt Text**
- **Location**: `<img src="/img/logo-2024-final.png">`
- **Impact**: MEDIUM - Logo purpose unclear to screen reader users
- **WCAG**: 1.1.1 Non-text Content (Level A)
- **Recommendation**: Add descriptive alt text: `alt="Company Logo"` or equivalent

## Major Issues

### 5. **Missing Form Labels**
- **Location**: Email and password inputs
- **Impact**: MEDIUM - Users cannot identify input purposes; placeholder text is not sufficient
- **WCAG**: 1.3.1 Info and Relationships (Level A)
- **Finding**: Both inputs use only placeholder attributes. Screen reader users will not hear field labels.
- **Recommendation**: Add `<label>` elements:
  ```html
  <label for="email">Email</label>
  <input type="email" id="email" placeholder="Email">
  <label for="password">Password</label>
  <input type="password" id="password" placeholder="Password">
  ```

### 6. **Missing Field Description Association**
- **Location**: Password field and hint text
- **Impact**: MEDIUM - Hint "At least 8 characters" is not programmatically associated with the password input
- **WCAG**: 1.3.1 Info and Relationships (Level A)
- **Recommendation**: Use `aria-describedby`: `<input type="password" id="password" aria-describedby="pwd-hint">` and `<p id="pwd-hint" class="hint">At least 8 characters.</p>`

### 7. **Problematic Tabindex Value**
- **Location**: `<a href="/terms" tabindex="3">Read the terms</a>`
- **Impact**: MEDIUM - Hardcoding positive tabindex values is an anti-pattern that disrupts natural tab order
- **WCAG**: 2.4.3 Focus Order (Level A)
- **Recommendation**: Remove `tabindex="3"` to rely on natural DOM order

## Minor Issues

### 8. **Insufficient Color Contrast**
- **Location**: `.hint { color: #595959; }` on white background
- **Impact**: LOW-MEDIUM - Text contrast ratio is approximately 4.5:1 (passes AA for 14px+ text, fails for smaller sizes)
- **WCAG**: 1.4.3 Contrast (Minimum) (Level AA)
- **Assumption**: Hint text renders at 0.9rem (approximately 14.4px)
- **Recommendation**: Use darker color such as `#333333` for better contrast margin

### 9. **Missing Form Submission Semantics**
- **Location**: Checkbox and form structure
- **Impact**: LOW - Form uses JavaScript submit rather than native form submission
- **Recommendation**: Use standard form submission with `<button type="submit">` instead of onclick handler

### 10. **No Error Handling or Validation UX**
- **Impact**: LOW - No visible indication of required fields or validation errors for assistive technology users
- **Recommendation**: Add `required` attributes, `aria-required="true"`, and error message regions with `role="alert"`

## Summary

**Critical fixes needed**: 3 (duplicate IDs, non-semantic button, removed focus indicators)  
**Should fix**: 5 additional issues  
**WCAG Level**: Currently fails Level A and AA conformance

**Estimated effort to remediate**: Low (all issues are straightforward markup corrections)
