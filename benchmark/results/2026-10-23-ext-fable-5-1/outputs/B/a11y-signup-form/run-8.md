# Accessibility audit: Sign-up page

**Scope and method.** Static review of the supplied HTML and CSS against WCAG 2.2 Level AA, plus common screen-reader and keyboard behaviour inferred from the HTML spec. No browser, assistive technology, or automated scanner was run, so runtime-dependent items are marked as estimates.

**Verdict: Fail.** The page cannot be completed by keyboard alone, and it offers no visible focus indicator. Those two defects alone block keyboard-only users, switch users, and most screen-reader users from creating an account.

| ID | Severity | Issue | WCAG 2.2 |
|---|---|---|---|
| A11Y-01 | Critical | Submit control is a `div` with `onclick`; form cannot be submitted by keyboard | 2.1.1, 4.1.2 |
| A11Y-02 | Critical | Global `:focus { outline: none }` removes all focus indication | 2.4.7 |
| A11Y-03 | High | Email and password fields have no label; placeholder is the only cue | 1.3.1, 3.3.2, 4.1.2 |
| A11Y-04 | High | Duplicate `id="email"` on two inputs | 1.3.1, 4.1.2 |
| A11Y-05 | High | Positive `tabindex="3"` breaks focus order | 2.4.3 |
| A11Y-06 | Medium | Password hint not programmatically linked to the field | 1.3.1, 3.3.2 |
| A11Y-07 | Medium | No `autocomplete` on email or password | 1.3.5 |
| A11Y-08 | Medium | `<html>` has no `lang` attribute | 3.1.1 |
| A11Y-09 | Medium | Logo image has no `alt` | 1.1.1 |
| A11Y-10 | Medium | No required marking, validation, or error messaging | 3.3.1, 3.3.2, 3.3.3 |
| A11Y-11 | Low | No landmarks and no accessible name for the form | 1.3.1, 2.4.1 (best practice) |
| A11Y-12 | Low | Small touch targets and no viewport meta | 2.5.8 (passes), 2.5.5 (AAA, fails) |

## Findings

**A11Y-01. Critical. The submit control is not a button.**
`<div class="btn" onclick="submitForm()">` has no role, is not focusable, and does not respond to Enter or Space. Screen readers announce it as plain text. Pressing Enter inside a field does not help either: the form has no submit button and contains two implicit-submission-blocking fields, so per the HTML spec Enter does nothing. Net effect: sign-up requires a pointing device. The handler also calls `form.submit()`, which skips native constraint validation.
Fix:
```html
<form id="signup" method="post" action="/signup" aria-labelledby="page-title">
  ...
  <button type="submit" class="btn">Create account</button>
</form>
```
Delete the inline script and the `onclick`.

**A11Y-02. Critical. Focus indicator removed for every element.**
`:focus { outline: none; }` applies to the inputs, checkbox, and link with no replacement style. Sighted keyboard users cannot tell where they are on the page.
Fix: remove the rule, or replace it with a visible indicator that meets 3:1 against adjacent colours:
```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

**A11Y-03. High. Email and password fields have no label.**
Both inputs rely on `placeholder`. Placeholder text disappears once the user types, so the field purpose is lost during entry and on review. Some assistive technologies do not use placeholder as the accessible name. Placeholder colour is left to the browser; Firefox renders it at reduced opacity, which is likely to fall below 4.5:1 against white. This last point is an estimate, not a measured value.
Fix:
```html
<label for="email">Email</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<label for="password">Password</label>
<input type="password" id="password" name="password" autocomplete="new-password"
       minlength="8" required aria-describedby="password-hint">
