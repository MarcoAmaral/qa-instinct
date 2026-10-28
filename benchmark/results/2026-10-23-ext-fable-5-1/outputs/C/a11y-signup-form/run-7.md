# Accessibility audit: Sign-up page

The page fails 8 WCAG 2.2 Level A and AA success criteria. Keyboard users cannot submit the form, and screen reader users cannot tell which field is which. All issues are fixable in the markup and CSS alone.

## Assumptions

- The audit is against WCAG 2.2 Level AA, read from source only. Nothing was tested in a browser or with assistive technology.
- The page language is English.
- The logo is informative, not decorative, and the company name is not known. Replace **Company** below with the real name.
- The browser's default font size (16 px) and line height apply, since the CSS sets neither.

## Findings

Ordered by severity. Each finding gives the location, the problem, the criterion, and the fix.

### 1. The submit control is a `div`, not a button (critical)

**Location:** `<div class="btn" onclick="submitForm()">Create account</div>`

Keyboard users cannot reach or activate the control. A `div` is not in the tab order, has no button role, and does not respond to Enter or Space. Pressing Enter inside a field does not submit either: the form has no submit button and more than one text field, so browsers suppress implicit submission. The page is unusable without a mouse.

Calling `form.submit()` in script also bypasses the browser's built-in validation, so `type="email"` checking never runs.

**Criteria:** 2.1.1 Keyboard (A), 4.1.2 Name, Role, Value (A).

**Fix:** Replace the `div` and the script with `<button type="submit">Create account</button>`. Keep the `.btn` styles on the button.

### 2. Focus indicator removed for every element (critical)

**Location:** `:focus { outline: none; }`

Sighted keyboard users cannot see which field, link or checkbox has focus anywhere on the page.

**Criteria:** 2.4.7 Focus Visible (AA), 2.4.11 Focus Not Obscured (AA).

**Fix:** Delete the rule. If a custom style is wanted, replace it with a visible one, for example `:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }`.

### 3. Email and password fields have no labels (critical)

**Location:** both `<input>` elements in the form.

Placeholder text is the only name. It disappears as soon as the user types, so the field's purpose is lost mid-task. Placeholder contrast is also controlled by the browser and usually fails 4.5:1. Some screen readers do not announce placeholders as the field name.

**Criteria:** 1.3.1 Info and Relationships (A), 3.3.2 Labels or Instructions (A), 4.1.2 Name, Role, Value (A).

**Fix:** Add a visible `<label for="...">` before each input. Keep the placeholder only if it adds an example, such as `name@example.com`.

### 4. Duplicate `id="email"` on two fields (serious)

**Location:** the password input reuses `id="email"`.

Duplicate IDs make label association unreliable and are invalid HTML. Any label, script or `aria-describedby` that points to `email` will reach the first field only. This must be fixed before finding 3 can work.

**Criterion:** 1.3.1 Info and Relationships (A). Also a parsing error under 4.1.1 in WCAG 2.1.

**Fix:** Change the password field to `id="password"`.

### 5. Password hint is not connected to the field (serious)

**Location:** `<p class="hint">At least 8 characters.</p>`

The hint is visually under the password field, but nothing links them. Screen reader users hear the field with no rule, and only find the hint if they read past it.

**Criterion:** 3.3.2 Labels or Instructions (A), 1.3.1 Info and Relationships (A).

**Fix:** Give the paragraph `id="password-hint"` and add `aria-describedby="password-hint"` to the password input.

### 6. Positive `tabindex` breaks the tab order (serious)

**Location:** `<a href="/terms" tabindex="3">`

The only positive `tabindex` on the page sends this link to the front of the tab order. Keyboard users land on **Read the terms** before **Email**, then jump back up the page. Focus order no longer matches reading order.

**Criterion:** 2.4.3 Focus Order (A).

**Fix:** Remove the `tabindex` attribute. The link is already focusable in document order.

### 7. Logo image has no text alternative (serious)

**Location:** `<img src="/img/logo-2024-final.png">`

Screen readers announce the filename, "logo-2024-final.png", as the first thing on the page.

**Criterion:** 1.1.1 Non-text Content (A).

**Fix:** Add `alt="Company logo"`. If the logo is purely decorative, use `alt=""` instead.

### 8. Page language is not declared (moderate)

**Location:** `<html>`

Without `lang`, screen readers may use the wrong pronunciation rules, and translation tools cannot detect the source language.

**Criterion:** 3.1.1 Language of Page (A).

**Fix:** Change to `<html lang="en">`.

### 9. Input purpose is not identified (moderate)

**Location:** email and password inputs.

Browsers and assistive tools cannot offer autofill or icons for the fields, which helps people with cognitive and motor disabilities.

**Criterion:** 1.3.5 Identify Input Purpose (AA).

**Fix:** Add `autocomplete="email"` and `autocomplete="new-password"`.

## Advisory issues

These do not fail a criterion on the source alone but will cause problems in practice.

- **No `required` attributes and no error handling.** Once the control is a real button, mark **Email**, **Password** and **I accept the terms** as required so the browser reports empty fields. Any custom validation must show text errors next to the field, per 3.3.1 Error Identification.
- **Small button.** With default font size the control is about 27 px tall and just meets the 24 px minimum in 2.5.8 Target Size. Increase padding to `8px 16px` for touch users.
- **No viewport meta tag.** On phones the page renders zoomed out, which works against 1.4.4 Resize Text and 1.4.10 Reflow. Add `<meta name="viewport" content="width=device-width, initial-scale=1">`.
- **Title and heading differ.** The `<title>` says "Sign up" and the `<h1>` says "Create your account". Use one phrase for both so search results, browser tabs and the page agree.
- **No landmark.** Wrap the content in `<main>` so screen reader users can jump straight to it.

## What passes

- **Colour contrast.** Body text, hint text and button text all pass 4.5:1 on their backgrounds. Measured from the CSS:

  | Text | Background | Ratio | Result |
  | --- | --- | --- | --- |
  | `#222` body | `#fff` | 15.9:1 | Pass AAA |
  | `#595959` hint | `#fff` | 7.0:1 | Pass AAA |
  | `#fff` button | `#0a58ca` | 6.4:1 | Pass AA |

- **Terms checkbox.** The input is wrapped in a `<label>`, so it has a proper accessible name.
- **Heading structure.** One `<h1>` describes the page.
- **Relative font size.** The hint uses `rem`, so it scales with the user's text settings.
- **Link text.** **Read the terms** describes its destination.

## Corrected source

This version resolves every finding above and the advisory items.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Create your account</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    .btn { display: inline-block; padding: 8px 16px; background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Company logo">
    <h1>Create your account</h1>
    <form id="signup">
      <label for="email">Email</label>
      <input type="email" id="email" name="email" autocomplete="email" required>

      <label for="password">Password</label>
      <input type="password" id="password" name="password" autocomplete="new-password"
             minlength="8" aria-describedby="password-hint" required>
      <p class="hint" id="password-hint">At least 8 characters.</p>

      <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>
      <a href="/terms">Read the terms</a>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

## Retest before release

Source review cannot confirm behaviour. Before publishing, check these in a browser:

1. Tab through the page with the keyboard. Focus must move Email, Password, checkbox, link, button, and be visible at each stop.
2. Submit with Enter from the password field.
3. Read the form with a screen reader such as NVDA or VoiceOver. Each field must announce its label, and the password field must also announce the hint.
4. Leave every field empty and submit. Each error must appear as text next to its field.
