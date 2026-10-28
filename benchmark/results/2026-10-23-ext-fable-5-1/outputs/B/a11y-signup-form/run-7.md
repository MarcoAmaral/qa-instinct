# Accessibility Audit: Sign-up Page

**Scope:** Static source review of the supplied `Sign up` HTML against WCAG 2.2 Level AA. No browser, screen reader, or automated tooling was run, so findings that depend on rendering (browser default placeholder colour, actual rendered target sizes) are marked as needing verification.

**Assumptions**
- Target conformance level is WCAG 2.2 AA.
- Page content is English, so `lang="en"` is the correct value.
- The image is the company logo and the company name is not known; `[Company]` is used as a placeholder below.
- The inline `submitForm()` is the only script, and `/terms` is a normal same-site page.
- `.btn` is intended to be the form's submit control.

## Summary

| Severity | Count | Issues |
|---|---|---|
| Critical | 2 | Form cannot be submitted from the keyboard; focus indicator removed site-wide |
| High | 4 | Unlabelled inputs; duplicate `id`; logo has no text alternative; positive `tabindex` |
| Medium | 5 | No page language; hint not associated; no `autocomplete`; no validation or error handling; placeholder contrast unverified |
| Low | 4 | No viewport meta; no landmarks or form name; small target size; terms link discards entered data |

Overall verdict: **Fails WCAG 2.2 AA.** A keyboard-only or screen reader user cannot complete sign-up at all.

## Critical

### C1. The submit control is a `<div>` with an `onclick`
- **Where:** `<div class="btn" onclick="submitForm()">Create account</div>`
- **WCAG:** 2.1.1 Keyboard (A), 4.1.2 Name, Role, Value (A)
- **Impact:** A `<div>` is not in the tab order and does not respond to Enter or Space, so keyboard users cannot activate it. Screen readers announce it as plain text, not a button. There is also no fallback: the HTML implicit-submission rule does not fire on Enter when a form has no submit button and more than one text field, which this form has. Keyboard users have **no way to submit the form**.
- **Also:** `form.submit()` skips constraint validation and does not dispatch a `submit` event, so any future validation or analytics hooks will be bypassed.
- **Fix:** Replace with `<button type="submit">Create account</button>` and remove the inline script. Style the button via the `.btn` class.

### C2. Focus indicator removed globally
- **Where:** `:focus { outline: none; }`
- **WCAG:** 2.4.7 Focus Visible (AA); also undermines 2.4.11 Focus Not Obscured (AA)
- **Impact:** Sighted keyboard users cannot tell which field, checkbox, or link currently has focus anywhere on the page. No replacement indicator is provided.
- **Fix:** Delete the rule. If a custom indicator is wanted, use `:focus-visible` with an outline of at least 2px and 3:1 contrast against adjacent colours, for example `:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }`.

## High

### H1. Email and password inputs have no label
- **Where:** `<input type="email" placeholder="Email" ...>` and `<input type="password" placeholder="Password" ...>`
- **WCAG:** 1.3.1 Info and Relationships (A), 3.3.2 Labels or Instructions (A), 4.1.2 Name, Role, Value (A)
- **Impact:** Placeholder text is not a reliable accessible name. It disappears once the user types, so users who get interrupted or who use magnification lose the field's purpose. Some assistive technology and autofill combinations ignore placeholder entirely, announcing "edit text, blank". Voice-control users cannot say "click Email" reliably.
- **Fix:** Add a visible `<label for="...">` for each input. Keep placeholders only as example values, never as the sole label.

### H2. Duplicate `id="email"` on two different inputs
- **Where:** Both the email and password inputs
- **WCAG:** 4.1.1 Parsing (A, WCAG 2.0/2.1; retired in 2.2 but the consequence maps to 1.3.1 and 4.1.2)
- **Impact:** Any `<label for="email">` or `aria-describedby` would bind to only the first element, so the password field could never be correctly labelled or described. `getElementById` returns the email input only. Browser autofill heuristics may also misclassify the password field.
- **Fix:** Change the password field to `id="password"`.

### H3. Logo image has no `alt` attribute
- **Where:** `<img src="/img/logo-2024-final.png">`
- **WCAG:** 1.1.1 Non-text Content (A)
- **Impact:** Screen readers fall back to the file name and announce "logo-2024-final.png, image". If this is the first thing on the page, it is also the first thing a screen reader user hears.
- **Fix:** `alt="[Company]"` if the logo is informational, or `alt=""` if the heading already identifies the site and the logo is purely decorative. If the logo links home, the alt text should be "[Company] home".

### H4. Positive `tabindex` on the terms link
- **Where:** `<a href="/terms" tabindex="3">`
- **WCAG:** 2.4.3 Focus Order (A)
- **Impact:** Elements with a positive `tabindex` are visited before all elements with `tabindex="0"` or natural focus. The first Tab press on this page lands on "Read the terms", skipping the email and password inputs. Focus order no longer matches visual and reading order.
- **Fix:** Remove the `tabindex` attribute. The link is natively focusable and its DOM position is already correct.

## Medium

### M1. No language declared on the document
- **Where:** `<html>`
- **WCAG:** 3.1.1 Language of Page (A)
- **Impact:** Screen readers may pick the wrong pronunciation rules; browser translation prompts behave unpredictably.
- **Fix:** `<html lang="en">`.

