# Accessibility Audit: Sign-up Page

**Scope and assumptions.** Static review of the supplied HTML against WCAG 2.2 Level AA. No browser, screen reader, or runtime testing was possible, so anything that depends on rendering is marked *inferred*. I assume: the page is in English; the logo is the only brand identification on the page and is therefore informative; browser default styles apply wherever the stylesheet is silent; JavaScript is enabled; server-side behaviour is unknown.

**Overall result: fails WCAG 2.2 AA.** A keyboard-only user cannot submit this form at all, and a screen-reader user cannot reliably tell which field is which.

| Severity | Count | Findings |
|---|---|---|
| Blocker | 3 | 1, 2, 3 |
| Critical | 3 | 4, 5, 6 |
| Major | 3 | 7, 8, 9 |
| Minor | 3 | 10, 11, 12 |

## Findings

**1. Blocker. The submit control is a `div`, not a button.**
WCAG 2.1.1 Keyboard, 4.1.2 Name Role Value.
The element is not focusable, has no role, and ignores Enter and Space. Screen readers announce it as plain text. Pressing Enter inside a field does not submit either: the form has no submit button and contains two text-type fields, so the HTML implicit-submission rule does not apply. Keyboard and most screen-reader users have no way to create an account. The control also does nothing with JavaScript disabled.
Fix: replace with `<button type="submit">Create account</button>` and delete the inline script.

**2. Blocker. Focus indicator removed site-wide.**
WCAG 2.4.7 Focus Visible.
The rule `:focus { outline: none; }` hides focus on every element with no replacement. Sighted keyboard users cannot see where they are.
Fix: delete the rule, or replace it with a `:focus-visible` style that has at least 3:1 contrast against adjacent colours.

**3. Blocker. Email and password fields have no label.**
WCAG 1.3.1 Info and Relationships, 3.3.2 Labels or Instructions, 4.1.2.
Placeholder text is the only identification. It disappears as soon as the user types, is not a programmatic label in all assistive technologies, and is low contrast by default (see contrast table). Users with memory or cognitive impairments lose the field's purpose mid-entry.
Fix: add a visible `<label for>` to each field.

**4. Critical. Duplicate `id="email"` on both inputs.**
WCAG 1.3.1, 4.1.2 (and 4.1.1 Parsing under WCAG 2.1).
Any `label for="email"` would bind to the first field only, so the password field could never receive a label. Assistive technology and browser autofill may identify the password field as the email field. The duplicate also breaks any script that targets the field by id.
Fix: change the second id to `password`.

**5. Critical. Positive `tabindex="3"` on the terms link.**
WCAG 2.4.3 Focus Order.
Elements with a positive tabindex are visited before everything else. This link is the only one, so the first Tab press on the page lands on "Read the terms", before the email field. Combined with finding 2, the user's first keystroke moves focus somewhere invisible and out of reading order.
Fix: remove the `tabindex` attribute.

**6. Critical. Logo image has no `alt` attribute.**
WCAG 1.1.1 Non-text Content.
Screen readers will announce the filename, "logo-2024-final.png", or just "image". The logo is the only brand identification on the page, so it is informative.
Fix: `alt="<Company name>"`. Use `alt=""` only if the company name is added as visible text elsewhere.

**7. Major. Password hint, constraints, and input purpose are not exposed programmatically.**
WCAG 1.3.1, 3.3.2, 1.3.5 Identify Input Purpose.
"At least 8 characters" is a visual-only paragraph; screen readers do not read it when the password field has focus. There is no `minlength`, so the rule is not enforced. Neither field has `autocomplete`, which 1.3.5 requires for fields collecting user data, and which also blocks password managers from offering a generated password.
Fix: give the hint an id and reference it with `aria-describedby`; add `minlength="8"`; add `autocomplete="email"` and `autocomplete="new-password"`.

