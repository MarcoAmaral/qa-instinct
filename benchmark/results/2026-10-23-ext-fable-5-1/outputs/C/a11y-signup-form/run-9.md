# Accessibility audit: sign-up page

The page fails WCAG 2.2 Level AA in 9 places. 3 of them stop keyboard and screen reader users from creating an account at all: the submit control is a `div`, every focus outline is removed, and the two text fields have no labels. All 9 can be fixed in the markup alone. A corrected source is at the end.

## Scope and assumptions

- Standard: WCAG 2.2, Level AA. Severity is my judgement of impact on completing the form.
- I reviewed the source only. I did not render it, so I could not test browser defaults, real focus order or screen reader output. Those checks are listed under "Not checked".
- I assume no other stylesheet or script loads, and that the page is in English.
- I assume the logo image shows the company name. The name is not in the source, so the fix uses a placeholder.

## Findings

| # | Severity | What is wrong | Who it blocks | WCAG |
| --- | --- | --- | --- | --- |
| 1 | Blocker | **Create account** is a `div` with `onclick`. It is not in the tab order, has no role, and does not respond to Enter or Space. Pressing Enter in a field does not submit either, because the form has no submit button. | Keyboard, switch and screen reader users cannot submit. | 2.1.1, 4.1.2 |
| 2 | Blocker | `:focus { outline: none; }` removes the focus indicator from every element. | Sighted keyboard users cannot see where they are. | 2.4.7, 2.4.11 |
| 3 | Blocker | **Email** and **Password** have no `label`. Placeholder text is the only name, and it disappears once the user types. | Screen reader users hear "edit text" with no name. Everyone loses the field name while typing. | 1.3.1, 3.3.2, 4.1.2 |
| 4 | Serious | Both text fields have `id="email"`. Duplicate IDs make any `label for`, error link or `aria-describedby` point at the wrong field. | Assistive technology, and any fix for finding 3. | 1.3.1, 4.1.2 |
| 5 | Serious | The hint "At least 8 characters." is not linked to the password field. | Screen reader users reach the field without hearing the rule. | 3.3.2 |
| 6 | Serious | `tabindex="3"` on **Read the terms** puts the link first in the tab order, before the fields it follows visually. | Keyboard users land on the link before the form starts. | 2.4.3 |
| 7 | Serious | `<html>` has no `lang` attribute. | Screen readers may read English text with the wrong voice. Translation tools cannot detect the language. | 3.1.1 |
| 8 | Serious | The logo `img` has no `alt`. Screen readers read the file name "logo-2024-final.png". | Screen reader users. | 1.1.1 |
| 9 | Moderate | The email and password fields have no `autocomplete` attributes. | Users who rely on browser or password manager autofill, including users with motor or memory impairments. | 1.3.5 |
| 10 | Moderate | No `viewport` meta tag. Phones render the page at desktop width and shrink it. | Low vision users on mobile must pinch and scroll sideways. | 1.4.4, 1.4.10 |
| 11 | Minor | The button is about 26 px tall with `padding: 4px 8px`. That meets the 24 px minimum but is a small target. | Users with tremor or on touch screens. | 2.5.8 (passes), best practice |
| 12 | Minor | No `<main>` landmark. The page is short, so this is a small cost. | Screen reader users who navigate by landmark. | 1.3.1, best practice |

Two related defects are not accessibility failures but affect the same fix. The form has no `method` or `action`, so it submits by GET and puts the password in the URL. And `form.submit()` skips built-in validation, so `type="email"` never reports an error. A real submit button fixes both.

## What passes

- Text colour contrast. Body text, the hint text and the button all exceed 4.5:1 on their backgrounds.
- The checkbox has a proper wrapping `label`.
- Text sizes use `rem`, so browser zoom and text resizing work.
- The link text **Read the terms** describes its target.
- The page has a title and one `h1`.

## Not checked

I could not check these without rendering the page or running the site.

- Placeholder text contrast. Browser defaults are usually just above 4.5:1, but this varies by browser.
- Error messages. The source has no validation or error display, so 3.3.1 and 3.3.3 cannot be assessed. Add visible, text-based errors that name the field.
- The real tab order after fixes, and how each screen reader announces the form.
- The logo image content, and whether the page is reached through a flow with its own issues.

## Corrected source

This version fixes findings 1 to 12. Replace the placeholder in the logo `alt` with the company name, or use `alt=""` if the name appears as text on the page.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    label { display: block; margin-top: 1rem; }
    .btn { display: inline-block; padding: 10px 16px; background: #0a58ca; color: #fff;
           border: 0; font: inherit; margin-top: 1rem; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; margin: 0.25rem 0 0; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="[Company name]">
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

Notes on the changes:

- `button type="submit"` replaces the `div` and the script. The script is no longer needed.
- `:focus-visible` keeps a clear outline for keyboard users without showing it on mouse clicks.
- `aria-describedby` reads the hint after the password field name. `minlength` matches the hint, so the browser enforces the rule it states.
- Removing `tabindex="3"` restores the natural order: email, password, checkbox, link, button.
- The `action` value is an assumption. Set it to the real endpoint.

## Retest after fixing

1. Tab through the page from the address bar. Every control should show an outline, in the order listed above.
2. Press Enter inside the email field. The form should submit or show a validation message.
3. Open the page with a screen reader. Each field should announce its label, and the password field should also read "At least 8 characters."
4. Submit with an empty form. Each error should be shown as text next to its field.
