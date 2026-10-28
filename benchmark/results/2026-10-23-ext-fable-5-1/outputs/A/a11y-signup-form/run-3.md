# Accessibility audit: Sign-up page

**Verdict:** Not shippable. A keyboard-only user cannot submit the form at all, and a screen reader user cannot tell the two text fields apart. Both are WCAG 2.2 Level A failures, and there are several more A/AA failures behind them.

**Assumptions:** The page is in English. The logo is the only brand identification on the page, so it needs a text alternative rather than being decorative. The site has no global stylesheet or script beyond what is shown. Nothing was verified in a browser or with assistive technology; findings are from static reading of the source, and contrast ratios are computed from the hex values.

## Findings

| # | Severity | Issue | WCAG 2.2 | Where |
|---|----------|-------|----------|-------|
| 1 | Critical | Submit control is a `div` with `onclick`. It is not focusable, has no button role or name, and does not respond to Enter or Space. Implicit submission on Enter also does not apply, because the form has no submit button and more than one text field. Keyboard, switch and most screen reader users cannot create an account. | 2.1.1 Keyboard (A), 4.1.2 Name, Role, Value (A) | `<div class="btn" onclick="submitForm()">` |
| 2 | Critical | `:focus { outline: none; }` removes the focus indicator from every element with no replacement. Sighted keyboard users cannot see where they are. | 2.4.7 Focus Visible (AA) | `<style>` |
| 3 | High | Email and password inputs have no label. The placeholder is the only text, it disappears once the user types, and it is not a reliable accessible name across browsers and screen readers. | 1.3.1 Info and Relationships (A), 3.3.2 Labels or Instructions (A), 4.1.2 (A) | both `<input>` elements |
| 4 | High | Duplicate `id="email"` on the email and password inputs. Any `label for`, `aria-describedby`, or script lookup resolves to the email field only, so even a label fix would fail until this is corrected. 4.1.1 is retired in WCAG 2.2 but the practical breakage remains. | 1.3.1 (A), 4.1.2 (A) | password `<input>` |
| 5 | High | Logo image has no `alt`. Screen readers announce the file name, "logo-2024-final.png". | 1.1.1 Non-text Content (A) | `<img>` |
| 6 | High | No `lang` attribute on `<html>`. Screen readers may use the wrong pronunciation rules and translation tools cannot detect the language. | 3.1.1 Language of Page (A) | `<html>` |
| 7 | High | `tabindex="3"` on the terms link puts it first in the tab order, before the email field, which does not match the visual order. Positive tabindex values also push the link ahead of any other focusable content added later. | 2.4.3 Focus Order (A) | `<a href="/terms">` |
| 8 | Medium | The "At least 8 characters" hint is not programmatically tied to the password field. In forms mode a screen reader will skip it. There is also no `minlength`, so the rule is not enforced. | 3.3.2 (A), 1.3.1 (A) | `.hint` paragraph |
| 9 | Medium | No `autocomplete` on the email and password fields. Email and new password are both listed input purposes. | 1.3.5 Identify Input Purpose (AA) | both `<input>` elements |
| 10 | Medium | No validation or error handling of any kind. Fields are not `required`, the terms checkbox is not enforced, and `form.submit()` bypasses built-in constraint validation, so even the `type="email"` check never runs. Users get no error identification if the server rejects the submission. | 3.3.1 Error Identification (A), 3.3.3 Error Suggestion (AA) | `<form>`, `submitForm()` |
| 11 | Medium | No viewport meta tag. Mobile browsers lay the page out at roughly 980px and require two-dimensional scrolling and pinch zoom to read it. | 1.4.10 Reflow (AA) | `<head>` |
| 12 | Low | Placeholder text is doing the job of a label, so its contrast matters. Browser default placeholder colour is around 4.6:1 in Chrome and lower in Firefox. Resolved by finding 3. | 1.4.3 Contrast (Minimum) (AA) | both `<input>` elements |
| 13 | Low | The "Create account" control has 4px vertical padding. Its rendered height is roughly 26px at default font size, which just clears the 24px minimum but leaves no margin. | 2.5.8 Target Size (Minimum) (AA) | `.btn` |
| 14 | Low | No `main` landmark. On a one-form page this is a best practice rather than a failure, but it costs nothing. | Best practice | `<body>` |
| 15 | Low | Page title "Sign up" is accurate but does not identify the site. Fine for a single-site tab, weaker with many tabs open. | 2.4.2 Page Titled (A), advisory | `<title>` |

**Functional bug, not accessibility:** none of the inputs has a `name` attribute, so the form submits no data regardless of how it is triggered.

## What passes

- Body text, hint text and button text all meet AA contrast. Values computed from the hex colours:

| Pair | Ratio |
|------|-------|
| `#222` on `#fff` | 15.9:1 |
| `#595959` on `#fff` | 7.0:1 |
| `#fff` on `#0a58ca` | 6.4:1 |

- Single `h1` matching the page purpose.
- Terms checkbox is wrapped in a `label`, so it has an accessible name.
- Hint font size at 0.9rem is still comfortably readable and scales with user settings.
- No motion, timing, audio or colour-only information.

## Corrected markup

The following resolves every finding above. Replace the site name and form action with the real values.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up - Example</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    label { display: block; margin-top: 1rem; }
    .btn {
      display: inline-block; padding: 8px 16px; margin-top: 1rem;
      background: #0a58ca; color: #fff; border: 0; font: inherit; cursor: pointer;
    }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .btn:focus-visible { outline-color: #222; }
    .hint { color: #595959; font-size: 0.9rem; margin: 0.25rem 0 0; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Example">
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
        <input type="checkbox" id="terms" name="terms" required>
        I accept the terms
      </label>
      <a href="/terms">Read the terms</a>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

Notes on the changes:

- **Native `button type="submit"`** replaces the `div` and the script. It is focusable, has the correct role and name, submits on Enter and Space, and runs constraint validation. The `onclick` handler and inline script are no longer needed.
- **`:focus-visible` with a 3px outline** restores a visible indicator while avoiding the mouse-click outline that the original rule was probably trying to suppress.
- **Visible `label` elements** replace placeholders. If the design requires placeholder-style labels, use a float-label pattern that keeps the `label` element in the DOM rather than relying on `placeholder`.
- **`aria-describedby`** links the hint to the password field so it is read when the field receives focus.
- **The positive `tabindex` is removed.** Source order now matches tab order.
- **`required` and `minlength`** give users browser-native error messages. For server-side errors, render them next to the relevant field, reference them with `aria-describedby`, and set `aria-invalid="true"` on the field.

## Still to verify in a browser

- Rendered target size of the button at the site's real font stack and line height.
- Focus outline colour against any real page background or header image not shown here.
- Screen reader announcement order with NVDA or VoiceOver, particularly that the hint is read after the password label.
- Server-side error rendering, which is not part of this source.
