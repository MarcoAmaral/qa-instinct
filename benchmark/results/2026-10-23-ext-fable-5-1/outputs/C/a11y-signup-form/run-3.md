# Accessibility audit: Sign-up page

**Scope.** Static review of the HTML and CSS source against WCAG 2.2 Level AA. No browser, screen reader or automated checker was used, so rendered sizes, placeholder colours and runtime behaviour are inferred, not measured.

**Assumptions.**

- The page is in English. The language is not declared.
- The product name is "Acme" where a name is needed in examples.
- The page must work with a keyboard alone, with a screen reader and on a phone.
- The product's own labels are **Email**, **Password**, **I accept the terms**, **Read the terms** and **Create account**, as written in the source.

## Summary

The page cannot be completed by keyboard-only users or by most screen reader users. The main causes are the submit control, the missing labels and the removed focus outline. All issues are fixable in the markup; no design change is needed.

| Severity | Count | Meaning |
| --- | --- | --- |
| Critical | 4 | Some users cannot complete sign-up |
| High | 4 | Some users will struggle or get wrong information |
| Medium | 3 | Harder than it needs to be, or fails on some devices |
| Check | 2 | Cannot be confirmed from source alone |

## Critical

### 1. The **Create account** control is a `div`, not a button

The control is a `div` with an `onclick`. It is not in the tab order, it has no role, and it does not react to Enter or Space. A keyboard user cannot reach it. A screen reader announces it as plain text, not as a button. Pressing Enter in a field does not submit either, because the form has no submit button and more than one text field.

Affects: keyboard users, screen reader users, switch users.
WCAG: 2.1.1 Keyboard, 4.1.2 Name, Role, Value.

Fix: use a real button and drop the script.

```html
<button type="submit" class="btn">Create account</button>
```

### 2. All focus outlines are removed

`:focus { outline: none; }` applies to every element. A sighted keyboard user cannot see which field or link is active.

Affects: keyboard users, people with motor impairments, screen magnifier users.
WCAG: 2.4.7 Focus Visible, 2.4.11 Focus Not Obscured (Minimum).

Fix: delete the rule, or replace it with a visible style that only appears for keyboard focus.

