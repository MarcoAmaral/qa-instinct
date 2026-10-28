## Summary

**Scope and assumptions.** Target standard is WCAG 2.2 Level AA. Content is English, so the page language is assumed to be `en`. The logo is assumed to be the only place the company name appears, so it is informative rather than decorative. No server-side validation or JavaScript beyond the inline script is assumed. The audit is a static review of the source, so screen reader and browser behaviour below is predicted from the spec, not observed.

**Verdict.** The page fails WCAG 2.2 AA and is not usable by keyboard-only or screen reader users. A keyboard user cannot submit the form at all. Four defects are blockers, four are high, and the rest are medium or low.

| Severity | Count | Items |
|---|---|---|
| Blocker | 4 | 1, 2, 3, 4 |
| High | 4 | 5, 6, 7, 8 |
| Medium | 3 | 9, 10, 11 |
| Low | 2 | 12, 13 |

## Findings

**1. Submit control is a `div`, so the form cannot be submitted from the keyboard. Blocker. SC 2.1.1 Keyboard, 4.1.2 Name, Role, Value.**
- The "Create account" element has no `tabindex`, no `role`, and only an `onclick` handler. It never receives focus and does not respond to Enter or Space.
- Pressing Enter inside a text field does not help. The HTML spec disables implicit submission when a form has no submit button and more than one text-type field, and this form has two.
- Screen readers announce it as plain text, not a button.
- Fix: replace it with `<button type="submit" class="btn">Create account</button>` and delete the inline script.

**2. Focus indicator is removed globally. Blocker. SC 2.4.7 Focus Visible, 2.4.11 Focus Not Obscured.**
- The rule `:focus { outline: none; }` hides focus on every element with no replacement style. Sighted keyboard users cannot tell where they are.
- Fix: delete the rule, or replace it with a visible `:focus-visible` style of at least 3:1 contrast against adjacent colours.

**3. Email and password fields have no label. Blocker. SC 1.3.1 Info and Relationships, 3.3.2 Labels or Instructions, 4.1.2.**
- Both inputs rely on `placeholder` alone. Placeholder text disappears on input, is not a reliable accessible name across assistive technologies, and the user-agent default colour typically fails contrast.
- Fix: add a visible `<label for="...">` for each input. Keep the placeholder only as an example value, if at all.

**4. Duplicate `id="email"` on the password input. Blocker. SC 4.1.1 Parsing in 2.0 and 2.1, and a direct cause of 1.3.1 and 4.1.2 failures.**
- Two elements share one id, so any `label for="email"` or `aria-describedby` would bind to the wrong field, and `getElementById` returns only the first.
- Fix: change the password input to `id="password"`.

**5. Page language is not declared. High. SC 3.1.1 Language of Page.**
- The `<html>` element has no `lang`. Screen readers may pick the wrong pronunciation rules and translation tools may misdetect the language.
- Fix: `<html lang="en">`.

**6. Logo has no text alternative. High. SC 1.1.1 Non-text Content.**
- The `<img>` lacks `alt`. Screen readers will read the file name, "logo-2024-final.png", which is noise.
- Fix: `alt="Acme"` with the real company name, or `alt=""` if the name appears elsewhere as text.

**7. Positive `tabindex` on the terms link breaks focus order. High. SC 2.4.3 Focus Order.**
- Elements with a positive tabindex are focused before everything else. The first Tab press lands on "Read the terms", then jumps back to Email, Password, and the checkbox.
- Fix: remove `tabindex="3"`. Links are focusable by default and DOM order is already logical.

**8. Password hint is not associated with the field. High. SC 3.3.2 Labels or Instructions, 1.3.1.**
- "At least 8 characters." is a loose paragraph. Screen reader users who tab straight into the field never hear it.
- Fix: give the paragraph `id="password-hint"` and add `aria-describedby="password-hint"` to the password input. Add `minlength="8"` so the rule is also enforced.

