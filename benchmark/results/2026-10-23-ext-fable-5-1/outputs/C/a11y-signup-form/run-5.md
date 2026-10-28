---
title: Fix the accessibility issues on the sign-up page
slug: fix-the-accessibility-issues-on-the-sign-up-page
article_type: troubleshooting
product_area: Sign-up
audience: Developer
plan_availability: None: internal audit, not plan-dependent
reading_time: 6 min
related_articles: None: no related articles yet
last_updated: 2026-10-25
---

# Fix the accessibility issues on the sign-up page

Keyboard and screen reader users cannot complete the sign-up page as written. Three issues block them outright, and 7 more make the form hard to use or fail WCAG 2.2 Level AA.

## Scope and assumptions

- The audit covers the source only. Nothing was rendered, so browser defaults are described, not measured.
- The page language is assumed to be English.
- The logo is assumed to show the company name and is not a link. The company name is unknown and appears below as `Company name`.
- The form posts to its own URL because no `action` is set. Server-side validation and error pages are out of scope.
- WCAG references use WCAG 2.2. Conformance level is given per issue.

## Summary of findings

| # | Severity | Issue | WCAG | Line |
| --- | --- | --- | --- | --- |
| 1 | Blocker | **Create account** is a `div`, so the keyboard cannot reach or press it | 2.1.1 (A), 4.1.2 (A) | `<div class="btn" ...>` |
| 2 | Blocker | Focus outline removed everywhere | 2.4.7 (AA) | `:focus { outline: none; }` |
| 3 | Blocker | **Email** and **Password** have no label, only placeholder text | 1.3.1 (A), 3.3.2 (A), 4.1.2 (A) | both `<input>` |
| 4 | High | Two elements share `id="email"` | 4.1.1 (A), blocks fix 3 | password `<input>` |
| 5 | High | **Read the terms** has `tabindex="3"`, so it is focused before the form | 2.4.3 (A) | `<a href="/terms" ...>` |
| 6 | High | Logo image has no `alt` | 1.1.1 (A) | `<img src=...>` |
| 7 | Medium | No `lang` on `<html>` | 3.1.1 (A) | `<html>` |
| 8 | Medium | Password hint not linked to the field | 3.3.2 (A) | `<p class="hint">` |
| 9 | Medium | No `autocomplete` on **Email** and **Password** | 1.3.5 (AA) | both `<input>` |
| 10 | Medium | `form.submit()` skips validation, so no error is ever shown | 3.3.1 (A) | `<script>` |

Colour contrast passes. Body text, the button and the hint all exceed the 4.5:1 minimum.

| Text | Colours | Ratio |
| --- | --- | --- |
| Body | `#222` on `#fff` | 15.9:1 |
| **Create account** | `#fff` on `#0a58ca` | 6.4:1 |
| Hint | `#595959` on `#fff` | 7.0:1 |

## The submit control is not a button

**Create account** is a `div` with an `onclick`. It is not in the tab order, has no button role, and does not respond to Enter or Space. Pressing Enter inside a field does not submit either, because the form has 2 text fields and no submit button. Keyboard and screen reader users have no way to send the form.

Fix: replace the `div` and the script with a native button.

```html
<button type="submit" class="btn">Create account</button>
```

Remove the `<script>` block and the `onclick`. A native button also lets the browser run its own validation before sending.

## Focus is invisible

`:focus { outline: none; }` removes the focus ring from every element on the page. Sighted keyboard users cannot see which field or control is active.

Fix: delete the rule. If a custom style is wanted, replace it with one that is visible.

```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

## The text fields have no labels

**Email** and **Password** use `placeholder` as their only name. Placeholder text disappears when the user types, is often rendered in low-contrast grey, and is not treated as a label by all assistive technology. A screen reader user hears "edit text" with no name.

Fix: add a visible label for each field and point it at the field with `for`.

```html
<label for="email">Email</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<label for="password">Password</label>
<input type="password" id="password" name="password"
       autocomplete="new-password" required aria-describedby="password-hint">
<p class="hint" id="password-hint">At least 8 characters.</p>
```

This single change also fixes findings 4, 8 and 9:

- The password field gets its own `id`, so the duplicate `id="email"` is gone. The duplicate is invalid HTML and would make `<label for="email">` point at the wrong field.
- `aria-describedby` reads the hint aloud when the password field receives focus.
- `autocomplete` lets browsers and password managers fill the fields, which WCAG 1.3.5 requires for fields that collect personal data.
- `name` attributes are added so the values are sent on submit. Without them the form posts nothing.

## The terms link is focused first

`tabindex="3"` puts **Read the terms** ahead of every element without a positive tabindex. The tab order becomes: link, **Email**, **Password**, checkbox. This does not match the visual order.

Fix: remove the `tabindex` attribute. The link then sits in document order, after the checkbox.

## The logo has no text alternative

Screen readers announce the file name, "logo-2024-final.png". If the logo carries the company name, that name is the alternative. If it is purely decorative, use an empty `alt`.

```html
<img src="/img/logo-2024-final.png" alt="Company name">
```

## The page language is not set

Without `lang`, screen readers guess the language and may use the wrong voice or pronunciation.

```html
<html lang="en">
```

## Validation never runs

`form.submit()` bypasses browser validation. A user can send an empty email or a 3-character password and never see an error. With the native button from the first fix, the browser blocks submission and names the invalid field. The `required` attributes above make the empty case an error too. A `minlength="8"` on the password field enforces the hint.

## Items to check in a browser

These could not be confirmed from the source alone.

- **Target size.** The button is about 26 px tall with the default font. WCAG 2.5.8 needs 24 px. It passes, but with little margin. Consider `padding: 8px 16px`.
- **Placeholder contrast.** Browser default placeholder colours vary and can fall below 4.5:1. Labels make the placeholders optional; remove them or keep them as examples only.
- **Landmarks.** Wrap the content in `<main>` so screen reader users can jump to it.
- **Viewport.** No `<meta name="viewport">` is set, so phones render the page at desktop width and the user must zoom.

## Corrected source

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
    label { display: block; margin-top: 12px; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Company name">
    <h1>Create your account</h1>
    <form id="signup" aria-labelledby="signup-heading">
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

Change `id="signup-heading"` to match the `h1` if the form name should be announced, or drop `aria-labelledby` if the heading alone is enough.

## Labels assumed

- **Email**, **Password**, **I accept the terms**, **Read the terms** and **Create account** are taken from the source as written.
- `Company name` in the logo `alt` is a placeholder. Replace it with the real name before publishing.
