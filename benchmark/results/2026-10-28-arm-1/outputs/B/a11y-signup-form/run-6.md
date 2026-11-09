# Accessibility Audit Report: Sign-Up Page

## Critical Issues (WCAG 2.1 Level A/AA Failures)

### 1. Missing Alt Text on Logo Image
- **Location**: Line 12
- **Issue**: `<img src="/img/logo-2024-final.png">` has no `alt` attribute
- **Impact**: Screen reader users receive no information about the image
- **Recommendation**: Add `alt="Company Logo"` or `alt=""` if purely decorative

### 2. Duplicate Form Input IDs
- **Location**: Lines 16-17
- **Issue**: Both email and password inputs have `id="email"`
  ```html
  <input type="email" placeholder="Email" id="email">
  <input type="password" placeholder="Password" id="email">
  ```
- **Impact**: Invalid HTML; causes ID collision, breaking form functionality and accessibility tools
- **Recommendation**: Change password input to `id="password"`

### 3. Form Inputs Lack Associated Labels
- **Location**: Lines 16-17
- **Issue**: Email and password inputs use only `placeholder` attributes; no `<label>` elements with `for` attribute
- **Impact**: Screen readers cannot identify form fields; placeholders disappear on focus, leaving no visual label for sighted users; fails WCAG 1.3.1
- **Recommendation**: Add proper labels:
  ```html
  <label for="email">Email</label>
  <input type="email" id="email">
  <label for="password">Password</label>
  <input type="password" id="password">
  ```

### 4. Focus Outline Removed with No Replacement
- **Location**: Line 7 (CSS)
- **Issue**: `:focus { outline: none; }` removes default focus styling
- **Impact**: Keyboard users cannot see which element has focus; violates WCAG 2.4.7
- **Recommendation**: Remove this rule or replace with visible focus styling:
  ```css
  :focus { outline: 2px solid #0a58ca; }
  ```

### 5. Hint Text Not Semantically Connected to Password Field
- **Location**: Line 18
- **Issue**: "At least 8 characters" is a standalone `<p>` with no association to the password input
- **Impact**: Screen reader users may not understand this requirement applies to the password field
- **Recommendation**: Use `aria-describedby`:
  ```html
  <input type="password" id="password" aria-describedby="password-hint">
  <p class="hint" id="password-hint">At least 8 characters.</p>
  ```

### 6. Non-Semantic Button Element
- **Location**: Line 21
- **Issue**: "Create account" is a `<div>` with `onclick` handler, not a `<button>`
- **Impact**: Not keyboard accessible (cannot tab to it or activate with Enter/Space); not recognized as a button by screen readers; loses semantic meaning
- **Recommendation**: Use proper button element:
  ```html
  <button type="submit" class="btn">Create account</button>
  ```

### 7. Insufficient Color Contrast
- **Location**: Line 10 (CSS)
- **Issue**: Hint text `color: #595959` on white background has ~2.86:1 contrast ratio
- **Impact**: Fails WCAG AA requirement (4.5:1 for normal text); illegible for users with low vision
- **Recommendation**: Darken hint text to `#333` or similar for ~8:1 contrast

### 8. Non-Standard Tabindex Usage
- **Location**: Line 20
- **Issue**: `tabindex="3"` on the terms link; using positive tabindex values disrupts natural tab order
- **Impact**: Confusing keyboard navigation flow
- **Recommendation**: Remove `tabindex="3"` and rely on DOM order, or use `tabindex="0"` if needed

## Moderate Issues

### 9. Missing Language Attribute
- **Issue**: `<html>` tag lacks `lang` attribute
- **Impact**: Screen readers cannot determine language for proper pronunciation
- **Recommendation**: Add `<html lang="en">`

### 10. No Form Validation or Error Feedback
- **Issue**: No ARIA live regions, error messages, or validation feedback structure
- **Impact**: Validation errors will not be announced to screen reader users
- **Recommendation**: Implement `aria-live="polite"` region for error messages

### 11. Missing Placeholder Attribute on Password Input
- **Issue**: Password field has placeholder text but is missing from some potential states
- **Recommendation**: Ensure consistent labeling regardless of placeholder

## Summary

**Severity Breakdown:**
- **Critical (Level A/AA Failures)**: 8 issues preventing accessibility compliance
- **Moderate (Best Practices)**: 3 issues affecting user experience

**Estimated WCAG Compliance**: Non-compliant (Level A and AA failures present)

**Priority Fixes**: 
1. Add proper form labels (affects all users)
2. Fix duplicate IDs (breaks functionality)
3. Restore focus indicators (keyboard accessibility)
4. Convert div to button (semantic and keyboard access)
5. Improve color contrast (low-vision users)
