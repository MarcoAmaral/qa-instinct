---
title: Sign-up page accessibility audit
slug: sign-up-page-accessibility-audit
article_type: reference
product_area: Sign-up
audience: Developer
plan_availability: None: the sign-up page is the same for every plan
reading_time: 6 min
related_articles: None: no related articles yet
last_updated: 2026-10-25
---

# Sign-up page accessibility audit

The sign-up page cannot be completed with a keyboard or a screen reader today, and 11 fixes bring it to WCAG 2.2 level AA.

## Scope and assumptions

- The audit covers the HTML and CSS shown. No other stylesheet, script or server code was reviewed.
- The standard is WCAG 2.2, level AA. The level column below shows the level each criterion belongs to.
- Nothing was tested in a browser or with assistive technology. Each finding is read from the source, so a few results (focus order, implicit submission) describe standard browser behaviour and should be confirmed by a manual test.
- The page language is assumed to be English.
- The logo is assumed to show the company name and not to be a link.
- The interface labels **Email**, **Password**, **I accept the terms**, **Read the terms** and **Create account** are taken from the source. An editor should confirm them against the live page.
- Error handling is assumed to happen on the server after submission, because the source has none.

## Summary of findings

| # | Finding | WCAG 2.2 criterion | Level | Severity |
| --- | --- | --- | --- | --- |
| 1 | Submit control is a `div`, not a button | 2.1.1 Keyboard, 4.1.2 Name, Role, Value | A | Blocker |
| 2 | Email and password fields have no label | 1.3.1 Info and Relationships, 3.3.2 Labels or Instructions, 4.1.2 | A | Critical |
| 3 | Two elements share the id `email` | 1.3.1, 4.1.2 | A | Critical |
| 4 | Focus outline removed on every element | 2.4.7 Focus Visible | AA | Critical |
| 5 | Positive `tabindex` on the terms link | 2.4.3 Focus Order | A | Serious |
| 6 | Logo image has no `alt` attribute | 1.1.1 Non-text Content | A | Serious |
| 7 | No `lang` attribute on `html` | 3.1.1 Language of Page | A | Serious |
| 8 | Password hint is not linked to the field | 1.3.1, 3.3.2 | A | Moderate |
| 9 | No `autocomplete` on email and password | 1.3.5 Identify Input Purpose | AA | Moderate |
| 10 | No viewport meta tag | 1.4.4 Resize Text, 1.4.10 Reflow | AA | Minor |
| 11 | No `main` landmark and no form name | Best practice | None | Minor |

## Findings

### 1. The submit control is a `div`

**What the reader experiences.** A keyboard user cannot reach **Create account** with the Tab key, and Enter does nothing on it. Pressing Enter inside a field does not submit either. Browsers skip implicit submission when a form has more than 1 text field and no submit button. A screen reader announces the element as plain text, not as a button. Without JavaScript the form cannot be sent at all.

**Why it fails.** A `div` has no role, is not focusable and has no keyboard behaviour. The `onclick` handler only runs for pointer users.

**Fix.** Replace the `div` with a native submit button and delete the script.

```html
<button type="submit" class="btn">Create account</button>
```

### 2. The email and password fields have no label

**What the reader experiences.** A screen reader may announce the fields as "edit text" with no name. Once a sighted user starts typing, the placeholder disappears and nothing says which field is which. Clicking the word does not focus the field.

**Why it fails.** A placeholder is a hint, not a label. It is not reliably exposed as the accessible name and is not required to meet contrast minimums.

**Fix.** Add a visible `label` for each field and keep the placeholder only if it adds an example.

```html
<label for="email">Email</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<label for="password">Password</label>
<input type="password" id="password" name="password" autocomplete="new-password" required aria-describedby="password-hint">
```

### 3. Two elements share the id `email`

**What the reader experiences.** Any label, hint or script that targets `email` reaches the first field only. The password field becomes unreachable by id.

**Why it fails.** Ids must be unique. Duplicate ids break label association and `getElementById`.

