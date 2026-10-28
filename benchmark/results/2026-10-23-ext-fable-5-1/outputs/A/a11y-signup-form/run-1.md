# Accessibility audit: Sign-up page

**Scope and assumptions.** Static review of the supplied HTML only, against WCAG 2.2 Level AA. I assume: the page content is English; the logo is the brand mark and conveys the company name (not purely decorative); no other CSS or JavaScript is loaded; and server-side validation behaviour is unknown, so I treat the page as having no error handling.

**Verdict.** The page does not meet WCAG 2.2 AA. A keyboard-only user cannot submit the form at all, and a screen reader user cannot tell the email and password fields apart. Both are blockers.

## Summary

| # | Issue | WCAG | Severity |
|---|-------|------|----------|
| 1 | Submit control is a `div` with `onclick`; not focusable, no role, no keyboard activation | 2.1.1, 4.1.2 | Critical |
| 2 | Email and password inputs have no label; placeholder is the only cue | 1.3.1, 3.3.2, 4.1.2 | Critical |
| 3 | Duplicate `id="email"` on two inputs | 4.1.1 / 1.3.1 | Critical |
| 4 | Global `:focus { outline: none }` removes all focus indication | 2.4.7 | Critical |
| 5 | Positive `tabindex="3"` on the terms link breaks focus order | 2.4.3 | Serious |
| 6 | Logo image has no `alt` | 1.1.1 | Serious |
| 7 | No `lang` on `<html>` | 3.1.1 | Serious |
| 8 | Password hint not programmatically tied to the field | 3.3.2, 1.3.1 | Moderate |
| 9 | No `autocomplete` on email/password | 1.3.5 | Moderate |
| 10 | No `required`, no error identification; `.submit()` bypasses browser validation | 3.3.1, 3.3.3 | Moderate |
| 11 | No `<main>` landmark; no viewport meta | 1.3.1 (best practice), 1.4.10 | Minor |
| 12 | Button hit area around 27 px tall; meets the 24 px AA minimum only marginally | 2.5.8 | Minor |

Colour contrast passes. Button text white on `#0a58ca` is about 6.4:1, hint `#595959` on white is about 7.0:1, and body `#222` on white is about 15.9:1.

## Findings

### 1. Submit control is not a button (Critical)

`<div class="btn" onclick="submitForm()">` is not in the tab order, has no button role, and does not respond to Enter or Space. Screen readers announce it as plain text. Because the form contains two text fields and no submit button, the HTML implicit-submission rule also disables Enter-to-submit from within the fields. Keyboard and switch users therefore have no way to create an account.

**Fix:** replace with `<button type="submit" class="btn">Create account</button>` and delete the inline script. Keep the `.btn` styles; they apply unchanged.

### 2. Inputs have no labels (Critical)

Both text inputs rely on `placeholder`. Placeholder text disappears once the user types, is not reliably read as an accessible name by all assistive technology, and gives sighted users nothing to re-check after filling the field.

**Fix:** add a visible `<label for>` for each field. If the design must stay minimal, keep the label visually hidden with a standard `.visually-hidden` class, but a visible label is strongly preferred on a sign-up form.

### 3. Duplicate `id="email"` (Critical)

The password input reuses the email input's id. Any `for="email"` label, `aria-describedby`, or script lookup will bind to the first match only. This is what makes fixes 2 and 8 impossible until it is corrected.

**Fix:** change the password input to `id="password"`.

### 4. Focus indicator removed globally (Critical)

`:focus { outline: none; }` applies to every element. Sighted keyboard users lose all indication of where they are on the page.

**Fix:** delete the rule. If the goal was to hide outlines on mouse click, use `:focus:not(:focus-visible) { outline: none; }` and provide a visible `:focus-visible` style with at least 3:1 contrast against adjacent colours.

### 5. Positive tabindex (Serious)

`tabindex="3"` is the only positive tabindex on the page, so the "Read the terms" link receives focus before the email field. Focus then jumps backwards to the top of the form. This contradicts the visual order.

**Fix:** remove the `tabindex` attribute. Natural DOM order already places the link after the checkbox, which is sensible.

### 6. Logo has no alternative text (Serious)

Screen readers will read the filename, "logo-2024-final.png". Under my assumption that the logo identifies the company, it needs a short text alternative.

**Fix:** `alt="Swareco"` (substitute the real brand name). If the logo is purely decorative because the heading already names the company, use `alt=""` instead.

### 7. No page language (Serious)

Without `lang`, screen readers may apply the wrong pronunciation rules and browsers cannot offer correct translation or hyphenation.

**Fix:** `<html lang="en">`.

### 8. Password hint is orphaned (Moderate)

"At least 8 characters." is a visual neighbour of the password field but has no programmatic relationship, so it is not announced when the field receives focus.

**Fix:** give the paragraph `id="password-hint"` and add `aria-describedby="password-hint"` to the password input.

### 9. Missing input purpose (Moderate)

WCAG 1.3.5 requires fields collecting user data to expose their purpose so browsers and assistive tools can autofill.

**Fix:** `autocomplete="email"` on the email field and `autocomplete="new-password"` on the password field.

### 10. No validation or error reporting (Moderate)

No field is `required`, the password has no `minlength`, and the terms checkbox can be left unchecked. The script calls `form.submit()`, which skips browser constraint validation entirely, so even adding `required` would have no effect with the current control. There is no live region or error summary to report server-side errors.

**Fix:** add `required` to all three fields and `minlength="8"` to the password. Use a real submit button (finding 1) so native validation runs. For server-side errors, render an error summary above the form with `role="alert"` and link each message to its field with `aria-describedby` and `aria-invalid="true"`.

### 11. Structure and viewport (Minor)

There is no `<main>` landmark and no `<meta name="viewport">`. Without the viewport meta, mobile browsers render the page at desktop width and users must pinch-zoom to read it.

**Fix:** wrap the heading and form in `<main>`, and add `<meta name="viewport" content="width=device-width, initial-scale=1">`. Do not add `maximum-scale` or `user-scalable=no`.

### 12. Target size (Minor)

With 4 px vertical padding and default line height, the button is roughly 27 px tall. It clears the 24 px AA minimum but gives little margin and falls well short of the 44 px AAA guidance commonly used for primary actions.

**Fix:** increase padding to at least `10px 16px`, or set `min-height: 44px`.

## Corrected markup

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    .btn { display: inline-block; padding: 10px 16px; min-height: 44px;
           background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
    label { display: block; margin-top: 1rem; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Swareco">
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
        <input type="checkbox" id="terms" name="terms" required> I accept the terms
      </label>
      <a href="/terms">Read the terms</a>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

## Out of scope but worth flagging

The original form has no `method` or `action`, so `submit()` would send the password in the URL query string via GET. The corrected markup uses POST. This is a security issue, not an accessibility one, but it should be fixed in the same change.

## Recommended verification

Once the page can be opened in a browser: tab through the page end to end and confirm every control shows a focus ring in order; complete and submit the form using only the keyboard; run axe or Lighthouse to confirm zero violations; and test with VoiceOver or NVDA to confirm each field announces its label, the password hint, and any error messages.
