# Accessibility audit: Sign-up page

**Scope and method.** Static review of the supplied source against WCAG 2.2 Level AA. No browser, screen reader, or automated scanner was run, so anything that depends on rendering or browser defaults is marked "verify in browser."

**Assumptions.**
- WCAG 2.2 AA is the conformance target.
- The supplied markup is the whole page. No other stylesheet or script changes its behavior.
- The logo is the only branding on the page and is meaningful, not decorative.
- The "Create account" control is the only intended submission path. No server-side validation or error display is visible, so none is assumed.
- Unstyled controls render with browser defaults.

**Result: Fail.** A keyboard-only user cannot submit the form at all, and no user can see where keyboard focus is. Both must be fixed before release.

| Severity | Count | Issue numbers |
|---|---|---|
| Blocker | 2 | 1, 2 |
| High | 5 | 3, 4, 5, 6, 7 |
| Medium | 3 | 8, 9, 10 |
| Low | 3 | 11, 12, 13 |

## Findings

**1. Blocker. The submit control is a `div`, so the form cannot be submitted by keyboard or assistive technology.** WCAG 2.1.1 Keyboard (A), 4.1.2 Name, Role, Value (A).
- Evidence: `<div class="btn" onclick="submitForm()">Create account</div>`. A `div` is not focusable, has no button role, and does not respond to Enter or Space.
- Pressing Enter inside a text field does not help. The HTML implicit-submission rule only fires when a form with no submit button has a single text-like field, and this form has two.
- Impact: keyboard, switch, and screen reader users have no way to create an account. Voice control users cannot say "click button" because no button exists.
- Fix: replace with `<button type="submit">Create account</button>` and drop the inline script. Native submission also runs built-in validation, which the current `form.submit()` call skips.

**2. Blocker. Focus indication is removed for every element.** WCAG 2.4.7 Focus Visible (AA).
- Evidence: `:focus { outline: none; }` with no replacement style.
- Impact: sighted keyboard users cannot tell which field or link is active anywhere on the page.
- Fix: delete the rule. If a custom indicator is wanted, use `:focus-visible` with a visible outline of at least 2px and 3:1 contrast against adjacent colors.

**3. High. The email and password fields have no labels. Placeholder text is the only cue.** WCAG 1.3.1 Info and Relationships (A), 3.3.2 Labels or Instructions (A), 4.1.2 (A).
- Evidence: `placeholder="Email"` and `placeholder="Password"` with no `<label>`, `aria-label`, or `aria-labelledby`.
- Impact: the placeholder vanishes as soon as the user types, so the field's purpose is lost for users with memory or attention impairments. Placeholder-as-name is a browser fallback, not a guarantee, and some assistive technologies ignore it.
- Default placeholder color in Chromium is close to #a9a9a9 on white, roughly 2.5:1, which fails 1.4.3. Verify in browser.
- Fix: add a visible `<label for="...">` for each field. Keep placeholders only as example values, never as the label.

**4. High. Duplicate `id="email"` on two inputs.** WCAG 1.3.1 (A), 4.1.2 (A). Also fails 4.1.1 Parsing under WCAG 2.1, which many procurement checklists still cite.
- Evidence: both the email and password inputs carry `id="email"`.
- Impact: any `label for="email"` or `aria-describedby` will bind to the first input only, so the password field can never be correctly labeled until this is fixed. Scripts and browser autofill that look up by id also target the wrong element.
- Fix: change the password input to `id="password"`.

**5. High. Positive `tabindex` puts the terms link first in the tab order.** WCAG 2.4.3 Focus Order (A).
- Evidence: `<a href="/terms" tabindex="3">`. Elements with a positive tabindex are focused before every element in natural order.
- Impact: the first Tab press on the page lands on "Read the terms," then jumps back up to Email. The order is illogical and does not match the visual layout.
- Fix: remove the `tabindex` attribute. Links are focusable by default.

**6. High. Logo image has no text alternative.** WCAG 1.1.1 Non-text Content (A).
- Evidence: `<img src="/img/logo-2024-final.png">` with no `alt` attribute.
- Impact: screen readers announce the file name, "logo-2024-final.png," which is noise. Users relying on the logo to confirm which service they are signing up for get nothing.
- Fix: add `alt="<Company name>"`. If the logo is purely decorative, use `alt=""` instead.

**7. High. Page language is not declared.** WCAG 3.1.1 Language of Page (A).
- Evidence: `<html>` has no `lang` attribute.
- Impact: screen readers may read the page with the wrong pronunciation rules, and browser translation prompts behave unpredictably.
- Fix: `<html lang="en">`, or the correct language code.