```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

### 3. **Email** and **Password** have no labels

Both fields rely on `placeholder` only. Placeholder text disappears when the user types, is not a reliable accessible name, and is not read back when the user returns to check a value. A screen reader user hears "edit text" with no field name, or at best the placeholder, depending on the browser.

Affects: screen reader users, voice control users, people with memory or attention difficulties.
WCAG: 1.3.1 Info and Relationships, 3.3.2 Labels or Instructions, 4.1.2 Name, Role, Value.

Fix: add a visible label for each field, linked by `for` and `id`. Keep the placeholder only if it adds something the label does not.

```html
<label for="email">Email</label>
<input type="email" id="email" name="email">
```

### 4. Both fields share `id="email"`

The password field reuses the email field's `id`. The HTML is invalid, and any label or `aria-describedby` that points at `email` binds to the first field only. The password field stays unlabelled even after you add labels.

Affects: everyone who depends on the label fix above.
WCAG: 1.3.1 Info and Relationships; 4.1.2 Name, Role, Value.

Fix: give the password field its own `id`.

```html
<input type="password" id="password" name="password">
```

## High

### 5. **Read the terms** has `tabindex="3"`

A positive `tabindex` moves the link to the front of the tab order. The keyboard path becomes: **Read the terms**, then **Email**, then **Password**, then the checkbox. That does not match the visual order and confuses keyboard users.

Affects: keyboard users, screen reader users.
WCAG: 2.4.3 Focus Order.

Fix: remove the `tabindex` attribute. Links are focusable by default.

### 6. The logo has no `alt` text

With no `alt`, a screen reader reads the file name: "logo-2024-final.png". The reader learns nothing and hears the word "final", which sounds like a status.

Affects: screen reader users.
WCAG: 1.1.1 Non-text Content.

Fix: name what the image shows, or mark it decorative if the product name also appears as text.

```html
<img src="/img/logo-2024-final.png" alt="Acme">
```

### 7. The password hint is not linked to the field

"At least 8 characters." sits in a paragraph after the field. A screen reader user who tabs straight into the field never hears it. They learn the rule only after a failed submit, if at all.

Affects: screen reader users.
WCAG: 3.3.2 Labels or Instructions.

Fix: give the hint an `id` and point the field at it.

```html
<input type="password" id="password" name="password" aria-describedby="password-hint">
<p class="hint" id="password-hint">At least 8 characters.</p>
```

### 8. The page language is not declared

The `html` element has no `lang` attribute. Screen readers may use the wrong voice or pronunciation rules, and translation tools cannot detect the source language reliably.

Affects: screen reader users, users of browser translation.
WCAG: 3.1.1 Language of Page.

Fix:

```html
<html lang="en">
```

## Medium

### 9. No required fields, no validation and no error messages

Nothing is marked `required`, so an empty form can be sent. The `submitForm()` function calls `form.submit()`, which skips the browser's built-in checks, so even the `type="email"` check never runs. There is no markup for error messages, so if the server rejects the form, the page gives no accessible way to say what went wrong or where.

Affects: everyone, most of all screen reader users and people with cognitive disabilities.
WCAG: 3.3.1 Error Identification, 3.3.3 Error Suggestion.

Fix: mark the three fields `required`, add `minlength="8"` to the password, and use a submit button so the browser validates. If you show your own errors, put the message text next to the field and link it with `aria-describedby`, and set `aria-invalid="true"` on the field.

### 10. No `autocomplete` on the fields

Browsers and password managers cannot fill the fields reliably. This matters most for people who find typing hard or who cannot remember a new password.

Affects: people with motor or cognitive impairments, everyone on a phone.
WCAG: 1.3.5 Identify Input Purpose.

Fix:

```html
<input type="email" id="email" name="email" autocomplete="email">
<input type="password" id="password" name="password" autocomplete="new-password">
```

### 11. No viewport meta tag

Without it, phones render the page at desktop width and zoom out. Text becomes very small and the user must pinch to zoom before every tap.

Affects: all mobile users, most of all people with low vision.
WCAG: 1.4.4 Resize Text, 1.4.10 Reflow.

Fix:

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

## Check in a browser

These cannot be confirmed from source.

- **Placeholder contrast.** Browsers choose the placeholder colour. Some defaults fall below the 4.5:1 ratio. This stops mattering once the placeholders are replaced by labels.
- **Button size.** Padding of 4 px by 8 px around 16 px text gives a target about 27 px tall. That meets the 24 px minimum in 2.5.8 Target Size, but only just. Padding of 8 px by 16 px gives comfortable room.

## What passes

- Body text at `#222` on white has a contrast ratio of about 15.9:1.
- The hint at `#595959` on white has a ratio of about 7:1, which passes for its 14.4 px size.
- The button at `#0a58ca` with white text has a ratio of about 6.4:1.
- The checkbox is wrapped in a `label`, so **I accept the terms** is its accessible name and the text is clickable.
- The page has a `title` and a single `h1`.
- The fields use the right input types, so phones show the right keyboard.

## Outside accessibility, but worth a line

The form has no `method` or `action`. It submits with GET to the current URL, which puts the password in the address bar, browser history and server logs. Add `method="post"` and an `action`.

## Corrected page

This version fixes every item above. The product name, the form `action` and the English `lang` value are assumptions.

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

## Suggested order of work

1. Replace the `div` with a submit button and remove the script.
2. Remove the `:focus` rule.
3. Add labels and fix the duplicate `id`.
4. Remove `tabindex`, add `alt`, link the hint, add `lang`.
5. Add `required`, `autocomplete` and the viewport tag.
6. Test with a keyboard only, then with one screen reader, before release.
