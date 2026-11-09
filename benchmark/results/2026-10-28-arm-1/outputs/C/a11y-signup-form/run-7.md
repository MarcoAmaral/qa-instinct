# Accessibility Audit: Sign-up Page

**Critical Issues (WCAG 2.1 Level A failures)**

1. **Logo image missing alt text**
   - The logo image has no `alt` attribute. Provide descriptive alt text (e.g., "Company logo") or mark it as decorative with `alt=""` if it is only visual.

2. **Form inputs lack associated labels**
   - Both the email and password inputs use only `placeholder` attributes. Placeholders are not accessible labels—they disappear on focus and are not announced reliably to screen readers.
   - Add `<label>` elements associated via `for` and `id` attributes:
     ```html
     <label for="email">Email</label>
     <input type="email" id="email">
     ```

3. **Duplicate input ID**
   - Both inputs have `id="email"`. The password input should have a unique ID, e.g., `id="password"`.

4. **Button is not a semantic button**
   - The form submission uses a `<div>` with `onclick`. This fails keyboard navigation and screen reader accessibility. Replace with a proper `<button>` element:
     ```html
     <button type="submit">Create account</button>
     ```
     Remove the JavaScript function; the form will submit automatically.

**High Priority Issues (WCAG 2.1 Level AA failures)**

5. **Focus indicator removed without replacement**
   - The CSS rule `:focus { outline: none; }` removes the default focus outline without providing a visible alternative. Users navigating by keyboard cannot see which control is focused.
   - Add a visible focus style:
     ```css
     :focus { outline: 2px solid #0a58ca; outline-offset: 2px; }
     ```

6. **Improper tab order**
   - The link has `tabindex="3"`, imposing a non-semantic tab order. Remove it and let the natural DOM order determine focus sequence.

**Medium Priority Issues**

7. **Placeholder text only**
   - The password field shows "At least 8 characters" as a hint paragraph, but the actual password field has no label. The hint should be associated with the field using `aria-describedby`:
     ```html
     <input type="password" id="password" aria-describedby="pwd-hint">
     <p class="hint" id="pwd-hint">At least 8 characters.</p>
     ```

8. **Missing required indicators**
   - Add `required` attribute to inputs and indicate required fields visually and in the label.

9. **Form lacks error handling**
   - Assume: Form will show validation errors. Errors should be announced to screen readers using `aria-live="polite"` and linked to fields using `aria-invalid` and `aria-describedby`.

10. **Checkbox label accessibility**
    - The checkbox is wrapped in a `<label>`, which is correct, but ensure the label text is descriptive and linked to the field.

**Contrast (assumed WCAG 2.1 Level AA compliance check)**

- The `.hint` color (#595959 on white) provides approximately 5:1 contrast, which meets Level AA for small text (14px or smaller). Confirm actual rendered size; if larger, it should meet 4.5:1 minimum.

**Recommended Refactor**

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    .btn { display: inline-block; padding: 4px 8px; background: #0a58ca; color: #fff; border: none; cursor: pointer; }
    :focus-visible { outline: 2px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <img src="/img/logo-2024-final.png" alt="Company Logo">
  <h1>Create your account</h1>
  <form id="signup">
    <label for="email">Email</label>
    <input type="email" id="email" required>
    
    <label for="password">Password</label>
    <input type="password" id="password" required aria-describedby="pwd-hint">
    <p class="hint" id="pwd-hint">At least 8 characters.</p>
    
    <label><input type="checkbox" id="terms" required> I accept the terms</label>
    <a href="/terms">Read the terms</a>
    
    <button type="submit">Create account</button>
  </form>
</body>
</html>
```
