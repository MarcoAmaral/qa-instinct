# Accessibility audit: sign-up page

**Scope and assumptions.** Reviewed against WCAG 2.2 Level AA by static reading of the source only. Assumed: the page is in English, the logo is the site's brand image and not a link, no external CSS or JavaScript is loaded beyond what is shown, and `submitForm()` is the only submission path. Contrast ratios are calculated from the declared colors.

## Summary

| Severity | Count | Issues |
|---|---|---|
| Critical | 3 | Non-keyboard submit control, focus indicator removed globally, form fields have no labels |
| Serious | 6 | Duplicate `id`, hint not linked to field, positive `tabindex`, missing `alt`, missing `lang`, no `autocomplete` |
| Moderate | 2 | No required/validation or error messaging, `form.submit()` bypasses browser validation |
| Minor | 4 | No viewport meta, no landmark, borderline button target size, placeholder contrast risk |

Color contrast of the declared text colors passes. Body text, the hint, and the button all exceed 4.5:1 (roughly 15.9:1, 7.0:1 and 6.4:1 respectively).

## Findings

**1. The "Create account" control is a `div`, not a button. Critical. WCAG 2.1.1, 4.1.2.**
The `div.btn` has an `onclick` but is not focusable, has no `button` role, no accessible name as a control, and does not respond to Enter or Space. Keyboard and screen-reader users cannot submit. Because the form contains two text-type fields and no real submit button, browsers also do not perform implicit submission on Enter, so there is no fallback path at all.
Fix: replace with a native button. This also restores Enter-to-submit from any field.
```html
<button type="submit" class="btn">Create account</button>
```

**2. Focus indicator removed for every element. Critical. WCAG 2.4.7.**
`:focus { outline: none; }` hides the focus ring on all inputs, the checkbox, the link and any future button. Sighted keyboard users cannot tell where they are.
Fix: delete the rule, or replace it with a visible custom indicator.
```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

**3. Email and password fields have no label. Critical. WCAG 1.3.1, 3.3.2, 4.1.2.**
Placeholder text is the only identification. It disappears once the user types, is not reliably announced by all screen readers, and is not a programmatic label. The default placeholder color in most browsers is also at or below the 4.5:1 threshold, so even the visual cue is weak.
Fix: add visible `<label for>` elements and keep the placeholder only as an example, if at all.
```html
<label for="email">Email</label>
<input type="email" id="email" name="email">
<label for="password">Password</label>
<input type="password" id="password" name="password">
```

**4. Both inputs share `id="email"`. Serious. WCAG 4.1.1 (parsing), breaks 1.3.1.**
Duplicate IDs make any `label for`, `aria-describedby` or autofill association ambiguous, and `getElementById` will only ever find the first one. Rename the password field's `id` to `password`.

**5. Password hint is not associated with the field. Serious. WCAG 3.3.2.**
"At least 8 characters." is a loose paragraph. Screen-reader users who tab straight into the password field never hear the requirement.
Fix:
```html
<input type="password" id="password" aria-describedby="pw-hint" ...>
<p class="hint" id="pw-hint">At least 8 characters.</p>
```

**6. `tabindex="3"` on the terms link. Serious. WCAG 2.4.3.**
A positive tabindex is visited before every element with tabindex 0, so the link receives focus before the email field. Tab order no longer matches reading order and the link's position next to the checkbox is lost. Remove the attribute; the natural DOM order is already correct.

**7. Logo image has no `alt`. Serious. WCAG 1.1.1.**
Screen readers will announce the file name "logo-2024-final.png". Under the assumption the logo is decorative here, because the `h1` already states the page purpose, use `alt=""`. If it is or becomes a link to the home page, use the organisation name instead, for example `alt="Swareco"`.

**8. No `lang` on `<html>`. Serious. WCAG 3.1.1.**
Without `lang="en"`, screen readers may pick the wrong pronunciation rules and translation tools cannot identify the language. Add `<html lang="en">`.

**9. No `autocomplete` on personal-data fields. Serious. WCAG 1.3.5.**
Fields collecting the user's email and a new password must declare their purpose so browsers and assistive tech can autofill and identify them. Add `autocomplete="email"` and `autocomplete="new-password"`.

**10. No required marking, validation or error messaging. Moderate. WCAG 3.3.1, 3.3.3.**
Nothing marks the fields or the terms checkbox as required, and there is no mechanism to identify or describe an error on this page. Assuming the server validates, errors still need a visible, text-based, programmatically associated message on return. Add `required` to all three controls and `minlength="8"` to the password so the browser surfaces errors before submission, and reserve an `aria-live` region or inline error text with `aria-describedby` for server-side errors.

**11. `form.submit()` skips constraint validation. Moderate. Related to 3.3.1.**
Calling `submit()` programmatically bypasses `type="email"`, `required` and `minlength` checks, so the fixes in item 10 would never run. The native submit button from item 1 removes the need for this script entirely. Delete the inline script.

**12. Minor items.**
- No `<meta name="viewport" content="width=device-width, initial-scale=1">`. Mobile browsers will render at desktop width and the form will need pinch-zooming, which undermines reflow (1.4.10).
- No `<main>` landmark. Add one around the heading and form for 1.3.1 and screen-reader navigation.
- Button height with 4px padding and default line height is roughly 27 CSS pixels, which passes 2.5.8 but with little margin. Increase vertical padding to at least 8px.
- The page title "Sign up" meets 2.4.2 but would be more useful with the site name, for example "Sign up – Swareco".

**Out of scope but worth flagging.** The form has no `method` or `action`, so it submits by GET and places the password in the URL and server logs. Add `method="post"`.

## Corrected markup

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up – Swareco</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    label { display: block; margin-top: 1rem; }
    .btn { display: inline-block; padding: 8px 16px; background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <img src="/img/logo-2024-final.png" alt="">
  <main>
    <h1>Create your account</h1>
    <form id="signup" method="post" action="/signup">
      <label for="email">Email</label>
      <input type="email" id="email" name="email" autocomplete="email" required>

      <label for="password">Password</label>
      <input type="password" id="password" name="password" autocomplete="new-password"
             minlength="8" required aria-describedby="pw-hint">
      <p class="hint" id="pw-hint">At least 8 characters.</p>

      <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>
      <a href="/terms">Read the terms</a>

      <p><button type="submit" class="btn">Create account</button></p>
    </form>
  </main>
</body>
</html>
```

Remaining work after applying this markup: implement visible, programmatically associated error messages for server-side validation failures, and confirm the logo's decorative status with the design owner.