**9. No input purpose metadata. Medium. SC 1.3.5 Identify Input Purpose.**
- Neither field has `autocomplete`. Browsers and assistive tools cannot auto-fill or identify the fields.
- Fix: `autocomplete="email"` on the email field and `autocomplete="new-password"` on the password field.

**10. No required marking or error handling. Medium. SC 3.3.1 Error Identification, 3.3.2.**
- Nothing is marked `required`, the checkbox is not enforced, and the inline script calls `form.submit()`, which bypasses constraint validation entirely. Users receive no feedback on empty or invalid input.
- Fix: add `required` to all three controls and use a real submit button so native validation runs. Add visible, programmatically linked error messages if custom validation is introduced later.

**11. No viewport meta tag. Medium. SC 1.4.10 Reflow.**
- Mobile browsers will lay the page out at a desktop width and shrink it, so text becomes very small and users must pinch-zoom to read and tap.
- Fix: `<meta name="viewport" content="width=device-width, initial-scale=1">`. Do not add `user-scalable=no`.

**12. Button target is small. Low. SC 2.5.8 Target Size Minimum passes, 2.5.5 Enhanced fails.**
- At 4px vertical padding the control is roughly 26px tall. That meets the 24px AA minimum but misses the 44px AAA recommendation and will be hard to tap on touch devices.
- Fix: `min-height: 44px` and `padding: 10px 16px` on the button.

**13. Form has no accessible name. Low. Best practice under 1.3.1.**
- Screen reader form-landmark lists will show an unnamed form.
- Fix: `aria-labelledby="signup-heading"` on the form, pointing at the `<h1>`.

**Checks that pass.** Body text `#222` on white is about 15.9:1. Hint text `#595959` on white is about 7.0:1. Button text white on `#0a58ca` is about 6.4:1. All three meet AA for normal text. The page has a `<title>`, a single `<h1>`, and the checkbox is correctly wrapped in a `<label>`. Font sizes use relative units.

**Adjacent functional defects, outside accessibility scope but blocking release.** No input has a `name` attribute, so nothing is sent on submit. The form has no `method` or `action`, so it defaults to GET, which would place the password in the URL once names are added. Use `method="post"`.

## Remediated source and verification plan

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    .field { margin-bottom: 1rem; }
    label { display: block; }
    .btn { display: inline-block; min-height: 44px; padding: 10px 16px;
           background: #0a58ca; color: #fff; border: 0; font: inherit; cursor: pointer; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; margin: 0.25rem 0 0; }
  </style>
</head>
<body>
  <img src="/img/logo-2024-final.png" alt="Acme">
  <h1 id="signup-heading">Create your account</h1>
  <form id="signup" method="post" action="/signup" aria-labelledby="signup-heading">
    <div class="field">
      <label for="email">Email</label>
      <input type="email" id="email" name="email" autocomplete="email" required>
    </div>
    <div class="field">
      <label for="password">Password</label>
      <input type="password" id="password" name="password" autocomplete="new-password"
             required minlength="8" aria-describedby="password-hint">
      <p class="hint" id="password-hint">At least 8 characters.</p>
    </div>
    <div class="field">
      <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>
      <a href="/terms">Read the terms</a>
    </div>
    <button type="submit" class="btn">Create account</button>
  </form>
</body>
</html>
```

Replace "Acme" and the `action` URL with real values.

**Verification once a browser is available.**
1. Keyboard only: Tab order should be Email, Password, checkbox, terms link, Create account. Every stop must show a visible outline. Enter in either text field and Enter or Space on the button must submit.
2. Screen reader: NVDA with Firefox and VoiceOver with Safari. Each field should announce its label, the password field should also read the hint, and the submit control should announce as "button".
3. Automated: run axe-core and the W3C HTML validator. Expect zero duplicate-id, missing-label, missing-alt, and missing-lang errors.
4. Validation: submit empty, submit a 7-character password, and submit with the checkbox unchecked. Each must be blocked with a visible message.
5. Zoom and reflow: 200% text zoom and a 320px-wide viewport with no horizontal scrolling or clipped content.
6. Contrast: confirm the three colour pairs above and the new focus outline with a contrast checker.
