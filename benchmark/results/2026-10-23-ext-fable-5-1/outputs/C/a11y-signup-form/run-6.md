---
title: Sign-up page accessibility audit
slug: sign-up-page-accessibility-audit
article_type: troubleshooting
product_area: Sign up
audience: Developer
plan_availability: None: the sign-up page is the same for every plan
reading_time: 6 min
related_articles: None: no related articles exist yet for this page
last_updated: 2026-10-25
---

# Sign-up page accessibility audit

The sign-up page cannot be completed with a keyboard or a screen reader as written, and 11 issues need fixing before it meets WCAG 2.2 Level AA.

## How this audit was done

This audit reads the page source only. Nothing was rendered in a browser, tested with a screen reader, or measured on screen. Findings about layout, target size and mobile behaviour are marked as unverified.

Assumptions made where the source gives no answer:

- The page is in English. The `lang` fix below uses `en`; change it if not.
- The logo is the company logo and is not a link. The alt text fix uses the placeholder "Company name".
- The server validates the form. The source shows no client-side validation, so this could not be checked.
- No other stylesheet or script loads. Only the inline `<style>` and `<script>` were reviewed.
- The target standard is WCAG 2.2 Level AA.

## Findings at a glance

| # | Severity | Issue | WCAG |
| --- | --- | --- | --- |
| 1 | Blocker | **Create account** is a `div`, not a button | 2.1.1, 4.1.2 |
| 2 | Blocker | Focus outline removed on every element | 2.4.7 |
| 3 | Blocker | **Email** and **Password** fields have no label | 1.3.1, 3.3.2, 4.1.2 |
| 4 | High | Two elements share `id="email"` | 4.1.1, 1.3.1 |
| 5 | High | **Read the terms** has `tabindex="3"` | 2.4.3 |
| 6 | High | Logo image has no `alt` | 1.1.1 |
| 7 | High | No `lang` on `<html>` | 3.1.1 |
| 8 | Medium | Password hint is not linked to the field | 1.3.1, 3.3.2 |
| 9 | Medium | No `autocomplete` on email or password | 1.3.5 |
| 10 | Medium | No required fields and no error messages | 3.3.1, 3.3.3 |
| 11 | Low | Button target size and mobile zoom are unverified | 2.5.8, 1.4.4 |

Severity reflects who is locked out. Blocker means a whole group of users cannot finish signing up.

## 1. The submit control is a `div`, not a button

**What fails.** `<div class="btn" onclick="submitForm()">` is not focusable, so keyboard users can never reach it. Screen readers announce it as plain text, not as a button. Enter and Space do nothing on it. Pressing Enter inside a field does not submit either, because a form with 2 text fields and no submit button has no implicit submission. Calling `form.submit()` also skips browser validation and the `submit` event.

**Fix.** Replace the `div` with a real button and remove the script.

```html
<button type="submit" class="btn">Create account</button>
```

Keep `.btn` styling; it applies to a `button` the same way. Add `border: 0; cursor: pointer;` if the default button border shows.

## 2. The focus outline is removed on every element

**What fails.** `:focus { outline: none; }` hides the focus ring for every link, field and button on the page. A sighted keyboard user cannot see where they are. This fails 2.4.7 Focus Visible and makes finding 5 worse.

**Fix.** Delete the rule. If a custom ring is wanted, style it instead of hiding it.

```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

## 3. The email and password fields have no label

**What fails.** Both inputs rely on `placeholder` alone. Placeholder text disappears once the user types, so they cannot check which field holds what. Screen readers do not treat placeholder as a reliable name, and some do not announce it at all. Browser default placeholder colour usually fails contrast as well.

**Fix.** Add a visible label for each field.

```html
<label for="email">Email</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<label for="password">Password</label>
<input type="password" id="password" name="password"
       autocomplete="new-password" required aria-describedby="password-hint">
