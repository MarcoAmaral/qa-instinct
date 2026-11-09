# Accessibility Audit: Sign-up Page

## Critical Issues

### 1. Missing Alt Text on Logo
**Issue**: `<img src="/img/logo-2024-final.png">` has no `alt` attribute.
**Impact**: Screen reader users cannot identify the logo. The image is likely decorative, but this must be explicit.
**Fix**: Add `alt=""` if decorative, or `alt="Company logo"` if the logo is a link or meaningful content.

### 2. Focus Outline Removed
**Issue**: `:focus { outline: none; }` removes the browser's default focus indicator.
**Impact**: Keyboard users cannot see which element has focus. This breaks keyboard navigation entirely for accessibility.
**Fix**: Remove this rule and provide visible focus styles (border, background change, or box-shadow).

### 3. Duplicate Element IDs
**Issue**: Both the email and password inputs have `id="email"`.
**Impact**: Labels and other elements cannot associate correctly; JavaScript behavior becomes unpredictable.
**Fix**: Change the password input to `id="password"`.

### 4. Missing Labels for Form Inputs
**Issue**: Email and password inputs have only placeholders, no `<label>` elements.
**Impact**: Screen reader users cannot identify what each field is for. Placeholders disappear when typing, leaving sighted users confused too.
**Fix**: Add explicit labels: `<label for="email">Email</label>` and `<label for="password">Password</label>` placed visually above or beside each input.

### 5. Hint Not Associated with Input
**Issue**: "At least 8 characters" is a `<p class="hint">` with no programmatic link to the password field.
**Impact**: Screen reader users do not know this hint applies to the password field.
**Fix**: Add `aria-describedby="password-hint"` to the password input and `id="password-hint"` to the paragraph.

### 6. Non-Semantic Button
**Issue**: "Create account" is a `<div class="btn" onclick="submitForm()">` instead of a `<button>` element.
**Impact**: Screen readers do not identify it as a button; keyboard users may not be able to activate it without JavaScript; it has no default submit behavior.
**Fix**: Replace with `<button type="submit">Create account</button>`.

### 7. Checkbox Label Unclear
**Issue**: `<label><input type="checkbox" id="terms"> I accept the terms</label>` mixes the checkbox and text without clear visual separation.
**Impact**: Some assistive technologies may not correctly associate the label; the link to terms is separate from the checkbox.
**Fix**: Keep the label, but consider adding a clear visual focus indicator and ensuring the link is clearly part of the terms acceptance requirement.

### 8. Tabindex Ordering
**Issue**: `tabindex="3"` on the "Read the terms" link breaks natural tab order.
**Impact**: Keyboard users navigate out of sequence (email → password → terms link → checkbox → button becomes confusing).
**Fix**: Remove `tabindex="3"` and let the browser use document order.

### 9. No Alt Text for Implicit Link Context
**Issue**: "Read the terms" link exists but the checkbox says "I accept the terms" — the two are visually separate.
**Impact**: Unclear relationship between accepting and reading; users may not know they can read terms before accepting.
**Fix**: Place the link closer to the checkbox or nest it within the label.

## Moderate Issues

### 10. Color Contrast
**Issue**: The hint text uses `color: #595959` on a white background.
**Assumption**: Background is white (`#fff`).
**Impact**: Contrast ratio is approximately 7.8:1 (passes WCAG AA for normal text, but is at the threshold). Fine for body text but could be darker for better readability.
**Recommendation**: Increase darkness slightly (e.g., `#4a4a4a`) for better usability.

### 11. No Form-Level Error Handling or Validation Feedback
**Issue**: No visible error messages or validation feedback; users cannot tell if submission succeeds or fails.
**Impact**: Accessibility and usability concern; users do not know what went wrong if the form is rejected.
**Fix**: Add aria-live regions or explicit error messages with aria-labels if validation fails.

### 12. Missing Inputs `name` Attributes
**Issue**: Form inputs lack `name` attributes.
**Impact**: When the form submits, the values are not sent to the server.
**Fix**: Add `name="email"` and `name="password"` to the inputs.

## Summary of Fixes Required (in priority order)

1. Remove `:focus { outline: none; }` and add visible focus styles.
2. Add unique IDs and `<label>` elements for all inputs.
3. Change `<div class="btn">` to `<button type="submit">`.
4. Link the hint to the password field with `aria-describedby`.
5. Add `alt` attribute to the logo.
6. Remove `tabindex="3"` from the link.
7. Add `name` attributes to form inputs.
8. Consider reorganizing the checkbox and link for clearer relationship.