**8. Major. No `lang` attribute on `<html>`.**
WCAG 3.1.1 Language of Page.
Screen readers may use the wrong speech synthesiser and mispronounce the content.
Fix: `<html lang="en">` (assumed English).

**9. Major. No validation or error messaging path.**
WCAG 3.3.1 Error Identification, 3.3.3 Error Suggestion.
No field is `required`, the terms checkbox is not enforced, and calling `form.submit()` from script bypasses browser constraint validation entirely. A user who submits an empty or invalid form gets no client-side feedback. Whether the server returns accessible errors is unknown.
Fix: use a native submit button so built-in validation runs, add `required` to all three controls, and ensure any server-side errors are listed at the top of the form with links to the fields and are announced via a live region.

**10. Minor (inferred). No viewport meta tag.**
WCAG 1.4.10 Reflow.
Mobile browsers will render the page at desktop width and scale it down, forcing pinch-zoom to read or operate the form.
Fix: add `<meta name="viewport" content="width=device-width, initial-scale=1">` and do not disable user scaling.

**11. Minor. No landmarks and the form has no accessible name.**
Best practice supporting 1.3.1 and 2.4.1.
Screen-reader users cannot jump to the main content or identify the form in a landmark list.
Fix: wrap the content in `<main>` and add `aria-labelledby` on the form pointing at the heading.

**12. Minor (inferred). Small, unstyled target with no affordance.**
WCAG 2.5.8 Target Size (Minimum), 2.5.5 (AAA).
At a 16px base, the padding of 4px by 8px gives a button roughly 27px tall. That passes the 24px minimum but is well under the 44px recommended size. There is no pointer cursor, hover, focus, or active state, so sighted users have no cue that it is interactive.
Fix: `min-height: 44px`, `cursor: pointer`, and distinct hover and focus styles.

**Functional defects noticed in passing (not accessibility, but blocking QA sign-off).** Neither input has a `name` attribute, so the form currently submits no data. The form has no `method`, so once names are added it would submit via GET and place the password in the URL and server logs. Add `method="post"` and an `action`.

## What passes

| Check | Detail | Result |
|---|---|---|
| Body text contrast | #222 on #fff, 15.9:1 | Pass |
| Hint text contrast | #595959 on #fff at 14.4px, 7.0:1 | Pass |
| Button text contrast | #fff on #0a58ca, 6.4:1 | Pass |
| Placeholder contrast (inferred) | Browser default, Chrome #757575 on #fff, about 4.6:1 | Marginal, varies by browser |
| Terms checkbox | Wrapped in a `<label>`, so it has an accessible name | Pass |
| Page title | "Sign up" is present and relevant | Pass |
| Heading structure | Single `<h1>` describing the page | Pass |
| Link text | "Read the terms" is descriptive out of context | Pass |
| Text sizing | No fixed pixel font sizes, so browser zoom and text resize work | Pass |
| Input type | `type="email"` gives mobile users the right keyboard | Pass |

## Corrected markup and browser verification

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
    .btn { display: inline-block; min-height: 44px; padding: 8px 16px;
           background: #0a58ca; color: #fff; border: 0; cursor: pointer; }
    .btn:hover { background: #084298; }
    :focus-visible { outline: 3px solid #1a1a1a; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Company name">
    <h1 id="signup-heading">Create your account</h1>
    <form id="signup" method="post" action="/signup" aria-labelledby="signup-heading">
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

Once the fixes are applied, verify in a browser what this review could not:

- Tab through the page: order should be email, password, checkbox, link, button, with a visible ring on each.
- Press Enter in the email field: the form should submit or show validation errors.
- With a screen reader, focus the password field: it should announce "Password, edit, secure, required, At least 8 characters."
- Check placeholder and error-message colours against the 4.5:1 threshold in each target browser.
- Load on a phone at 320px width: no horizontal scrolling, controls at least 44px tall.
- Run an automated scan (axe or Lighthouse) to confirm no remaining duplicate ids or missing names.
