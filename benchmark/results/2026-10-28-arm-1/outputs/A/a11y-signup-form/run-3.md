# Accessibility Audit: Sign-up Page

## Critical Issues

### 1. **Duplicate Element IDs**
Both the email and password inputs have `id="email"`, creating invalid HTML and breaking form functionality. The password field should have `id="password"`.

### 2. **Focus Outline Removed**
The CSS rule `:focus { outline: none; }` removes keyboard navigation indicators without providing a replacement. Keyboard and switch users cannot see which element is focused. This violates WCAG 2.1 criterion 2.4.7 (Focus Visible).

### 3. **Non-Semantic Button**
The "Create account" action uses a `<div class="btn" onclick="submitForm()">` instead of a `<button>`. This breaks:
- Keyboard interaction (Enter/Space keys don't work without custom JavaScript)
- Screen reader announcement (not recognized as a clickable control)
- Form submission semantics

### 4. **Missing Form Labels**
Email and password inputs lack `<label>` elements, relying only on `placeholder` text. Placeholders disappear when focused, leaving screen reader users without field identification. This violates WCAG 2.1 criterion 3.3.2 (Labels or Instructions).

### 5. **Missing Image Alt Text**
The logo image lacks an `alt` attribute, making it inaccessible to screen readers.

## High-Priority Issues

### 6. **Missing `lang` Attribute**
The `<html>` tag lacks `lang="en"` (or appropriate language code), preventing screen readers from setting the correct language context.

### 7. **Illogical Tab Order**
The link has `tabindex="3"`, creating an arbitrary tab order that breaks the natural source-order navigation. Remove explicit tabindex values unless absolutely necessary.

## Medium-Priority Issues

### 8. **Color Contrast in Hint Text**
The hint text (#595959 on white) has a contrast ratio of approximately 6.7:1, which technically passes WCAG AA but is at the lower acceptable boundary for small text (0.9rem). Consider darker text for better readability.

### 9. **Missing Input Type Consistency**
The password input is not visually distinguished from email input, and users cannot toggle password visibility without JavaScript.

## Summary of Required Fixes

| Priority | Fix |
|----------|-----|
| Critical | Change `<div class="btn">` to `<button>` |
| Critical | Add `:focus { outline: 2px solid; }` or equivalent visible focus indicator |
| Critical | Add `<label>` elements for email and password inputs |
| Critical | Fix duplicate `id="email"` on password field |
| Critical | Add `alt=""` (or descriptive alt) to logo image |
| High | Add `lang="en"` to `<html>` tag |
| High | Remove `tabindex="3"` from link |
| Medium | Darken hint text color or increase font size |
