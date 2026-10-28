# Accessibility audit: Sign-up page

**Verdict:** Fails WCAG 2.2 AA. Three defects block keyboard and screen-reader users from completing sign-up at all. Remediation is small (about 15 lines) and shown at the end.

**Assumptions:** target is WCAG 2.2 Level AA; page language is English; the logo is the only brand identification and therefore informative, not decorative; no other CSS or JS is loaded; `submitForm()` is the only intended submission path. Findings are from static review only, so rendered behaviour (focus rings in specific browsers, actual target sizes) is estimated.

## Findings

| # | Severity | Issue | WCAG | Fix |
|---|---|---|---|---|
| 1 | **Critical** | Submit control is a `<div onclick>`. It is not focusable, has no button role, and does not respond to Enter or Space. The form also has no `<button type="submit">`, and because it contains two text-type fields, the browser will not implicitly submit on Enter. Keyboard and switch users cannot submit the form. Screen readers announce it as plain text. | 2.1.1, 4.1.2 | Replace with `<button type="submit" class="btn">Create account</button>`. Drop the inline JS entirely. |
| 2 | **Critical** | Email and password inputs have no `<label>`; placeholder is the only name. Placeholder text disappears on input, is not reliably exposed as an accessible name, and is not read by all screen readers. | 1.3.1, 3.3.2, 4.1.2 | Add visible `<label for>` elements. Keep placeholders only as supplementary examples, if at all. |
| 3 | **Critical** | `:focus { outline: none; }` removes the focus indicator from every element with no replacement. Sighted keyboard users cannot tell where they are. | 2.4.7, 2.4.11 | Delete the rule, or replace with `:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }`. |
| 4 | **Serious** | Duplicate `id="email"` on both inputs. Breaks `label for`, `aria-describedby`, `getElementById`, and browser autofill. Assistive tech may associate the wrong name with the password field. | 1.3.1, 4.1.2 (and 4.1.1 in 2.1) | Change the password input to `id="password"`. |
| 5 | **Serious** | `tabindex="3"` on the terms link. Positive tabindex is focused before all tabindex-0 elements, so the first Tab press lands on "Read the terms" ahead of the email field. Focus order no longer matches visual order. | 2.4.3 | Remove the attribute. |
| 6 | **Serious** | Logo `<img>` has no `alt`. Screen readers will announce the filename, "logo-2024-final.png". | 1.1.1 | `alt="[Company name]"` if it identifies the site; `alt=""` if purely decorative. |
| 7 | **Serious** | `<html>` lacks `lang`. Screen readers may use the wrong pronunciation rules. | 3.1.1 | `<html lang="en">`. |
| 8 | **Serious** | No error identification. `form.submit()` bypasses browser constraint validation, so a malformed email, empty fields, or unchecked terms are never reported. There is no `required` on any field. | 3.3.1, 3.3.3 | Use a real submit button (fix 1), add `required` and `minlength="8"`, and if custom validation is added, render errors in text and link them with `aria-describedby`. |
| 9 | **Moderate** | The "At least 8 characters" hint is not programmatically tied to the password field. Screen-reader users in forms mode will not hear it. | 3.3.2, 1.3.1 | Give the hint an `id` and add `aria-describedby="password-hint"` to the input. |
| 10 | **Moderate** | No `autocomplete` on fields collecting personal data. | 1.3.5 | `autocomplete="email"` and `autocomplete="new-password"`. |
| 11 | **Moderate** | No viewport meta tag. Mobile browsers render at desktop width and shrink, defeating reflow and making text and targets tiny. | 1.4.4, 1.4.10 | `<meta name="viewport" content="width=device-width, initial-scale=1">`. |
| 12 | **Moderate** | Submission depends on inline JavaScript with no non-JS fallback. | Best practice (robustness) | Resolved by fix 1. |
| 13 | **Minor** | Button padding of 4px top and bottom yields roughly a 26px-tall target at default font size. This only marginally clears the 24px minimum. | 2.5.8 | Use at least `padding: 10px 16px`. |
| 14 | **Minor** | No `<main>` landmark, so screen-reader users cannot jump past the header. | Best practice (2.4.1 advisory) | Wrap the heading and form in `<main>`. |
| 15 | **Minor** | Terms acceptance is not marked `required`, so the form can be submitted without consent and without any message. | 3.3.1 | Add `required` to the checkbox. |

## What already passes

- **Colour contrast.** Button text (white on #0a58ca) is about 6.4:1. Hint text (#595959 on white) is about 7:1. Body text (#222) is about 16:1. All exceed the 4.5:1 AA threshold.
- **Terms checkbox** is correctly labelled by its wrapping `<label>`.
- **Page title** and a single **h1** are present and descriptive.
- **Link** uses default underlined styling, so it does not rely on colour alone.
- **Hint font size** of 0.9rem is relative and scales with user zoom.

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
    .btn { display: inline-block; padding: 10px 16px; background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
    label { display: block; margin-top: 1rem; }
  </style>
</head>
<body>
  <img src="/img/logo-2024-final.png" alt="Acme">
  <main>
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

**Still to verify in a browser:** that the focus ring is visible against the blue button, that native validation messages appear and are announced, and that the submit button measures at least 24x24 CSS pixels at the final font size.
