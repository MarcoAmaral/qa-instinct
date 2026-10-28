# Accessibility audit: sign-up page

## Scope and assumptions

- Target standard is WCAG 2.2 Level AA. Severity uses four levels: Critical blocks a user group from completing sign-up, Serious makes it substantially harder, Moderate degrades the experience, Minor is advisory.
- Review is static source only. No browser, screen reader, or automated scanner was run, so findings that depend on rendering are marked as needing confirmation.
- The page is assumed to be complete as shown: no external CSS or JS, browser default styles apply to everything not in the inline stylesheet, and the one script is the only behaviour.
- The logo is assumed to be the company brand mark and the only place the brand name appears, so it is informative rather than decorative.
- Page language is assumed to be English.

## Summary

| Severity | Count | Findings |
|---|---|---|
| Critical | 2 | Submit control is a non-focusable div; all focus outlines removed |
| Serious | 7 | Placeholder-only labels; duplicate id; missing alt; positive tabindex; unassociated hint; no lang; no autocomplete |
| Moderate | 3 | No validation or error messaging; no viewport meta; no landmarks |
| Minor | 3 | Placeholder reliance; target size margin; page title |

Keyboard-only users cannot submit this form at all. Screen reader users get no labels beyond disappearing placeholder text and no logo name. The page would fail a WCAG 2.2 AA conformance claim on multiple Level A criteria.

## Findings

**C1. Submit control is a div with an onclick handler.** Critical. WCAG 2.1.1 Keyboard, 4.1.2 Name Role Value.
The "Create account" control is a `<div>` so it is not in the tab order, has no button role, and only responds to mouse clicks. Because the form has no submit button and more than one text field, pressing Enter in a field does not trigger implicit submission either. Keyboard, switch, and most screen reader users have no way to submit. In Windows forced-colors mode the background colour is dropped so the div no longer even looks like a button.
Fix: replace with `<button type="submit" class="btn">Create account</button>` and delete the script. Keep the `.btn` class but add `border: 0; font: inherit; cursor: pointer`.

**C2. Focus indicator removed globally.** Critical. WCAG 2.4.7 Focus Visible, 2.4.11 Focus Not Obscured.
The rule `:focus { outline: none; }` removes the visible focus ring from every element with no replacement. Sighted keyboard users cannot tell which field or link is active.
Fix: delete the rule. If a custom style is wanted, use `:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }` and give the blue button a contrasting outline colour such as `#222`.

**S1. Email and password fields have no label.** Serious. WCAG 1.3.1 Info and Relationships, 3.3.2 Labels or Instructions, 2.4.6 Headings and Labels.
Both inputs rely on `placeholder` only. Placeholder text vanishes once the user types, is not announced consistently by all assistive technology, is not a label for voice-control users, and typically renders at low contrast. The accessibility API will fall back to the placeholder for the name, so the field is not nameless, but this still fails the label requirement.
Fix: add visible `<label for>` elements before each input. Placeholders may stay only as example values.

**S2. Duplicate `id="email"` on the password field.** Serious. WCAG 1.3.1, 4.1.2 (4.1.1 Parsing under 2.0 and 2.1).
Two elements share one id. Any `label for="email"`, `aria-describedby`, or script lookup resolves to the first input only, so the password field cannot be labelled, described, or targeted. This defect will also break any fix for S1 and S5 until corrected.
Fix: change the password input to `id="password"`.

**S3. Logo image has no `alt` attribute.** Serious. WCAG 1.1.1 Non-text Content.
Screen readers will either announce the file name "logo-2024-final.png" or skip the image. Under the stated assumption that the logo carries the brand name, that information is lost.
Fix: `alt="Company name"`. If a text brand name is added elsewhere on the page, use `alt=""` instead.

**S4. Positive `tabindex="3"` on the terms link.** Serious. WCAG 2.4.3 Focus Order.
Elements with a positive tabindex are focused before all naturally focusable elements. Tab order becomes: terms link, email, password, checkbox. The link is reached before the fields it relates to and the sequence no longer matches the visual order.
Fix: remove the `tabindex` attribute. Natural DOM order is correct.

**S5. Password hint is not associated with the field.** Serious. WCAG 3.3.2 Labels or Instructions, 1.3.1.
"At least 8 characters." is a plain paragraph. A screen reader user in forms mode tabbing through fields will never hear it, and it is announced after the field in reading mode.
Fix: give the paragraph `id="password-hint"` and add `aria-describedby="password-hint"` to the password input. Also add `minlength="8"` so the constraint is enforced.

**S6. No `lang` attribute on `<html>`.** Serious. WCAG 3.1.1 Language of Page.
Screen readers may pick the wrong speech synthesiser voice and pronunciation rules. Translation tools and hyphenation also depend on it.
Fix: `<html lang="en">`.

