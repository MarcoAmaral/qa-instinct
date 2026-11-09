# Accessibility Audit Report: Sign-up Page

## Critical Issues

### 1. Focus Indicator Removed
- **Location**: CSS `:focus { outline: none; }`
- **Issue**: Removing default focus outlines without providing alternative focus styles makes the page unusable for keyboard navigation. Users cannot see which element has focus.
- **WCAG Violation**: 2.4.7 Focus Visible (Level AA)
- **Recommendation**: Remove the `:focus { outline: none; }` rule and either use default focus indicators or define visible custom focus styles with sufficient contrast.

### 2. Non-Semantic Button Element
- **Location**: `<div class="btn" onclick="submitForm()">Create account</div>`
- **Issue**: The submit action uses a `<div>` with an `onclick` handler instead of a `<button>` element. Divs are not keyboard-accessible by default and don't announce their purpose to assistive technologies.
- **WCAG Violation**: 4.1.2 Name, Role, Value (Level A)
- **Recommendation**: Replace with `<button type="submit">Create account</button>` within the form.

### 3. Duplicate ID Attributes
- **Location**: Password input has `id="email"` (should be unique)
- **Issue**: Both email and password inputs share `id="email"`, breaking label associations and form functionality.
- **WCAG Violation**: 4.1.1 Parsing (Level A)
- **Recommendation**: Change password input to `id="password"`.

### 4. Missing Image Alt Text
- **Location**: `<img src="/img/logo-2024-final.png">`
- **Issue**: No `alt` attribute. Users of screen readers cannot understand the image's purpose.
- **WCAG Violation**: 1.1.1 Non-text Content (Level A)
- **Assumption**: Logo is decorative or represents the brand name.
- **Recommendation**: Use `alt="[Company Name]"` if it's a logo, or `alt=""` if purely decorative.

## Major Issues

### 5. Missing Form Labels
- **Location**: Email and password inputs
- **Issue**: Inputs lack associated `<label>` elements. Screen reader users won't know what each field is for.
- **WCAG Violation**: 1.3.1 Info and Relationships (Level A), 3.3.2 Labels or Instructions (Level A)
- **Recommendation**: Wrap each input in a `<label>` or associate via `aria-label`:
  ```html
  <label for="email">Email</label>
  <input type="email" id="email" placeholder="Email">
  ```

### 6. Hint Text Not Associated with Input
- **Location**: `<p class="hint">At least 8 characters.</p>` after password field
- **Issue**: The hint is semantically disconnected from the password input. Screen reader users won't know this hint relates to that field.
- **WCAG Violation**: 1.3.1 Info and Relationships (Level A)
- **Recommendation**: Add `aria-describedby="password-hint"` to the password input and `id="password-hint"` to the hint paragraph.

### 7. Checkbox Label Clarity
- **Location**: `<label><input type="checkbox" id="terms"> I accept the terms</label>`
- **Issue**: The label is vague—it doesn't specify *which* terms or provide context.
- **WCAG Violation**: 3.3.2 Labels or Instructions (Level A)
- **Recommendation**: Clarify the label text: "I accept the Terms of Service and Privacy Policy"

### 8. Explicit Tabindex on Link
- **Location**: `<a href="/terms" tabindex="3">Read the terms</a>`
- **Issue**: Explicit positive tabindex values (`tabindex="3"`) disrupt natural tab order and complicate maintenance.
- **WCAG Violation**: 2.4.3 Focus Order (Level A)
- **Recommendation**: Remove `tabindex="3"` and rely on the natural DOM order.

## Minor Issues

### 9. Missing Viewport Meta Tag
- **Location**: Missing from `<head>`
- **Issue**: Without a viewport meta tag, the page may not scale properly on mobile devices, affecting usability for some users.
- **WCAG Violation**: Related to 1.4.4 Resize Text (Level AA)
- **Recommendation**: Add `<meta name="viewport" content="width=device-width, initial-scale=1">`

### 10. Missing HTML Language Attribute
- **Location**: `<html>` tag
- **Issue**: No `lang` attribute specified. Screen readers may use incorrect pronunciation rules.
- **WCAG Violation**: 3.1.1 Language of Page (Level A)
- **Assumption**: Page is in English.
- **Recommendation**: Add `<html lang="en">`

### 11. Missing Form-Level Error Handling
- **Issue**: No visible error messages or aria-live announcements for validation errors.
- **WCAG Violation**: 3.3.4 Error Prevention (Level AA)
- **Recommendation**: Add error messaging with `aria-live="polite"` for dynamic feedback.

### 12. Color Contrast in Hint Text
- **Location**: `.hint { color: #595959; }`
- **Issue**: #595959 on #fff has a contrast ratio of approximately 5.9:1. While it meets AA for body text (4.5:1), it's barely compliant and may be difficult for users with low vision.
- **WCAG Violation**: 1.4.3 Contrast (Minimum) (Level AA)
- **Recommendation**: Use darker color (e.g., #464646 or darker) for better contrast.

## Summary of Required Changes

| Severity | Count |
|----------|-------|
| Critical | 4 |
| Major    | 5 |
| Minor    | 3 |
| **Total**| **12**|

**Pass/Fail**: **FAIL** — Multiple Level A violations prevent keyboard and screen reader users from using this form.
