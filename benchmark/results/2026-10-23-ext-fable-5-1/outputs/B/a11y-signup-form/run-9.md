# Accessibility audit: Sign-up page

**Scope and assumptions.** Target standard is WCAG 2.2 Level AA. The review is static source analysis only, so anything that needs rendering (actual placeholder colour, computed sizes, screen reader output) is marked "at risk" rather than confirmed. I assume the page is in English, the logo is the only brand identification on the page (so it is informative, not decorative), there is no external CSS or JS beyond what is shown, and no server-side validation is known.

**Verdict: Fail.** A keyboard-only user cannot submit this form at all, and a screen reader user cannot tell which field is which. Three defects are blocking, six are high, and the rest are medium or low.

## Summary

| # | Severity | Issue | WCAG |
|---|----------|-------|------|
| 1 | Critical | Submit control is a `div` with `onclick`; not focusable, no role, no keyboard activation | 2.1.1, 4.1.2 |
| 2 | Critical | Email and password inputs have no label, only placeholder | 3.3.2, 1.3.1, 4.1.2 |
| 3 | Critical | Global `:focus { outline: none }` removes all focus indication | 2.4.7 |
| 4 | High | Duplicate `id="email"` on two inputs | 4.1.1, 1.3.1 |
| 5 | High | `tabindex="3"` on the terms link breaks focus order | 2.4.3 |
| 6 | High | Logo image has no `alt` | 1.1.1 |
| 7 | High | No `lang` attribute on `<html>` | 3.1.1 |
| 8 | High | Password hint not programmatically associated with the field | 3.3.2, 1.3.1 |
| 9 | High | No validation, no error messages, `required` missing; `form.submit()` bypasses native validation | 3.3.1, 3.3.3 |
| 10 | Medium | No `autocomplete` on email and password | 1.3.5 |
| 11 | Medium | No viewport meta; mobile reflow at 320 px will fail | 1.4.10 |
| 12 | Medium | Button target is roughly 24 px tall; at risk under Target Size (Minimum) | 2.5.8 |
| 13 | Medium | Placeholder contrast is browser-dependent; at risk | 1.4.3 |
| 14 | Low | No `main` landmark and the form has no accessible name | Best practice |
| 15 | Low | Form submits by GET with no `method`, so the password lands in the URL | Out of scope (security), flagged for the team |

## Findings

**1. The submit control is not a button (Critical).** `<div class="btn" onclick="submitForm()">` has no `tabindex`, no `role`, and no key handler, so Tab skips it and Enter or Space do nothing. Implicit submission does not rescue this: the form has no submit button and two text-type fields, so pressing Enter inside a field does not submit either. Keyboard-only users, switch users, and most screen reader users therefore cannot create an account. Screen readers also announce "Create account" as plain text, not as a button. Fix: replace the `div` with `<button type="submit" class="btn">Create account</button>` and drop the `onclick` and `submitForm()` entirely. The same CSS class applies unchanged.

**2. Inputs rely on placeholder as their only label (Critical).** Neither text field has a `<label>`, `aria-label`, or `aria-labelledby`. Placeholder text disappears as soon as the user types, is not reliably exposed as the accessible name by all assistive technology, and is not read back when a user returns to a filled field to review or correct it. Voice-control users cannot say "click Email" reliably. Fix: add visible `<label for>` elements for both fields and keep the placeholder only as a supplementary example, or remove it.

**3. Focus indicator removed globally (Critical).** `:focus { outline: none; }` applies to every focusable element on the page. Sighted keyboard users have no way to see where focus is. Fix: delete the rule. If a custom indicator is wanted, use `:focus-visible` with an outline of at least 2 px and 3:1 contrast against adjacent colours.

**4. Duplicate id (High).** Both inputs carry `id="email"`. This is invalid HTML and it will silently break the label fix in finding 2: a `<label for="email">` will attach to the first match only, and `getElementById`, autofill heuristics, and test selectors become ambiguous. Fix: change the password input to `id="password"`.

**5. Positive tabindex (High).** `tabindex="3"` on "Read the terms" puts that link first in the tab sequence, before any input, and makes it ambiguous relative to everything else on the page. The resulting order is link, email, password, checkbox, then nothing, because the submit control is unfocusable. Fix: remove the `tabindex` attribute and let DOM order define focus order. Consider placing the link before the checkbox so users read the terms before being asked to accept them.

**6. Logo has no alternative text (High).** `<img src="/img/logo-2024-final.png">` has no `alt`. Many screen readers will fall back to announcing the file name, so users hear "logo 2024 final png". Fix: `alt="<Company name>"` since it is the only branding on the page. If the logo is purely decorative, use `alt=""`.