**S7. No `autocomplete` on email and password.** Serious. WCAG 1.3.5 Identify Input Purpose.
Inputs collecting personal data must declare their purpose so browsers and assistive tools can autofill and password managers can offer a generated password. This particularly affects users with motor and cognitive disabilities.
Fix: `autocomplete="email"` on the email input, `autocomplete="new-password"` on the password input.

**M1. No validation, required state, or error messaging.** Moderate. WCAG 3.3.1 Error Identification, 3.3.3 Error Suggestion, 4.1.3 Status Messages.
No field is `required`, nothing enforces the 8-character rule or terms acceptance, and the script calls `form.submit()` which bypasses browser constraint validation and the submit event entirely. Users who miss a field get no feedback. Switching to a native submit button and adding `required` and `minlength` restores browser validation as a baseline. For full conformance, add inline error text linked with `aria-describedby`, set `aria-invalid="true"` on failing fields, and move focus to the first error on submit.

**M2. No viewport meta tag.** Moderate. WCAG 1.4.10 Reflow, 1.4.4 Resize Text.
Without `<meta name="viewport" content="width=device-width, initial-scale=1">` mobile browsers render at a desktop width and scale down, making text tiny and requiring horizontal panning. Confirm in a browser; the fix is the one-line meta tag. Do not add `user-scalable=no` or `maximum-scale`.

**M3. No landmark regions.** Moderate. WCAG 1.3.1, best practice for 2.4.1 Bypass Blocks.
Content is placed directly in `<body>` with no `<main>` or `<header>`. Screen reader users cannot jump to the main content by landmark. Fix: wrap the heading and form in `<main>`.

**N1. Placeholder text as the only in-field hint.** Minor. WCAG 1.4.3 Contrast, 3.3.2.
Browser default placeholder colour is roughly `#757575`, which is close to the 4.5:1 limit and varies by browser. Once real labels exist, remove placeholders or confirm the rendered contrast.

**N2. Button target height is marginal.** Minor. WCAG 2.5.8 Target Size (Minimum).
With 4px vertical padding and default 16px text the button is roughly 26px tall, just over the 24px minimum. Increase padding to `8px 16px` for a comfortable margin and a better touch target. The checkbox is user-agent sized and exempt.

**N3. Page title lacks site context.** Minor. WCAG 2.4.2 Page Titled.
"Sign up" is acceptable but "Sign up – Company name" distinguishes the tab from other sites' sign-up pages. Advisory.

## What passes and out-of-scope notes

Colour contrast of authored text passes. Ratios computed from the stylesheet against the white background:

| Element | Colours | Ratio | Result |
|---|---|---|---|
| Body text | #222 on #fff | 15.9:1 | Pass AAA |
| Hint text | #595959 on #fff | 7.0:1 | Pass AAA |
| Button label | #fff on #0a58ca | 6.4:1 | Pass AA |

Also acceptable: a single `<h1>` as the page heading, `type="email"` and `type="password"` for correct keyboards and masking, font sizes in `rem` so they scale with user preferences, the checkbox label wrapping its input so it has an accessible name, and descriptive link text.

Functional defects found in passing, outside accessibility scope but blocking in practice:

- No input has a `name` attribute, so nothing is sent on submit.
- The form has no `action` or `method`, so it defaults to a GET to the current URL. Once names are added the password would appear in the query string and server logs. Set `method="post"`.
- Terms acceptance is not enforced.

## Corrected markup

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up – Company name</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    label { display: block; margin-top: 1rem; }
    .btn { display: inline-block; padding: 8px 16px; background: #0a58ca; color: #fff;
           border: 0; font: inherit; cursor: pointer; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .btn:focus-visible { outline-color: #222; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <main>
    <img src="/img/logo-2024-final.png" alt="Company name">
    <h1>Create your account</h1>
    <form id="signup" action="/signup" method="post">
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

This resolves every Critical and Serious finding and the Moderate findings except full custom error messaging, which M1 describes.

## Verification when a browser is available

1. Run the W3C HTML validator and axe-core on the original to confirm the duplicate id, missing alt, missing lang, and label failures, then re-run on the fixed page expecting zero violations.
2. Keyboard only: Tab from the address bar and confirm order is email, password, checkbox, link, button. Confirm a visible focus ring on each. Press Enter in the password field and confirm the form submits.
3. Screen reader: NVDA with Firefox and VoiceOver with Safari. Confirm the logo announces the company name, each field announces its label, the password field announces the hint, and the submit control announces as "Create account, button".
4. Zoom to 200% and resize the viewport to 320px wide. Confirm no horizontal scrolling and no clipped text.
5. Enable Windows forced-colors mode. Confirm the button still renders with a button appearance and the focus ring remains visible.
6. Submit with empty fields and a 7-character password. Confirm errors are announced and focus moves to the first invalid field.
