**Accessibility audit: Sign-up page**

Scope and assumptions: audited against WCAG 2.2 Level AA from source only, so nothing was verified in a browser or with assistive technology. I assume the logo is the site or company logo, the page has no external CSS or scripts beyond what is shown, and the server performs no validation that would change the client-side findings.

**Verdict:** the page fails AA. The form cannot be completed by keyboard alone, and screen reader users get no field names and no usable submit control. Seven blocking or serious defects are listed first, then minor ones, then what already passes.

## Findings

1. **Submit control is not a button (Critical).** The "Create account" element is a `div` with an `onclick`, so it is not in the tab order, has no button role or name, and ignores Enter and Space. Because the form has no real submit button, pressing Enter in a field does not submit either. Replace it with `<button type="submit">`. WCAG 2.1.1, 4.1.2.

2. **Focus indicator removed globally (Critical).** The rule `:focus { outline: none; }` hides focus on every element, so sighted keyboard users cannot tell where they are. Delete the rule, or use `:focus-visible` with a visible replacement of at least 3:1 contrast. WCAG 2.4.7, 1.4.11.

3. **Fields have no labels (Critical).** The email and password inputs rely on placeholders, which vanish on typing and are not a reliable accessible name. Add visible `<label for>` elements and keep placeholders only as examples. WCAG 1.3.1, 3.3.2, 4.1.2.

4. **Duplicate `id="email"` on two inputs (Serious).** The password field reuses the email field's ID, so any label, `aria-describedby`, or script targeting it resolves to the wrong element. Rename the password field's ID. WCAG 4.1.2 (and 4.1.1 under 2.1).

5. **Positive `tabindex="3"` on the terms link (Serious).** Positive values are focused before every natural-order element, so the link receives focus before the email field, which contradicts the visual order. Remove the attribute. WCAG 2.4.3.

6. **Logo image has no `alt` (Serious).** Screen readers will announce the filename. Use `alt="<Company name>"` if it is informative, or `alt=""` if purely decorative. WCAG 1.1.1.

7. **Password hint is not associated with its field (Moderate).** The "At least 8 characters" text is a loose paragraph, so it is not read when the password field gains focus. Give it an ID and reference it with `aria-describedby`. WCAG 3.3.2.

8. **No input purpose declared (Moderate).** Missing `autocomplete="email"` and `autocomplete="new-password"` blocks browser autofill and password managers. WCAG 1.3.5.

9. **No `lang` on the `html` element (Moderate).** Screen readers may pick the wrong voice or pronunciation. Add `lang="en"`. WCAG 3.1.1.

10. **No validation or error reporting (Moderate).** Nothing is `required`, and the script calls `form.submit()`, which bypasses built-in constraint validation. Users who miss a field or leave the terms unchecked get no feedback. Add `required`, let the native submit run, and surface errors in text associated with the field. WCAG 3.3.1, 3.3.3.

11. **Small click target (Minor).** The button renders about 26 CSS pixels tall, which only just clears the 24 pixel minimum. Pad it to 44 pixels for comfortable touch use. WCAG 2.5.8.

12. **No viewport meta tag (Minor).** Mobile browsers will render a desktop-width layout and shrink it, making the form hard to read before zooming. Add the standard viewport tag without disabling user scaling. WCAG 1.4.4, 1.4.10.

## What passes

| Check | Result |
|---|---|
| Body text #222 on white | 15.9:1, passes |
| Hint #595959 on white at 14.4px | 7.0:1, passes |
| Button white on #0a58ca | 6.4:1, passes |
| Page title present | Passes 2.4.2 |
| Single `h1` heading | Passes 1.3.1 |
| Checkbox wrapped in `label` | Passes 1.3.1, 4.1.2 |
| Charset declared | Passes |

## Recommended markup

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    .btn { display: inline-block; min-height: 44px; padding: 10px 16px; background: #0a58ca; color: #fff; border: 0; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
    label { display: block; margin-top: 1rem; }
  </style>
</head>
<body>
  <img src="/img/logo-2024-final.png" alt="Company name">
  <h1>Create your account</h1>
  <form id="signup" method="post" action="/signup">
    <label for="email">Email</label>
    <input type="email" id="email" name="email" autocomplete="email" required>

    <label for="password">Password</label>
    <input type="password" id="password" name="password"
           autocomplete="new-password" minlength="8" required
           aria-describedby="password-hint">
    <p class="hint" id="password-hint">At least 8 characters.</p>

    <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>
    <a href="/terms">Read the terms</a>

    <button type="submit" class="btn">Create account</button>
  </form>
</body>
</html>
```

The inline script is no longer needed because a native submit button handles submission and triggers constraint validation. If a script must remain, call `form.requestSubmit()` rather than `form.submit()` so validation and submit listeners still run. Error messages should be rendered in text next to each field and referenced by `aria-describedby`, and the first invalid field should receive focus after a failed submit.