```

Placeholders may stay as examples, for example `placeholder="name@example.com"`, but not as the only label.

## 4. Two elements share `id="email"`

**What fails.** The password input also has `id="email"`. Duplicate ids break label association, `aria-describedby`, browser autofill and any script that looks up the field. A label for **Email** would attach to whichever element the browser finds first.

**Fix.** Change the password input to `id="password"`, as shown in finding 3.

## 5. The terms link has a positive `tabindex`

**What fails.** `tabindex="3"` moves **Read the terms** to the front of the tab order. A keyboard user's first Tab lands on the link, then jumps back to **Email**. Combined with finding 2 they cannot see this happen.

**Fix.** Remove the attribute. The natural document order is correct.

```html
<a href="/terms">Read the terms</a>
```

## 6. The logo has no alt text

**What fails.** `<img src="/img/logo-2024-final.png">` has no `alt`. Screen readers announce the file name, "logo-2024-final.png", as the first thing on the page.

**Fix.** Give it a short name, or mark it decorative if the heading already names the product.

```html
<img src="/img/logo-2024-final.png" alt="Company name">
```

Use `alt=""` instead if the logo is purely decorative. If the logo becomes a link, the alt text should say where it goes, for example "Company name home".

## 7. The page has no language

**What fails.** `<html>` has no `lang` attribute. Screen readers fall back to their default voice and may mispronounce every word. Translation tools and spell checkers also guess.

**Fix.**

```html
<html lang="en">
```

## 8. The password hint is not linked to the field

**What fails.** "At least 8 characters." sits in a paragraph after the field. Sighted users see it, but a screen reader user focused on **Password** hears nothing about the rule until they move on.

**Fix.** Give the hint an id and reference it from the input, as shown in finding 3.

```html
<p class="hint" id="password-hint">At least 8 characters.</p>
```

## 9. The fields have no `autocomplete`

**What fails.** Without `autocomplete`, browsers and password managers cannot reliably identify the fields. Users with cognitive or motor disabilities depend on autofill. This fails 1.3.5 Identify Input Purpose.

**Fix.** Add `autocomplete="email"` and `autocomplete="new-password"`, as shown in finding 3.

## 10. No required fields and no error messages

**What fails.** None of the three inputs is marked `required`, and the source has no error text or `aria-live` region. The form can submit empty. If the server rejects it, the source gives no evidence of how the error returns to the user. This is unverified; it depends on server behaviour not shown here.

**Fix.** Mark the three fields `required`. After a failed submit, show an error message next to each invalid field, link it with `aria-describedby`, and set `aria-invalid="true"`. Move focus to the first error or to a summary at the top of the form.

## 11. Target size and mobile zoom are unverified

**What might fail.** `.btn` uses `padding: 4px 8px`. With a default font size the button is about 26 px tall, which only just meets the 24 px minimum in 2.5.8. The page has no `<meta name="viewport">`, so mobile browsers render it at desktop width and users must zoom to read. Neither can be confirmed without rendering.

**Fix.** Raise padding to at least `10px 16px`, and add a viewport tag that allows zoom.

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

## Checks that passed

- Body text `#222` on white has a contrast ratio above 15:1.
- Hint text `#595959` on white is about 7.0:1, which passes AA even at 0.9 rem.
- Button text white on `#0a58ca` is about 6.4:1, which passes AA.
- The page has a single `h1` that matches the task.
- The `<title>` is short and describes the page.
- **I accept the terms** wraps its checkbox in a `label`, so it is named correctly.
- Hint text uses `rem`, so it scales with browser text settings.

## Corrected page

This version applies every fix above. Replace "Company name" and `lang="en"` with the real values.

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
           color: #fff; border: 0; font: inherit; cursor: pointer; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <img src="/img/logo-2024-final.png" alt="Company name">
  <h1>Create your account</h1>
  <form id="signup" method="post" action="/signup">
    <label for="email">Email</label>
    <input type="email" id="email" name="email" autocomplete="email" required>

    <label for="password">Password</label>
    <input type="password" id="password" name="password" minlength="8"
           autocomplete="new-password" required aria-describedby="password-hint">
    <p class="hint" id="password-hint">At least 8 characters.</p>

    <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>
    <a href="/terms">Read the terms</a>

    <button type="submit" class="btn">Create account</button>
  </form>
</body>
</html>
```

The `method` and `action` values are assumed; the original form had neither.

## What to test next in a browser

1. Tab through the page from the address bar. Order should be logo link if any, **Email**, **Password**, **I accept the terms**, **Read the terms**, **Create account**, with a visible ring on each.
2. Press Enter inside **Password**. The form should submit or show errors.
3. Submit the empty form. Each field should show an error that a screen reader announces.
4. Check the page with a screen reader. Each field should announce its label, and **Password** should also read the hint.
5. Open the page on a phone. Text should be readable without zooming, and zoom should not be blocked.

## Updates

- 2026-10-25: first audit, from source only.
