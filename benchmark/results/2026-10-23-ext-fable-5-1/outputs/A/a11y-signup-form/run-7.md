# Accessibility audit: Sign-up page

**Verdict:** The page is not usable by keyboard-only or screen-reader users. The submit control is a plain div that cannot be reached or activated from the keyboard, and because the form has no real submit button and two text-type fields, pressing Enter does nothing either. Keyboard users cannot create an account at all. Six further defects fail WCAG 2.2 Level AA.

**Assumptions:** the audit target is WCAG 2.2 Level AA. The page is English. The logo conveys the organisation's identity rather than being purely decorative. Validation and error messages are handled server-side and are out of scope. Browser default styles apply wherever the page sets none. Severity follows the usual blocker, serious, moderate, minor scale.

| Severity | Count |
|---|---|
| Blocker | 2 |
| Serious | 4 |
| Moderate | 3 |
| Minor | 4 |

## Findings

**1. Submit control is a non-interactive div.** Blocker. WCAG 2.1.1 Keyboard, 4.1.2 Name, Role, Value. The "Create account" element is a styled div with an onclick handler. It is not in the tab order, has no button role, does not respond to Enter or Space, and screen readers announce it as plain text. Fix: replace it with a native submit button.

```html
<button type="submit" class="btn">Create account</button>
```

**2. The form cannot be submitted with Enter.** Blocker. WCAG 2.1.1 Keyboard. Because the form contains no submit button and has two fields that block implicit submission, the browser suppresses Enter-to-submit. Fixing finding 1 resolves this. A side effect worth noting: the inputs also have no name attributes, so even a mouse submission sends no data to the server.

**3. Visible focus is removed everywhere.** Serious. WCAG 2.4.7 Focus Visible. The global rule sets outline to none on every focused element with no replacement. Sighted keyboard users cannot tell where they are. Fix: delete the rule, or replace it with a visible indicator.

```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

**4. Email and password fields have no label.** Serious. WCAG 1.3.1 Info and Relationships, 3.3.2 Labels or Instructions, 2.4.6 Headings and Labels. Both inputs rely on placeholder text, which vanishes once the user types, is not reliably exposed as an accessible name, and usually renders below the 4.5:1 contrast minimum in default browser styling. Fix: add a visible label for each field, associated by the for attribute.

**5. Duplicate id on the password input.** Serious. WCAG 4.1.1 Parsing is obsolete in 2.2, but the defect still breaks 1.3.1 and 4.1.2 in practice. Both inputs use the id "email". Any label, aria-describedby, or script that targets the password field will resolve to the email field instead. Fix: give the password input the id "password".

**6. Positive tabindex on the terms link.** Serious. WCAG 2.4.3 Focus Order. The tabindex of 3 pulls "Read the terms" to the very start of the tab sequence, ahead of the email field. A keyboard user lands on the link before any form control, which does not match the visual order. Fix: remove the tabindex attribute. The link is naturally focusable.

**7. Logo image has no alt text.** Moderate. WCAG 1.1.1 Non-text Content. Screen readers will either skip the image or read the file name "logo-2024-final". Fix: add alt text naming the organisation. If the logo is purely decorative, use an empty alt instead.

```html
<img src="/img/logo-2024-final.png" alt="Acme">
```

**8. Password hint is not associated with its field.** Moderate. WCAG 3.3.2 Labels or Instructions. The "At least 8 characters" text is a free-standing paragraph. Screen-reader users who tab directly into the password field never hear it. Fix: give the paragraph an id and reference it from the input.

```html
<input type="password" id="password" name="password" aria-describedby="pw-hint">
<p class="hint" id="pw-hint">At least 8 characters.</p>
```

**9. Missing autocomplete on identity fields.** Moderate. WCAG 1.3.5 Identify Input Purpose. Without autocomplete values, password managers and assistive tools cannot recognise the field purpose. Fix: add the following attributes.

```html
<input type="email" autocomplete="email" ...>
<input type="password" autocomplete="new-password" ...>
```

**10. No language declared on the html element.** Minor. WCAG 3.1.1 Language of Page. Screen readers may use the wrong pronunciation rules. Fix: add a lang attribute to the html element.

**11. No viewport meta tag.** Minor. Not a WCAG failure by itself, but on mobile the page renders at desktop width and users must zoom to read. Related to 1.4.10 Reflow. Fix: add a standard viewport meta tag without restricting user scaling.

**12. No main landmark.** Minor. Best practice supporting 2.4.1 Bypass Blocks and 1.3.1. Wrap the heading and form in a main element so screen-reader users can jump to content.

**13. Required fields are not marked.** Minor. WCAG 3.3.2. Nothing tells users that email, password, and the terms checkbox are mandatory. Fix: add the required attribute and indicate the requirement in the visible label or a note above the form. Any server-side error messages that come back must identify the offending field in text, per 3.3.1 Error Identification.

**Passes worth keeping.** Body text at #222 on white, hint text at #595959 on white, and white text on the #0a58ca button all exceed the 4.5:1 contrast minimum. The checkbox is correctly wrapped in a label. The page has a descriptive title and a single h1. The button height of roughly 27px meets the 24px target size minimum in 2.5.8, although it falls short of the 44px AAA recommendation.

## Remediated markup

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
    label { display: block; margin-top: 1rem; }
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
             aria-describedby="pw-hint" minlength="8" required>
      <p class="hint" id="pw-hint">At least 8 characters.</p>

      <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>
      <a href="/terms">Read the terms</a>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

The inline script is no longer needed because a native submit button submits the form, including constraint validation, without JavaScript. Replace "Acme" with the actual organisation name.
