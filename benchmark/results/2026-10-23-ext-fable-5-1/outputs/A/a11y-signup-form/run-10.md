# Accessibility audit: Sign-up page

**Verdict:** the page fails WCAG 2.2 Level A. A keyboard-only or screen-reader user cannot complete sign-up at all, because the submit control is a non-focusable `div` and the form has no real submit button, so pressing Enter does nothing either. Nine further defects range from serious to minor. All colour contrast passes.

**Assumptions**
- Target standard is WCAG 2.2 Level AA. Severity below follows the axe scale: Critical, Serious, Moderate, Minor.
- The page is in English. The logo is informative content for the organisation, not a link.
- Unstyled elements use browser defaults, including link colour and placeholder colour.
- The inline script is the only JavaScript, and nothing else validates the form client-side. Server-side behaviour is unknown.

## Findings

| # | Severity | Issue | WCAG 2.2 | Fix |
|---|---|---|---|---|
| 1 | Critical | Submit control is a `div` with `onclick`. It has no button role, is not in the tab order, and ignores Enter and Space. | 2.1.1, 4.1.2 | Replace with `<button type="submit">`. |
| 2 | Critical | Enter in a field does not submit. Per the HTML spec, a form with no submit button and more than one text-like field has no implicit submission. | 2.1.1 | Fixed by #1. |
| 3 | Serious | Global `:focus { outline: none }` removes the focus indicator from every element. Keyboard users cannot see where they are. | 2.4.7 | Delete the rule. If a custom style is wanted, use `:focus-visible` with a visible outline. |
| 4 | Serious | Email and password inputs have no label. Placeholders are not accessible names in all assistive tech and vanish once the user types. | 1.3.1, 3.3.2, 4.1.2 | Add a visible `<label for>` for each field. Keep placeholders only as examples, if at all. |
| 5 | Serious | Both inputs share `id="email"`. This is invalid HTML, breaks any `label for` association, and confuses autofill and scripts. | 4.1.2, 1.3.1 | Give the password field `id="password"`. |
| 6 | Serious | Logo `img` has no `alt`. Screen readers announce the file name. | 1.1.1 | Add `alt="<organisation name>"`, or `alt=""` if it is purely decorative. |
| 7 | Serious | `tabindex="3"` on the terms link puts it first in the tab order, before the email field. Focus order no longer matches reading order. | 2.4.3 | Remove the attribute. |
| 8 | Moderate | The "At least 8 characters" hint is not associated with the password field, so screen readers do not read it in context. | 3.3.2 | Add `id` to the hint and `aria-describedby` on the input. Add `minlength="8"` so the rule is enforced. |
| 9 | Moderate | No `autocomplete` tokens on email or password. | 1.3.5 | Add `autocomplete="email"` and `autocomplete="new-password"`. |
| 10 | Moderate | No `required` attributes and no error identification. The script calls `form.submit()`, which bypasses browser validation entirely, so an empty form posts silently. | 3.3.1, 3.3.3 | Mark fields `required`, drop the script, and let native submission run constraint validation. Add inline errors with `aria-describedby` if custom messaging is needed. |
| 11 | Moderate | `<html>` has no `lang`. Screen readers may use the wrong pronunciation rules. | 3.1.1 | Add `lang="en"`. |
| 12 | Minor | No viewport meta tag. Mobile browsers render a desktop-width layout, and low-vision users must zoom everything. | 1.4.10 | Add `<meta name="viewport" content="width=device-width, initial-scale=1">`. |
| 13 | Minor | No landmark regions. Screen-reader users cannot jump straight to the form. | 1.3.1 best practice | Wrap content in `<main>` and name the form with `aria-labelledby` pointing at the heading. |
| 14 | Minor | The terms link navigates away from a half-completed form in the same tab. | 3.2.2 advisory | Open in a new tab and say so in the link text, or show the terms in an in-page dialog. |

**What passes.** Body text, hint text, and the button all exceed the 4.5:1 contrast minimum.

| Pair | Ratio |
|---|---|
| `#222` on `#fff` | 15.9:1 |
| `#595959` on `#fff` | 7.0:1 |
| `#fff` on `#0a58ca` | 6.4:1 |

The checkbox is correctly wrapped in a label. The page has a title and a single `h1`. Font sizes use rem, so text resizing works. The button is roughly 27 px tall with default fonts, which meets the 24 px minimum target size, but only just.

## Corrected markup

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    .btn { display: inline-block; padding: 8px 16px; background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
    label { display: block; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Your organisation name">
    <h1 id="signup-heading">Create your account</h1>
    <form id="signup" method="post" action="/signup" aria-labelledby="signup-heading">
      <label for="email">Email</label>
      <input type="email" id="email" name="email" autocomplete="email" required>

      <label for="password">Password</label>
      <input type="password" id="password" name="password" autocomplete="new-password"
             minlength="8" required aria-describedby="password-hint">
      <p class="hint" id="password-hint">At least 8 characters.</p>

      <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>
      <a href="/terms" target="_blank" rel="noopener">Read the terms (opens in a new tab)</a>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

The `method` and `action` values are placeholders. The original form had neither, so it would have submitted by GET to the current URL, exposing the password in the query string. Set these to match the real endpoint.

**Verifying the fix.** Tab through the page from the address bar and confirm the order is email, password, checkbox, link, button, with a visible ring on each. Press Enter inside the password field and confirm the form submits. Submit empty and confirm the browser reports the missing fields. Run axe or the W3C validator on the corrected source, which should report no duplicate ids, no missing labels, and no missing alt text. Finally, read the form with NVDA or VoiceOver and confirm each field announces its label, the password field reads the hint, and the button announces as "Create account, button".