**7. Missing page language (High).** `<html>` has no `lang`. Screen readers may use the wrong pronunciation rules, and browser translation and hyphenation lose a signal. Fix: `<html lang="en">`.

**8. Hint text is orphaned (High).** "At least 8 characters." is visually under the password field but has no programmatic link to it. A screen reader user who tabs straight into the password field never hears the requirement. Fix: give the paragraph an `id` and add `aria-describedby="password-hint"` on the password input.

**9. No validation or error handling (High).** No field is `required`, the checkbox is not enforced, and `form.submit()` deliberately skips the browser's constraint validation, so even `type="email"` is never checked. If the server rejects the submission, nothing on this page can identify the error in text or associate it with a field. Fix: add `required` and `minlength="8"` to the relevant fields, make the terms checkbox `required`, let the native submit button trigger validation, and design an inline error pattern that uses `aria-describedby` and `aria-invalid` with a text message next to the field.

**10. No autocomplete tokens (Medium).** Add `autocomplete="email"` and `autocomplete="new-password"`. This satisfies Identify Input Purpose and lets password managers do the right thing, which particularly helps users with cognitive or motor impairments.

**11. No viewport meta (Medium).** Without `<meta name="viewport" content="width=device-width, initial-scale=1">`, mobile browsers lay out at a desktop width and shrink it, forcing zoom plus horizontal scrolling. Content will not reflow at 320 px.

**12. Target size at risk (Medium).** The button has 4 px vertical padding and default line height, so it computes to roughly 24 px tall. That sits right on the 24 by 24 px minimum and could fall under it depending on font metrics. The checkbox is small, but its wrapping label extends the clickable area, which is acceptable. Fix: raise button padding to at least 8 px 16 px, or set `min-height: 44px` to meet the enhanced target.

**13. Placeholder contrast at risk (Medium).** Placeholder colour is browser default. Chrome's default is near 4.6:1, while Firefox renders placeholder at reduced opacity of the text colour, which with `#222` typically lands near 3.3:1 and fails. Unverifiable without rendering. Once real labels exist, this matters less, but set an explicit `::placeholder` colour of at least 4.5:1 if placeholders remain.

**14. Landmarks and form name (Low).** There is no `<main>` and the form has no accessible name. Wrap content in `<main>` and add `aria-labelledby` pointing at the `h1` so screen reader users can jump straight to the form.

**15. Password in URL (Low for accessibility, High for security).** No `method` means GET, so email and password are submitted as query parameters and end up in browser history and server logs. Add `method="post"` and an `action`. Flagged for the owning team; outside this audit's scope.

## What passes, and next steps

**Passes on inspection.** Page title is present and meaningful (2.4.2). There is a single `h1` describing the page (2.4.6). Body text `#222` on white is about 15.9:1, hint text `#595959` on white is about 7.0:1, and button text white on `#0a58ca` is about 6.5:1, all clearing 4.5:1 (1.4.3). The checkbox is correctly labelled by its wrapping `<label>`. Font sizes use `rem`, so text resizing works (1.4.4). No colour-only meaning, no motion, no time limits.

**Remediated markup for reference.** This is the minimum change set that clears every finding above except 13, which needs a rendered check:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    .btn { display: inline-block; padding: 8px 16px; min-height: 44px; background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
    label { display: block; margin-top: 0.75rem; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Company name">
    <h1 id="page-title">Create your account</h1>
    <form id="signup" method="post" action="/signup" aria-labelledby="page-title">
      <label for="email">Email</label>
      <input type="email" id="email" name="email" autocomplete="email" required>

      <label for="password">Password</label>
      <input type="password" id="password" name="password" autocomplete="new-password"
             minlength="8" required aria-describedby="password-hint">
      <p class="hint" id="password-hint">At least 8 characters.</p>

      <p><a href="/terms">Read the terms</a></p>
      <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>

      <button type="submit" class="btn">Create account</button>
    </form>
  </main>
</body>
</html>
```

**Verification once a browser is available.**
- Tab from the address bar through the page. Order must be email, password, link, checkbox, button, and each stop must show a visible ring.
- Submit with Enter from inside the email field and with Space on the button.
- Run axe or Lighthouse to confirm no duplicate-id, label, or alt violations remain.
- With NVDA or VoiceOver, confirm each field announces its label, and that the password field also announces "At least 8 characters".
- Submit the form empty and confirm each error is announced and visually tied to its field.
- Measure placeholder contrast in Chrome and Firefox, and the button's rendered height at 320 px and 400 percent zoom.
