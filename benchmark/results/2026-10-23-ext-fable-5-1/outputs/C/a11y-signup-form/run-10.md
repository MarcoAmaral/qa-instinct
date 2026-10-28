# Accessibility audit: Sign-up page

**Result:** The page cannot be completed with a keyboard or a screen reader. 3 blocking defects and 6 major defects need fixing before release. Colour contrast passes everywhere.

Standard used: WCAG 2.2, Level AA. Review method: static reading of the source only.

## Assumptions

- The source shown is the whole page. No other stylesheet or script loads.
- Browser default styles apply, with a base font size of 16 px.
- The logo image carries the company name and is the only place the name appears. I use "Acme" as a placeholder for it.
- The page is in English.
- The server returns validation errors on its own page. I cannot see that page, so error handling is reviewed only as far as this source allows.

## Findings

Ordered by severity. Each finding gives the effect on real users, the WCAG criterion, and the fix.

### Blocking

1. **The submit control is a `div`, not a button.** It is not in the tab order, has no role, and does not respond to Enter or Space. Screen readers announce "Create account" as plain text. Because the form has no real submit button and has 2 text fields, browsers also do not submit on Enter. Keyboard users have no way to create an account. (2.1.1 Keyboard, 4.1.2 Name, Role, Value.) Fix: use `<button type="submit">Create account</button>` and delete the script.

2. **Focus indicators are removed on every element.** The rule `:focus { outline: none; }` hides the only sign of where keyboard focus is. Sighted keyboard users must tab blind. (2.4.7 Focus Visible.) Fix: delete the rule, or replace it with a `:focus-visible` style that shows a 3 px outline for keyboard focus only.

3. **The email and password fields have no labels.** Placeholder text is their only name. It disappears when the user types, is often too faint to read, and is only a last-resort name for assistive technology. Voice-control users cannot say "click Email" reliably. (1.3.1 Info and Relationships, 3.3.2 Labels or Instructions, 4.1.2.) Fix: add a visible `<label for>` for each field.

### Major

4. **Both text fields share `id="email"`.** The password field reuses the email field's id. Any label, hint or script that targets the password field reaches the email field instead. (1.3.1, 4.1.2.) Fix: change the password field to `id="password"`.

5. **The password hint is not linked to the field.** "At least 8 characters." is a loose paragraph. Screen reader users hear it only if they read past the field, and never while focused on it. (3.3.2.) Fix: give the hint an id and add `aria-describedby` on the password field. Add `minlength="8"` so the browser enforces the same rule.

6. **`tabindex="3"` scrambles the focus order.** Positive tabindex values come first in the tab order. The first Tab press lands on **Read the terms**, then jumps back to the email field. Users lose their place on the first keystroke. (2.4.3 Focus Order.) Fix: remove the attribute and move the link above the checkbox, so people can read the terms before accepting them.

7. **The logo has no `alt` text.** Screen readers announce the file name, "logo-2024-final.png". (1.1.1 Non-text Content.) Fix: `alt="Acme"`. Use `alt=""` only if the company name appears as text elsewhere on the page.

8. **The page has no language.** `<html>` lacks `lang`, so screen readers may read English with another language's voice. (3.1.1 Language of Page.) Fix: `<html lang="en">`.

9. **Nothing is required and errors are never shown.** No field has `required`, and the script calls `form.submit()`, which skips browser validation of the email format. A user can submit an empty form with no feedback. (3.3.1 Error Identification, 3.3.3 Error Suggestion.) Fix: add `required` to all 3 fields and submit with a real button so the browser validates. Confirm the server's error page names each field in error.

### Minor

10. **No `autocomplete` attributes.** Browsers and password managers cannot fill the fields for people with memory or motor impairments. (1.3.5 Identify Input Purpose.) Fix: `autocomplete="email"` and `autocomplete="new-password"`.

11. **No viewport meta tag.** On phones the page renders at desktop width and the user must pinch to zoom each field. (1.4.10 Reflow.) Fix: add `<meta name="viewport" content="width=device-width, initial-scale=1">`. Do not add `user-scalable=no`.

12. **Small submit target.** With 4 px vertical padding the control is about 27 px tall. That passes the 24 px minimum (2.5.8) but is below the 44 px recommended for touch. Fix: use 12 px by 16 px padding.

13. **No landmark.** The page has no `<main>`, so screen reader users cannot jump to the content. Advisory. Fix: wrap the content in `<main>`.

## What passes

| Check | Result |
| --- | --- |
| Body text #222 on white | About 15.9:1, passes AA and AAA |
| Hint text #595959 on white | About 7.0:1, passes AA and AAA |
| Button text white on #0a58ca | About 6.5:1, passes AA |
| Page has a title and one `h1` | Passes 2.4.2 and 1.3.1 |
| Checkbox is inside a `<label>` | Passes 1.3.1 and 4.1.2 |
| Character encoding declared | Passes |

## Not checkable from source

- Placeholder text contrast depends on the browser's default colour. It is often below 4.5:1. The fix in finding 3 makes this moot.
- Behaviour at 200% zoom and 320 px width.
- The server's error page after submission.
- Whether the logo file is readable at high contrast settings.

## Out of scope, but urgent

The form has no `method` or `action`. It submits by GET to the current URL, which puts the password in the address bar, browser history and server logs. Add `method="post"` and an `action`.

## Corrected markup

All fixes above applied. Replace "Acme" and the `action` path with the real values.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    label { display: block; margin-top: 12px; }
    .hint { color: #595959; font-size: 0.9rem; }
    .btn { display: inline-block; padding: 12px 16px; background: #0a58ca;
           color: #fff; border: 0; font: inherit; margin-top: 16px; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
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
      <input type="password" id="password" name="password"
             autocomplete="new-password" minlength="8" required
             aria-describedby="password-hint">
      <p class="hint" id="password-hint">At least 8 characters.</p>

      <p><a href="/terms">Read the terms</a></p>
      <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

## Retest plan

1. Tab through the page. Order must be email, password, checkbox, link, button, with a visible ring on each.
2. Press Enter in the password field. The form must submit, or show a validation message if a field is empty.
3. With a screen reader, confirm each field announces its label, and the password field also announces the hint.
4. Load the page at 320 px width and 200% zoom. No horizontal scrolling.
