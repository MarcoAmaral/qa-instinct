# Accessibility audit: Sign-up page

**Verdict:** the page is not usable by keyboard or screen-reader users and fails WCAG 2.2 Level AA. The blocking defect is the submit control. It is a `div` with a click handler, so a keyboard user has no way to create an account at all. Pressing Enter in a field does not help either, because browsers only implicitly submit a form with two text-type fields when a real submit button exists.

**Assumptions.** Target is WCAG 2.2 AA. The inline CSS and script are the complete styling and behaviour. The logo is the only brand identification on the page. Both fields and the terms checkbox are required for sign-up.

## Findings

Severity: Blocker stops a group of users completing the task. Major degrades the task significantly. Minor is a conformance or quality gap.

| # | Severity | Issue | WCAG |
|---|----------|-------|------|
| 1 | Blocker | Submit control is a `div`, not a button | 2.1.1, 4.1.2 |
| 2 | Blocker | All focus indicators removed | 2.4.7 |
| 3 | Major | Fields have no labels, only placeholders | 1.3.1, 3.3.2, 4.1.2 |
| 4 | Major | Duplicate id on email and password inputs | 1.3.1, 4.1.2 |
| 5 | Major | Logo image has no alt text | 1.1.1 |
| 6 | Major | Positive tabindex breaks focus order | 2.4.3 |
| 7 | Major | Document has no language | 3.1.1 |
| 8 | Major | Native validation bypassed, no error messages | 3.3.1, 3.3.3 |
| 9 | Minor | Password hint not linked to the field | 3.3.2 |
| 10 | Minor | No autocomplete hints on inputs | 1.3.5 |
| 11 | Minor | Placeholder contrast likely fails | 1.4.3 |
| 12 | Minor | Button target height is marginal | 2.5.8 |
| 13 | Minor | No landmark regions | best practice |

**1. Submit control is a div.** It is not in the tab order, has no button role, and does not respond to Enter or Space. Screen readers announce it as plain text. Replace it with a native button.

**2. Focus indicators removed.** The global rule `:focus { outline: none; }` hides focus on every element with no replacement. Sighted keyboard users cannot see where they are. Delete the rule, or restyle focus with a visible indicator.

**3. No labels.** Placeholders vanish once the user types, are not read reliably as names by all assistive technology, and offer nothing to voice-control users who say "click Email". Add a visible label for each field.

**4. Duplicate id.** Both inputs carry `id="email"`. Any label, description, or script that targets that id will bind to the first field only. The password field becomes unreachable by id. Give the password field its own id.

**5. Logo without alt.** Screen readers will read the filename, which here leaks "logo-2024-final". If the logo identifies the site, the alt text should be the brand name. If it is decorative, use an empty alt.

**6. Positive tabindex.** The value `tabindex="3"` puts the terms link first in the whole tab sequence, before the email field. Remove the attribute. Links are focusable by default.

**7. Missing language.** Without a `lang` attribute, screen readers may pick the wrong voice and pronounce the text incorrectly. Add `lang="en"` or the correct language.

**8. Validation bypassed.** The script calls the form's `submit()` method, which skips constraint validation and the submit event. The email type check never fires, blank fields pass, and no error is ever shown. Mark required fields, use a real submit button, and render errors in text linked to the field.

**9. Hint not associated.** The "At least 8 characters" text is visible but not announced when the password field gets focus. Link it with `aria-describedby`.

**10. Autocomplete.** Email should declare `autocomplete="email"` and the password `autocomplete="new-password"`. This helps users with cognitive or motor impairments and enables password managers.

**11. Placeholder contrast.** Specified colours all pass. Body text, the hint, and the button are between 6.4:1 and 15.9:1. Browser default placeholder grey is typically below 4.5:1 on white. This stops mattering once real labels exist.

**12. Target size.** Padding of 4px top and bottom gives the button a height of roughly 26px, barely over the 24px minimum. Increase vertical padding.

**13. Landmarks.** Wrap the content in `main` so screen-reader users can jump to it.

**Out of scope but worth flagging.** The form has no method or action, so it submits with GET to the current URL and puts the password in the query string and server logs.

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
    label { display: block; margin-top: 1rem; }
    .btn { display: inline-block; padding: 10px 16px; background: #0a58ca;
           color: #fff; border: 0; font: inherit; margin-top: 1rem; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
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

      <label>
        <input type="checkbox" id="terms" name="terms" required>
        I accept the <a href="/terms">terms</a>
      </label>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

Replace "Acme" with the real brand name, or use `alt=""` if the logo is purely decorative. The link now sits inside the checkbox label text, which keeps it reachable in a sensible order and removes the need for a custom tabindex. Server-side validation should return errors as text next to each field, with `aria-describedby` pointing to them and `aria-invalid="true"` on the failing input.