**Fix.** Rename the password field id to `password`, as shown in finding 2.

### 4. The focus outline is removed on every element

**What the reader experiences.** A keyboard user tabbing through the page sees no sign of where they are.

**Why it fails.** The rule `:focus { outline: none; }` hides the browser's focus indicator without replacing it.

**Fix.** Delete the rule, or replace it with a visible style.

```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

### 5. The terms link has `tabindex="3"`

**What the reader experiences.** The first Tab press lands on **Read the terms**, before the email field. The reading order and the tab order no longer match.

**Why it fails.** A positive `tabindex` moves the element ahead of everything with a `tabindex` of 0 or none.

**Fix.** Remove the attribute. The link then takes its natural position after the checkbox.

### 6. The logo image has no `alt` attribute

**What the reader experiences.** A screen reader reads the file name, "logo-2024-final.png".

**Fix.** Name the company in the `alt` text. If the logo is purely decorative, use an empty `alt=""` instead.

```html
<img src="/img/logo-2024-final.png" alt="Company name">
```

Replace "Company name" with the real name shown in the logo.

### 7. The `html` element has no `lang` attribute

**What the reader experiences.** A screen reader may use the wrong voice and pronunciation.

**Fix.**

```html
<html lang="en">
```

### 8. The password hint is not linked to the field

**What the reader experiences.** A screen reader user who tabs into **Password** does not hear "At least 8 characters." The hint is read only if they browse past the field.

**Fix.** Give the hint an id and point to it with `aria-describedby`, as shown in finding 2.

```html
<p class="hint" id="password-hint">At least 8 characters.</p>
```

### 9. The fields have no `autocomplete` attribute

**What the reader experiences.** Password managers and browsers cannot fill the fields reliably. Users with memory or motor impairments depend on this.

**Fix.** Add `autocomplete="email"` and `autocomplete="new-password"`, as shown in finding 2.

### 10. There is no viewport meta tag

**What the reader experiences.** On a phone, the page may render at desktop width and need horizontal scrolling. Some browsers also lock zoom.

**Fix.**

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

Do not add `user-scalable=no` or a `maximum-scale` value.

### 11. No `main` landmark and no form name

**What the reader experiences.** A screen reader user cannot jump straight to the content or hear what the form is for.

**Fix.** Wrap the content in `main` and name the form from the heading.

```html
<main>
  <h1 id="signup-heading">Create your account</h1>
  <form id="signup" aria-labelledby="signup-heading">
```

## What passes

- The checkbox is wrapped in a `label`, so **I accept the terms** is its accessible name.
- The page has a single `h1` and a `title`.
- Colour contrast meets level AA for all text that has a defined colour.

| Text | Colours | Ratio | Result |
| --- | --- | --- | --- |
| Body text | #222 on #fff | 15.9:1 | Pass AA and AAA |
| Hint text | #595959 on #fff | 7.0:1 | Pass AA and AAA |
| Button text | #fff on #0a58ca | 6.5:1 | Pass AA |

The button padding of 4px by 8px makes a small target. Once it is a real button, give it at least 24px of height to meet 2.5.8 Target Size (Minimum), and consider 44px for touch.

## Not covered by this audit

- **Error messages.** The source has no error handling. When you add it, show each error next to its field, link it with `aria-describedby`, and move focus to the first error. This covers 3.3.1 Error Identification and 3.3.3 Error Suggestion.
- **Show password.** Not required by WCAG, but a **Show password** toggle helps users with low vision and motor impairments.
- **Behaviour on the live page.** Focus order, implicit submission and screen-reader announcements should be confirmed with a keyboard and at least 1 screen reader after the fixes are applied.

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
    .btn { display: inline-block; min-height: 44px; padding: 8px 16px; background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
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

The `method` and `action` values are placeholders. Set them to match the server.

## Related articles

None: no related articles yet. When they exist, link this audit from the developer guide for the sign-up page.

## Updates

None: first version.
