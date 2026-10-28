---
title: Sign-up page accessibility audit
slug: sign-up-page-accessibility-audit
article_type: troubleshooting
product_area: Sign up
audience: Developer
plan_availability: None: internal audit, not tied to a plan
reading_time: 5 min
related_articles: None: no related articles yet
last_updated: 2026-10-25
---

# Sign-up page accessibility audit

The sign-up page cannot be completed with a keyboard or a screen reader. Five blocking problems and six smaller ones are listed below, most serious first, each with one fix.

## Before you start

- This audit reads the source only. The page was not opened in a browser or tested with assistive technology.
- Assumption: the page has no external CSS or JavaScript beyond what is shown.
- Assumption: the page is in English and the company is called "Example". Replace both where they appear in the fixes.

## Keyboard users cannot press Create account

The **Create account** control is a `div` with an `onclick` handler. It is not in the tab order, is not announced as a button, and does not respond to **Enter** or **Space**. Because the form has no real submit button, pressing **Enter** in a field does not submit either.

Fix: replace the `div` with a submit button and drop the script.

```html
<button type="submit" class="btn">Create account</button>
```

## Email and Password fields have no label

Both fields rely on `placeholder`. Placeholder text disappears when the user types, is not treated as a label by all screen readers, and is often too faint to read. Fails WCAG 1.3.1 and 3.3.2.

Fix: add a visible label linked to each field.

```html
<label for="email">Email</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<label for="password">Password</label>
<input type="password" id="password" name="password" autocomplete="new-password" required aria-describedby="password-hint">
```

This fix also adds `autocomplete` (WCAG 1.3.5), `name` so values are actually sent, and `required`.

## Both inputs share id="email"

The password field reuses the email field's `id`. Duplicate ids are invalid HTML. Any `label for="email"` or script lookup binds to the first field only, so the password field can never be labelled. Fails WCAG 4.1.1.

Fix: included above. The password field uses `id="password"`.

## Focus is invisible on every element

The rule `:focus { outline: none; }` removes the focus ring from every link, field and button. Keyboard users cannot see where they are. Fails WCAG 2.4.7.

Fix: delete the rule. If a custom ring is wanted, use `:focus-visible` instead.

```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

## Read the terms is focused before the form fields

`tabindex="3"` on the **Read the terms** link puts it first in the tab order, ahead of every field. Positive tabindex values also break the order for any element added later. Fails WCAG 2.4.3.

Fix: remove the `tabindex` attribute.

## The logo has no alt text

Screen readers announce the filename, "logo-2024-final.png". Fails WCAG 1.1.1.

Fix: name the company, or mark the image decorative if the heading already carries the meaning.

```html
<img src="/img/logo-2024-final.png" alt="Example">
```

## The password hint is not linked to the field

"At least 8 characters." is a loose paragraph. A screen-reader user who tabs into **Password** does not hear it.

Fix: give the paragraph an `id` and reference it from the field. The `aria-describedby` is already in the fix above.

```html
<p class="hint" id="password-hint">At least 8 characters.</p>
```

## The page has no language

The `html` element has no `lang`. Screen readers may read English text with the wrong voice. Fails WCAG 3.1.1.

Fix:

```html
<html lang="en">
```

## The page cannot be zoomed well on mobile

There is no viewport meta tag, so mobile browsers render a desktop-width page and text starts very small. Users who rely on zoom are affected first.

Fix:

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

## The button is smaller than the minimum target size

Padding of 4px by 8px gives a target about 24px tall at best, at the edge of WCAG 2.5.8. Mobile and motor-impaired users will mis-tap it.

Fix: raise the padding to at least 10px 16px.

## There is no error handling

Nothing tells the user which field is empty or invalid. Once `required` is added, browsers show native messages, which is the minimum. Any custom validation added later needs an error message linked to the field with `aria-describedby`. WCAG 3.3.1 and 3.3.3.

## What passes

- Body text, hint text and button text all meet WCAG AA contrast. Hint text at #595959 on white is about 7:1. Button text is about 6.4:1.
- The **I accept the terms** checkbox is correctly wrapped in a label.
- The link text **Read the terms** describes its destination.
- The page has one `h1` that matches the task.

## What to check in a browser

- Tab through the page after the fixes. The order should be **Email**, **Password**, **I accept the terms**, **Read the terms**, **Create account**.
- Submit the form with a screen reader and confirm each field name, the hint, and any error are announced.

## Related articles

None: no related articles yet.

## Updates

- 2026-10-25: first audit, from source only.