### M2. Password hint is not programmatically associated with the field
- **Where:** `<p class="hint">At least 8 characters.</p>`
- **WCAG:** 3.3.2 Labels or Instructions (A), 1.3.1 Info and Relationships (A)
- **Impact:** A screen reader user focused on the password field is not told about the length requirement. They find out only if they read linearly past the field, or when submission fails.
- **Fix:** Give the paragraph an `id` and reference it with `aria-describedby` on the password input. Depends on fixing H2 first.

### M3. No `autocomplete` tokens on personal-data fields
- **Where:** Email and password inputs
- **WCAG:** 1.3.5 Identify Input Purpose (AA)
- **Impact:** Users with cognitive or motor impairments rely on browser autofill and password managers. Without tokens the browser has to guess, and the duplicate `id` (H2) makes that guess worse.
- **Fix:** `autocomplete="email"` on the email field and `autocomplete="new-password"` on the password field.

### M4. No required fields, no validation, no error messaging
- **Where:** Whole form
- **WCAG:** 3.3.1 Error Identification (A), 3.3.3 Error Suggestion (AA)
- **Impact:** The form can be sent empty or with an unchecked terms box. Nothing in the markup identifies which fields are mandatory or how errors will be reported. Because `form.submit()` bypasses native constraint validation, even `type="email"` does nothing today.
- **Fix:** Add `required` to all three controls, `minlength="8"` to the password, and use a real submit button so native validation runs. For custom errors, render text near the field, link it with `aria-describedby`, and set `aria-invalid="true"`.

### M5. Placeholder text contrast is unverified
- **Where:** Both inputs rely on placeholder text
- **WCAG:** 1.4.3 Contrast (Minimum) (AA)
- **Impact:** No placeholder colour is set, so the browser default applies. Chromium's default is roughly 4.6:1 on white and passes; some WebKit defaults are lighter and fail. Because the placeholder is currently the only label (H1), a failure here would be more serious than usual.
- **Fix:** Resolved by H1. If placeholders are kept as examples, set `::placeholder { color: #595959; }` to guarantee at least 4.5:1.

## Low

### L1. No viewport meta tag
- **Where:** `<head>`
- **WCAG:** 1.4.10 Reflow (AA), indirectly
- **Impact:** Mobile browsers render at a desktop width and shrink the page, so users must pinch-zoom to read and tap. Content does not reflow to the viewport.
- **Fix:** `<meta name="viewport" content="width=device-width, initial-scale=1">`. Do not add `user-scalable=no` or a `maximum-scale`.

### L2. No landmarks and no accessible name on the form
- **Where:** `<body>`, `<form id="signup">`
- **WCAG:** 1.3.1 Info and Relationships (A), best practice
- **Impact:** Screen reader users cannot jump to the main content or identify the form in a landmark list.
- **Fix:** Wrap the content in `<main>` and add `aria-labelledby` on the form pointing at the `<h1>`.

### L3. Button target size is close to the minimum
- **Where:** `.btn { padding: 4px 8px; }`
- **WCAG:** 2.5.8 Target Size (Minimum) (AA)
- **Impact:** With the default 16px font the rendered height is roughly 26px, which clears the 24px minimum but is well under the 44px recommended for primary touch actions. Needs confirmation in a browser.
- **Fix:** Increase to at least `padding: 12px 16px` and set `min-height: 44px`.

### L4. Terms link navigates away from a partially completed form
- **Where:** `<a href="/terms">`
- **WCAG:** Not a failure; usability concern related to 3.2 Predictable
- **Impact:** Following the link discards whatever the user has typed. Users with cognitive impairments are disproportionately affected by having to start over.
- **Fix:** Open terms in a modal dialog or new tab, and if using a new tab say so in the link text, for example "Read the terms (opens in a new tab)".

## Side finding (not accessibility)

The form has no `method` or `action`. On submit it defaults to `GET` against the current URL, which places the email and password in the query string, browser history, and server logs. Add `method="post"` and an explicit `action` before shipping.

## What passes

| Check | Result |
|---|---|
| Body text `#222` on `#fff` | 15.9:1, passes AA and AAA |
| Hint text `#595959` on `#fff` | 7.0:1, passes AA and AAA, including at 0.9rem |
| Button text `#fff` on `#0a58ca` | 6.4:1, passes AA |
| Page `<title>` is present and descriptive | Passes 2.4.2 |
| Single `<h1>` describing the page purpose | Passes 1.3.1 / 2.4.6 |
| Terms checkbox is wrapped in a `<label>` | Passes 1.3.1 / 4.1.2 |
| `<meta charset="utf-8">` | Present |
| Colour is not used as the only means of conveying information | Passes 1.4.1 |

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
    .btn { display: inline-block; min-height: 44px; padding: 12px 16px;
           background: #0a58ca; color: #fff; border: 0; font: inherit; cursor: pointer; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
    label { display: block; margin-top: 1rem; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="[Company]">
    <h1 id="signup-heading">Create your account</h1>
    <form id="signup" method="post" action="/signup" aria-labelledby="signup-heading">
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

## Verification steps once the page can be opened

1. Tab through the page from the address bar. Expected order: email, password, checkbox, terms link, submit button, with a visible focus ring on each.
2. Fill in the fields and press Enter in the password input. The form should submit.
3. Submit the form empty. Each required field should report an error that is announced by a screen reader.
4. With NVDA or VoiceOver, focus the password field. It should announce the label, "required", and "At least 8 characters."
5. Run axe or Lighthouse to confirm no duplicate IDs, missing labels, or missing `alt` remain.
6. On a 320px-wide viewport, confirm no horizontal scrolling and that the button is at least 44px tall.
7. Check the rendered placeholder colour, if any placeholders remain, with a contrast tool against the input background.
