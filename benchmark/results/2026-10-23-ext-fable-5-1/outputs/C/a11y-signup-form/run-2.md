# Accessibility audit: Sign up page

The page cannot be completed with a keyboard or a screen reader. Fix the 3 critical issues before release, then the rest in the order below.

## Scope and assumptions

- Source review only. Nothing was rendered, so contrast values are calculated from the CSS, and browser defaults are assumed where the CSS is silent.
- Standard: WCAG 2.2 level AA.
- The logo is the company logo and is not a link. The company name is assumed to be **Acme**; replace it in the fix.
- There is no error handling, no server-side validation hint and no viewport tag, because none appear in the source.
- The page language is English.

## Findings

| # | Severity | Issue | WCAG | Who is blocked |
| --- | --- | --- | --- | --- |
| 1 | Critical | **Create account** is a `div`, not a button. It is not in the tab order, has no role and pressing Enter does nothing. | 2.1.1, 4.1.2 | Keyboard and screen reader users cannot submit. |
| 2 | Critical | **Email** and **Password** have no labels. Placeholder text is the only name, and it disappears when typing. | 1.3.1, 3.3.2, 4.1.2 | Screen reader users hear unlabelled fields. Everyone loses the field name after typing. |
| 3 | Critical | `:focus { outline: none; }` removes the focus ring from every element. | 2.4.7, 2.4.11 | Keyboard users cannot see where they are. |
| 4 | High | The password field reuses `id="email"`. Duplicate ids break label association and script lookups. | 1.3.1, 4.1.2 | Any label pointing at `email` names the wrong field. |
| 5 | High | `tabindex="3"` on **Read the terms** puts the link first in the tab order, before **Email**. | 2.4.3 | Keyboard users land on the link before the form. |
| 6 | High | The logo has no `alt` attribute. Screen readers read the file name "logo-2024-final". | 1.1.1 | Screen reader users. |
| 7 | High | `<html>` has no `lang` attribute. | 3.1.1 | Screen readers may use the wrong voice. |
| 8 | Medium | The hint "At least 8 characters." is not linked to **Password**. | 3.3.2 | Screen reader users do not hear the rule when they reach the field. |
| 9 | Medium | No `autocomplete` on **Email** or **Password**. | 1.3.5 | Users who rely on browser or password manager autofill. |
| 10 | Medium | **Create account** is about 24 px tall at the default font size. That is the minimum, with no margin for a smaller font. | 2.5.8 | Touch and motor-impaired users. |
| 11 | Medium | No viewport meta tag. Mobile browsers render at desktop width. | 1.4.10 | Mobile and low-vision users who zoom. |
| 12 | Low | No `required` attributes and no error messages. Script submission also skips the browser's email format check. | 3.3.1, 3.3.3 | Everyone, when a field is empty or wrong. |
| 13 | Low | No `main` landmark. | 1.3.1, 2.4.1 | Screen reader users navigating by landmark. Minor on a 1-form page. |

Not an accessibility issue, but it blocks the form: no input has a `name` attribute, so the submission sends no data.

## What passes

| Check | Result |
| --- | --- |
| Body text #222 on #fff | 15.9:1, passes AA and AAA |
| Hint text #595959 on #fff | 7.0:1, passes AA and AAA |
| Button text #fff on #0a58ca | 6.4:1, passes AA |
| Page has a title and a single `h1` | Passes |
| **I accept the terms** checkbox has a wrapping label | Passes |

Placeholder contrast could not be checked. It uses the browser default colour, which fails AA in some browsers. Finding 2 removes the dependency on placeholders.

## Fixes

### 1. Replace the div with a submit button

```html
<button type="submit" class="btn">Create account</button>
```

Remove the `submitForm` script. A real submit button gives keyboard access, the button role, Enter-to-submit and native validation.

### 2 and 4. Add labels and unique ids

```html
<label for="email">Email</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<label for="password">Password</label>
<input type="password" id="password" name="password" autocomplete="new-password"
       minlength="8" required aria-describedby="password-hint">
<p class="hint" id="password-hint">At least 8 characters.</p>
```

This also covers findings 8, 9 and 12. Keep the placeholders out, or use them only for examples such as "name@example.com".

### 3. Restore a visible focus ring

```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

Delete the `:focus { outline: none; }` rule. If the design needs a custom ring, it must be at least 2 px thick and have 3:1 contrast against the background.

### 5. Remove the positive tabindex

```html
<a href="/terms">Read the terms</a>
```

The link then follows the checkbox in natural order.

### 6. Describe the logo

```html
<img src="/img/logo-2024-final.png" alt="Acme">
```

If a separate heading or text already names the company, use `alt=""` instead.

### 7 and 11. Set the language and viewport

```html
<html lang="en">
<meta name="viewport" content="width=device-width, initial-scale=1">
```

### 10. Enlarge the button

```css
.btn { display: inline-block; min-height: 44px; padding: 10px 16px; background: #0a58ca; color: #fff; }
```

### 13. Add a landmark

Wrap the heading and form in `<main>`.

## Corrected source

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    .btn { display: inline-block; min-height: 44px; padding: 10px 16px; background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
    label { display: block; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Acme">
    <h1>Create your account</h1>
    <form id="signup" method="post" action="/signup">
      <label for="email">Email</label>
      <input type="email" id="email" name="email" autocomplete="email" required>

      <label for="password">Password</label>
      <input type="password" id="password" name="password" autocomplete="new-password"
             minlength="8" required aria-describedby="password-hint">
      <p class="hint" id="password-hint">At least 8 characters.</p>

      <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>
      <a href="/terms">Read the terms</a>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

The `action` and `method` values are assumed. Match them to the real endpoint.

## Check in a browser before release

1. Tab from the address bar. The order must be **Email**, **Password**, **I accept the terms**, **Read the terms**, **Create account**, and the focus ring must be visible on each.
2. Fill in the fields and press Enter in **Password**. The form must submit.
3. Submit with an empty email. The browser must show an error on the field, and the error text must meet 4.5:1 contrast.
4. With a screen reader, confirm each field announces its label, and that **Password** also announces "At least 8 characters."
5. Zoom to 200% and 400%. Nothing may overlap or need horizontal scrolling.
6. Confirm the placeholder colour, if you keep any, meets 4.5:1.
