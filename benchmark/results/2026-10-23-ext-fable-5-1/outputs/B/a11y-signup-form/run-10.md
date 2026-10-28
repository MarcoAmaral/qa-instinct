# Accessibility audit: Sign-up page

**Verdict:** Fails WCAG 2.2 Level A. Keyboard-only and screen-reader users cannot complete sign-up. Nine defects block or degrade use, four of them critical. Colour contrast and heading structure pass.

**Scope and assumptions.** Static source review only, no browser or assistive-technology testing. Assumed target is WCAG 2.2 AA, modern Chromium, Firefox and Safari, with default user-agent styles for anything not set in the stylesheet. Assumed `submitForm()` is the only submission path, since the form has no submit button.

## Findings

| # | Severity | Issue | WCAG |
|---|----------|-------|------|
| 1 | Critical | Submit control is a `div` with `onclick`. It is not in the tab order, has no button role, and does not respond to Enter or Space. | 2.1.1, 4.1.2 |
| 2 | Critical | Enter inside the fields does nothing. Implicit submission is disabled when a form has two or more text fields and no submit button. Combined with #1, keyboard users have no way to submit. | 2.1.1 |
| 3 | Critical | Email and password inputs have no label. Placeholder text is not an accessible name in all assistive technologies and disappears once the user types. | 1.3.1, 3.3.2, 4.1.2 |
| 4 | Critical | `:focus { outline: none }` removes the focus indicator from every element on the page. Keyboard users cannot see where they are. | 2.4.7 |
| 5 | High | Duplicate `id="email"` on both inputs. Invalid HTML. Any future `<label for="email">` or `aria-describedby` would bind to the wrong field, and `getElementById` returns only the first. | 4.1.1 (legacy), 1.3.1 |
| 6 | High | `<html>` has no `lang` attribute. Screen readers may use the wrong pronunciation rules. | 3.1.1 |
| 7 | High | Logo image has no `alt`. Screen readers announce the file name "logo-2024-final.png". | 1.1.1 |
| 8 | High | Password hint "At least 8 characters" is a loose paragraph, not linked to the password field via `aria-describedby`. Screen-reader users in forms mode never hear it. | 1.3.1, 3.3.2 |
| 9 | Medium | `tabindex="3"` on the terms link. Positive tabindex pulls the link ahead of the fields in tab order, so focus jumps from the page start to the link, then back to the inputs. | 2.4.3 |
| 10 | Medium | No `autocomplete` attributes. Browsers and password managers cannot reliably identify the fields. Expected values are `email` and `new-password`. | 1.3.5 |
| 11 | Medium | No validation or error messaging. Nothing is `required`, the password has no `minlength`, and `form.submit()` bypasses built-in constraint validation entirely, so even `type="email"` is never enforced. Users get no error identification. | 3.3.1, 3.3.3 |
| 12 | Low | Button padding of 4px by 8px gives a target height of roughly 24px at default font size. This is at the WCAG 2.2 minimum and will fall below it if the font is set smaller. | 2.5.8 |
| 13 | Low | No `<meta name="viewport">`. Mobile browsers render at desktop width and users must pinch-zoom to read. | 1.4.4, 1.4.10 |

## Checks that pass

- **Colour contrast.** Button white on `#0a58ca` is about 6.4:1. Hint `#595959` on white is about 7.0:1. Body `#222` on white is about 15.9:1. All exceed AA for normal text.
- **Page title and heading.** A `<title>` and a single `<h1>` are present and descriptive.
- **Terms checkbox.** Wrapped in a `<label>`, so it has an accessible name.

**Caveat on contrast.** Placeholder text uses the browser default colour, typically around `#757575`, which sits near the 4.5:1 threshold. If placeholders are kept as visible hints after labels are added, set an explicit colour.

## Non-accessibility issue noticed

The form has no `method` or `action`. Submission defaults to GET on the current URL, which places the password in the query string, browser history and server logs. Out of scope for this audit, but it should be fixed before release.

## Recommended corrected markup

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    .btn { display: inline-block; padding: 8px 16px; min-height: 24px;
           background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 2px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <img src="/img/logo-2024-final.png" alt="Acme">
  <h1>Create your account</h1>
  <form id="signup" method="post" action="/signup" novalidate>
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

Notes on the fix: replace the logo `alt` with the real organisation name, or use `alt=""` if the heading already carries it. The `novalidate` attribute is optional and should be paired with custom inline error messages that use `aria-describedby` and `aria-invalid`. If native validation is preferred, drop `novalidate`.

## Suggested verification once a browser is available

1. Tab through the page with no mouse. Confirm order is email, password, checkbox, link, button, and that a focus ring is visible on each.
2. Press Enter in the password field. Confirm the form submits.
3. Run axe-core or Lighthouse. Confirm zero violations for labels, duplicate IDs, image alt, and document language.
4. Test with NVDA plus Firefox and VoiceOver plus Safari. Confirm each field announces its label, the password field announces the hint, and the submit control announces as a button.
5. Submit the form empty. Confirm errors are announced and focus moves to the first invalid field.