**8. Medium. The password hint is not associated with the password field.** WCAG 3.3.2 (A), 1.3.1 (A).
- Evidence: `<p class="hint">At least 8 characters.</p>` follows the input but is not linked to it.
- Impact: screen reader users who tab directly to the field never hear the requirement. They discover it only after a failed submission, and this page shows no errors either.
- Fix: give the paragraph an id and add `aria-describedby="password-hint"` to the password input. Also add `minlength="8"` so the browser enforces it.

**9. Medium. No required fields, no validation, and no error reporting.** WCAG 3.3.1 Error Identification (A), 3.3.3 Error Suggestion (AA).
- Evidence: no `required` attributes. The custom `submitForm()` calls `form.submit()`, which bypasses the `type="email"` check and the `submit` event. The form has no `method`, so it defaults to GET and puts the password in the URL. That is a security defect beyond this audit's scope but it should be raised with the owner.
- Impact: empty or malformed submissions go through silently. If the server rejects them, nothing in this page tells the user what went wrong or where.
- Fix: mark email, password, and the terms checkbox `required`, use a native submit button, set `method="post"`, and render server or client errors in text linked to the relevant field with `aria-describedby` and `aria-invalid="true"`.

**10. Medium. Input purpose is not identified for autofill.** WCAG 1.3.5 Identify Input Purpose (AA).
- Evidence: no `autocomplete` attributes on the email or password fields.
- Impact: users with cognitive or motor impairments cannot rely on browser or password manager autofill.
- Fix: `autocomplete="email"` on the email field and `autocomplete="new-password"` on the password field.

**11. Low. No viewport meta tag.** WCAG 1.4.10 Reflow (AA). Verify in browser.
- Evidence: the `<head>` has no `<meta name="viewport">`.
- Impact: mobile browsers render the page at desktop width and shrink it, which forces zooming and two-dimensional scrolling.
- Fix: add `<meta name="viewport" content="width=device-width, initial-scale=1">`. Do not add `user-scalable=no` or a `maximum-scale`.

**12. Low. Target size of the checkbox and button is borderline.** WCAG 2.5.8 Target Size Minimum (AA). Verify in browser.
- Evidence: the default checkbox is about 13px square, and the button is roughly 27px tall at a 16px font. The checkbox is wrapped in its label, so the label text extends the clickable area and likely passes.
- Fix: once the button is a real `<button>`, give it at least `min-height: 24px` and enough padding. Keep the checkbox inside its label.

**13. Low. No landmarks and a generic page title.** Best practice under 2.4.1 and 2.4.2, not a strict failure on a one-section page.
- Evidence: no `<main>` or `<header>`. Title is "Sign up" with no site name.
- Fix: wrap the content in `<main>`, and use a title such as "Sign up | <Site name>".

**Checks that pass.** Body text #222 on white is about 15.9:1. Hint text #595959 on white is about 7.0:1 and the 0.9rem size is acceptable. Button text white on #0a58ca is about 6.4:1, which meets AA for normal text. The terms checkbox has a wrapping label and a correct accessible name. There is a single h1 that matches the page purpose, and the character set is declared.

## Remediated markup and verification steps

This version resolves findings 1 through 13 with the assumptions above. Replace the company name and language code as needed.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up | Company name</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    label { display: block; margin-top: 1rem; }
    .btn { display: inline-block; min-height: 24px; padding: 8px 16px;
           background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <header><img src="/img/logo-2024-final.png" alt="Company name"></header>
  <main>
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
        I accept the terms
      </label>
      <a href="/terms">Read the terms</a>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

The code above was not rendered or executed. Before sign-off, run the following in a browser:

1. Tab through the page with no mouse. Confirm the order is Email, Password, checkbox, link, button, and that each stop shows a visible outline.
2. Submit the form using only the keyboard, both by pressing Enter in a field and by activating the button.
3. Read the page with NVDA on Windows and VoiceOver on macOS or iOS. Confirm each field announces its label, the password field announces the hint, and the logo announces the company name.
4. Submit with fields empty and with a 5-character password. Confirm each error is announced and visually tied to its field.
5. Run axe DevTools or Lighthouse to catch anything a static read misses, and check the page at 400% zoom and 200% text size for clipping or horizontal scrolling.
6. Confirm that the server rejects a GET submission and that the password never appears in a URL or server log.
