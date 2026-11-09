# Sign-up Page Accessibility Audit

## Critical Issues

### 1. Duplicate Input IDs
Both the email and password fields have `id="email"`. The password field should have `id="password"`. This breaks:
- Label associations (if labels were present)
- JavaScript targeting
- Form submission handling

### 2. Missing Labels for Form Inputs
Email and password inputs rely only on placeholder text, which:
- Disappears when focused, leaving no visible label
- Is not read by screen readers as a label
- Fails WCAG 2.1 Level A requirement (1.3.1 Info and Relationships)

**Assumption**: Labels should be programmatically associated via `<label for="">` or field wrapping.

### 3. Non-semantic Submit Button
The "Create account" action uses a `<div>` with `onclick` instead of `<button>`:
- Not keyboard accessible (can't be activated with Enter/Space)
- Not announced as a button to screen readers
- Requires JavaScript to function
- Fails basic HTML semantics

### 4. Removed Focus Outline
The CSS rule `:focus { outline: none; }` removes all focus indicators:
- Breaks keyboard navigation visibility
- Users cannot see which element has focus
- Violates WCAG 2.1 Level AA (2.4.7 Focus Visible)

### 5. Missing Alt Text
The logo image has no `alt` attribute:
- Screen reader users won't know what the image represents
- Fails WCAG 2.1 Level A (1.1.1 Non-text Content)

## Major Issues

### 6. Unrelated Helper Text
The hint "At least 8 characters" is not programmatically associated with the password field:
- Should use `aria-describedby` to link hint to input
- Currently appears as orphaned text to screen readers

### 7. Insufficient Tabindex Usage
The link has `tabindex="3"` but no other elements have tabindex attributes. This creates confusion about intended tab order and suggests an incomplete implementation.

### 8. Checkbox Label Accessibility
While the checkbox has a label (`<label><input type="checkbox">...`), the label text is not visually distinct, making it harder to click for users with motor control issues.

## Minor Issues

### 9. Missing Language Attribute
The `<html>` element lacks `lang="en"` (or appropriate language code):
- Impacts screen reader pronunciation
- Fails WCAG 2.1 Level A (3.1.1 Language of Page)

### 10. No Form Structure
The form lacks:
- `action` attribute (though may be handled by JavaScript)
- `method` attribute
- `novalidate` or validation attributes
- No ARIA attributes for error handling (`aria-required`, `aria-invalid`)

### 11. Color Contrast (Potential)
While blue (#0a58ca) on white likely meets WCAG AA for normal text, verify the contrast ratio is ≥4.5:1 if this button text size is below 18pt.

## Recommendations (Priority Order)

1. Replace `<div class="btn">` with `<button type="submit">`
2. Add proper `<label>` elements for email and password inputs
3. Fix duplicate ID: change password input to `id="password"`
4. Remove `:focus { outline: none; }` or replace with visible focus styling
5. Add `alt="Company Logo"` (or descriptive text) to the image
6. Add `aria-describedby="password-hint"` to password input and `id="password-hint"` to the hint `<p>`
7. Add `lang="en"` to the `<html>` tag
8. Remove inappropriate `tabindex="3"` from the link unless intentionally controlling tab order for all elements
9. Add form attributes: `action`, `method`, and validation ARIA attributes