<p class="hint" id="password-hint">At least 8 characters.</p>
```

**A11Y-04. High. Duplicate `id="email"`.**
The password input reuses the email input's id. Any `label for`, `aria-describedby`, autofill heuristic, or `getElementById` call resolves to the first element only. This makes correct labelling of the password field impossible until it is fixed, and it will confuse automated test selectors.
Fix: rename to `id="password"` as shown above.

**A11Y-05. High. Positive `tabindex` corrupts focus order.**
`tabindex="3"` on the terms link places it ahead of everything in natural order. The first Tab press lands on "Read the terms", then jumps back to the email field. Focus order no longer matches the visual order.
Fix: remove the `tabindex` attribute. Consider placing the link inside the checkbox label text or directly before the checkbox so it is encountered before the user is asked to accept. Because following the link leaves the page, the typed email and password are lost. Either warn that it opens in a new tab or show the terms in a dialog or expandable region.

**A11Y-06. Medium. Password hint not associated with the field.**
"At least 8 characters." is a free-standing paragraph. Screen readers in forms mode will not read it when the password field receives focus.
Fix: `aria-describedby="password-hint"` on the input and `id="password-hint"` on the paragraph, as shown in A11Y-03.

**A11Y-07. Medium. No input purpose identification.**
Email and password collect user information but carry no `autocomplete` token. Users who rely on browser autofill or personalisation tools receive no help.
Fix: `autocomplete="email"` and `autocomplete="new-password"`.

**A11Y-08. Medium. Page language not declared.**
Screen readers may pick the wrong pronunciation rules.
Fix: `<html lang="en">`. Assumption: the page is in English.

**A11Y-09. Medium. Logo has no alternative text.**
Screen readers will announce "image" or read the filename "logo-2024-final.png". Assumption: the logo is the only branding on the page and is not a link, so it is informative.
Fix: `alt="<Company name>"`. If the product name is also present in the heading, `alt=""` is acceptable.

**A11Y-10. Medium. No required indication, validation, or error handling.**
No field is marked `required`, nothing tells the user which fields are mandatory, and because submission goes through `form.submit()` the browser never validates the email format or the password length. The terms checkbox can be left unchecked. There is no error state to audit, which is itself a failure to meet the error identification and suggestion criteria.
Fix: add `required` and `minlength="8"`, submit through a real button so native validation runs, state "All fields are required" above the form, and on server-side rejection render a summary with `role="alert"` plus per-field messages linked via `aria-describedby` and `aria-invalid="true"`.

**A11Y-11. Low. No landmarks and no form name.**
There is no `<main>` region and the form has no accessible name. Minor on a one-form page, but cheap to fix.
Fix: wrap content in `<main>`, give the `h1` an id, and reference it with `aria-labelledby` on the form.

**A11Y-12. Low. Small targets and no viewport meta.**
The button is roughly 27 px tall with 4 px vertical padding, which clears the 24 px AA minimum but not the 44 px AAA recommendation. Without `<meta name="viewport" content="width=device-width, initial-scale=1">` mobile browsers render at desktop width, shrinking every target. Sizes are estimates from default font metrics.
Fix: add the viewport meta and set `min-height: 44px` and matching padding on `.btn`.

## Passed checks

- Page title "Sign up" is present and descriptive.
- Single `h1` describes the page purpose.
- Body text contrast is about 15.9:1, hint text about 7.0:1, button text about 6.4:1. All exceed 4.5:1.
- The terms checkbox is correctly wrapped in a `<label>` and has the accessible name "I accept the terms".
- `type="email"` is used, which triggers an appropriate on-screen keyboard.
- No fixed pixel font sizes, no zoom restriction, no motion, no autoplay, and no time limits.

## Assumptions and out-of-scope observations

- Target conformance level assumed to be WCAG 2.2 AA. Under WCAG 2.1 the duplicate id would additionally fail 4.1.1 Parsing.
- All three fields are assumed to be mandatory.
- Contrast and target-size figures were computed from the CSS and default browser metrics, not measured in a browser.
- Not an accessibility defect, but worth escalating: the form has no `method`, so it submits via GET and places the email and password in the URL, browser history, and server logs. Use `method="post"`. The current design also fails entirely when JavaScript is disabled.
