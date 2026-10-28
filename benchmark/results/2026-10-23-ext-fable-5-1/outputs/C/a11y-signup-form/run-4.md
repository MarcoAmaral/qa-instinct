---
title: Accessibility audit of the sign-up page
slug: accessibility-audit-of-the-sign-up-page
article_type: reference
product_area: Sign-up
audience: Developer
plan_availability: None: internal audit, not a product feature
reading_time: 5 min
related_articles: None: no related articles yet
last_updated: 2026-10-25
---

# Accessibility audit of the sign-up page

The page fails for keyboard and screen reader users and cannot be submitted without a mouse. Nine issues need fixing before launch, three of them blockers.

## Summary

| Severity | Count | What breaks |
| --- | --- | --- |
| Blocker | 3 | Keyboard users cannot submit the form, cannot see focus, and get no field names |
| Major | 4 | Wrong tab order, duplicate id, unlinked hint, missing language and purpose |
| Minor | 2 | Unnamed logo, no required fields or error messages |

Contrast passes everywhere. Body text on white is about 16:1, the hint is about 7:1, and white on the button is about 6.5:1. The checkbox has a proper label, the heading and page title are present, and the link text says where it goes.

## Findings, in order of impact

1. **The submit control is a div, not a button.** Blocker. WCAG 2.1.1, 4.1.2. The **Create account** div is not in the tab order, is not announced as a button, and does not react to Enter or Space. The form has no real submit button and 2 text fields, so pressing Enter in a field does nothing. Keyboard and screen reader users cannot create an account. The script also calls `submit()`, which skips browser validation. Replace the div:

   ```html
   <button type="submit" class="btn">Create account</button>
   ```

   Delete the script and the onclick handler.

2. **Focus is invisible on every element.** Blocker. WCAG 2.4.7. The rule `:focus { outline: none; }` removes the focus ring from every control and adds nothing in its place. Keyboard users cannot tell which field they are in. Remove the rule, or replace it with a visible style:

   ```css
   :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
   ```

3. **Email and password fields have no labels.** Blocker. WCAG 1.3.1, 3.3.2, 4.1.2. Both fields use only a placeholder. Placeholder text disappears as soon as the user types, is low contrast by default, and is not treated as the field name by every screen reader. Add a visible label to each field:

   ```html
   <label for="email">Email</label>
   <input type="email" id="email" name="email" autocomplete="email" required>

   <label for="password">Password</label>
   <input type="password" id="password" name="password"
          autocomplete="new-password" minlength="8" required
          aria-describedby="password-hint">
   ```

4. **Both text fields share the id "email".** Major. Duplicate ids are invalid HTML. Any label, script, or assistive technology that looks up the id finds the email field and ignores the password field. The fix in item 3 renames the password id.

5. **The terms link uses tabindex="3".** Major. WCAG 2.4.3. A positive tabindex moves the element ahead of everything else. Tab order becomes: **Read the terms**, then **Email**, **Password**, and the checkbox. The link opens before the user has seen the form. Remove the tabindex attribute. The link then sits in reading order, right after the checkbox.

6. **The password hint is not attached to the field.** Major. WCAG 3.3.2. A screen reader user who tabs into **Password** does not hear "At least 8 characters." Give the paragraph an id and reference it from the field, as shown in item 3:

   ```html
   <p class="hint" id="password-hint">At least 8 characters.</p>
   ```

7. **The page has no language.** Major. WCAG 3.1.1. Without a lang attribute, screen readers may read the page with the wrong voice and pronunciation rules. Add `lang="en"` to the html element. See the assumptions below.

8. **Fields do not declare their purpose.** Major. WCAG 1.3.5. Without autocomplete attributes, browsers and assistive tools cannot fill the fields or identify them. The fix in item 3 adds `autocomplete="email"` and `autocomplete="new-password"`.

9. **The logo has no alt text.** Minor. WCAG 1.1.1. Screen readers announce the file name, "logo-2024-final.png". If the logo only decorates the page, use `alt=""`. If it is the only place the company name appears, use the company name:

   ```html
   <img src="/img/logo-2024-final.png" alt="Company name">
   ```

10. **Nothing is required and nothing reports errors.** Minor. WCAG 3.3.1, 3.3.3. No field is marked required, the terms checkbox can be skipped, and the page shows no error messages. The fix in item 3 adds `required` and `minlength`, which gives the browser's built-in messages once the div becomes a real button. Add `required` to the checkbox as well. Custom error text should sit next to the field and be linked with aria-describedby.

## Notes outside WCAG scope

- **Target size.** The button is about 27 px tall, which just clears the 24 px minimum in WCAG 2.2. A 44 px height is the usual mobile target. Increase the padding to 10px 16px.
- **No viewport meta tag.** Phones render the page at desktop width and shrink it. Add `<meta name="viewport" content="width=device-width, initial-scale=1">`.
- **No main landmark.** The page is short, so this costs little today. Wrapping the heading and form in a main element helps once the page grows.

## Corrected page

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
    .btn { display: inline-block; padding: 10px 16px; margin-top: 1rem;
           background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Company name">
    <h1>Create your account</h1>
    <form id="signup" method="post" action="/signup">
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
  </main>
</body>
</html>
```

## Assumptions

- **Language is English.** The visible text is English, so the fix uses `lang="en"`. Change it if the page is served in other languages.
- **The logo is informative.** The company name is not shown anywhere else, so the alt text names the company. Replace "Company name" with the real name, or use empty alt text if the name appears elsewhere.
- **The form posts to /signup.** The original form has no action or method. The corrected page assumes a POST to the same path. Change it to match the server.
- **Contrast figures are calculated from the hex values.** They were not measured in a browser. Rendered fonts and anti-aliasing do not change the result.
- **Target size is estimated.** The 27 px button height assumes a 16 px default font with normal line height.

## Updates

- 2026-10-25: first audit.
