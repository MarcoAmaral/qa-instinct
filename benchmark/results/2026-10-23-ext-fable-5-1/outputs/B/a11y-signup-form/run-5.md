# Accessibility Audit: Sign-up Page

**Standard:** WCAG 2.2 Level AA (with notes where 2.1 and AAA differ)
**Method:** Static source review only. No browser, screen reader, or automated scanner was run. Findings that need runtime confirmation are marked.
**Verdict:** **Fail.** The page cannot be completed with a keyboard alone, and screen reader users receive no field labels. Two blocker-level defects plus several high-severity ones.

## Assumptions

- The page is served in English, as the only visible text is English.
- The snippet is the entire page; there is no surrounding template adding `lang`, landmarks, labels, or focus styles.
- JavaScript is enabled; `submitForm()` is the only submission path intended.
- The logo is the only branding on the page, so it is informative rather than decorative.
- Contrast ratios are computed from the CSS hex values against the `#fff` body background.

## Summary

| Severity | Count | IDs |
|---|---|---|
| Blocker | 2 | A11Y-01, A11Y-02 |
| High | 4 | A11Y-03, A11Y-04, A11Y-05, A11Y-06 |
| Medium | 4 | A11Y-07, A11Y-08, A11Y-09, A11Y-10 |
| Low | 3 | A11Y-11, A11Y-12, A11Y-13 |

## Keyboard walkthrough (predicted)

Tab order as the source will produce it:

1. "Read the terms" link (positive `tabindex="3"` moves it ahead of everything).
2. Email input.
3. Password input.
4. Terms checkbox.
5. End of page. The "Create account" div is never reached.

No element shows a focus ring at any step because of `:focus { outline: none; }`. Pressing Enter in the email or password field does not submit: the form has no submit button and has two text-type fields, so the HTML implicit-submission rule blocks it. Net result: a keyboard-only user can fill in the form but cannot submit it.

## Findings

### A11Y-01 · Blocker · Submit control is a non-interactive `div`
**WCAG:** 2.1.1 Keyboard (A), 4.1.2 Name, Role, Value (A)
**Location:** `<div class="btn" onclick="submitForm()">Create account</div>`
**Issue:** A `div` has no role, is not focusable, and does not respond to Enter or Space. Screen readers announce it as plain text, not as a button. Combined with the absence of a native submit button, the form has no keyboard-reachable submission path.
**Impact:** Keyboard, switch, and screen reader users cannot create an account.
**Fix:** Replace with a native button. This also restores Enter-to-submit and browser constraint validation.

```html
<button type="submit" class="btn">Create account</button>
```

Drop the inline `onclick` and the `submitForm()` helper, or if you must keep JS, attach a `submit` listener to the form instead of calling `form.submit()`, which skips validation and the submit event.

### A11Y-02 · Blocker · Email and password inputs have no label
**WCAG:** 1.3.1 Info and Relationships (A), 3.3.2 Labels or Instructions (A), 4.1.2 Name, Role, Value (A)
**Location:** Both `<input>` elements in the form
**Issue:** Placeholders are the only identification. Placeholder text is not a reliable accessible name across assistive technologies, disappears once the user types, and is typically rendered in low-contrast gray.
**Impact:** Screen reader users may hear "edit text" with no field name. Sighted users lose the label the moment they start typing and cannot re-check which field is which.
**Fix:** Add visible, programmatically associated labels. Keep placeholders only as an example, not as the label.

```html
<label for="email">Email</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<label for="password">Password</label>
<input type="password" id="password" name="password" autocomplete="new-password"
       minlength="8" required aria-describedby="password-hint">
<p class="hint" id="password-hint">At least 8 characters.</p>
```

### A11Y-03 · High · Duplicate `id="email"` on two inputs
**WCAG:** 4.1.1 Parsing (A, in WCAG 2.1; removed in 2.2 but still breaks 1.3.1 and 4.1.2 in practice)
**Location:** Password input reuses `id="email"`
**Issue:** IDs must be unique. Any `<label for="email">`, `aria-describedby`, or script lookup binds to the first match only. The password field can never receive a correct label while this remains.
**Fix:** Rename to `id="password"` (included in the A11Y-02 fix above).

### A11Y-04 · High · Focus indicator removed globally
**WCAG:** 2.4.7 Focus Visible (AA), 2.4.11 Focus Not Obscured (AA, 2.2), 2.4.13 Focus Appearance (AAA)
**Location:** `:focus { outline: none; }`
**Issue:** No replacement focus style is defined, so no element on the page shows where keyboard focus is.
**Impact:** Keyboard users cannot tell which field or control is active.
**Fix:** Delete the rule. If a custom ring is wanted, scope it to `:focus-visible` and keep it at least 2px with 3:1 contrast against adjacent colours.

```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

### A11Y-05 · High · Positive `tabindex` breaks focus order
**WCAG:** 2.4.3 Focus Order (A)
**Location:** `<a href="/terms" tabindex="3">`
**Issue:** Positive tabindex values are focused before all natural-order elements, so the terms link becomes the first tab stop on the page, ahead of the email field and before the checkbox it relates to.
**Impact:** Confusing, out-of-sequence navigation. It also sets a precedent that will worsen as the page grows.
**Fix:** Remove the `tabindex` attribute. Links are focusable by default and the source order already places it sensibly after the checkbox.

### A11Y-06 · High · Logo image has no `alt` attribute
**WCAG:** 1.1.1 Non-text Content (A)
**Location:** `<img src="/img/logo-2024-final.png">`
**Issue:** With no `alt`, screen readers fall back to announcing the file name, "logo-2024-final.png".
**Fix:** If the logo identifies the site, give it the brand name: `alt="Swareco"` (assumed brand; substitute the real name). If it is purely decorative, use `alt=""`.

### A11Y-07 · Medium · Page language not declared
**WCAG:** 3.1.1 Language of Page (A)
**Location:** `<html>`
**Issue:** Without `lang`, screen readers use their default voice and may mispronounce content; translation tools and hyphenation also misbehave.
**Fix:** `<html lang="en">`

### A11Y-08 · Medium · Missing `autocomplete` on identity fields
**WCAG:** 1.3.5 Identify Input Purpose (AA)
**Location:** Email and password inputs
**Issue:** Fields that collect user information must expose their purpose so browsers and assistive tech can autofill and relabel them.
**Fix:** `autocomplete="email"` and `autocomplete="new-password"` (shown in A11Y-02).

### A11Y-09 · Medium · Password hint not associated with its field
**WCAG:** 3.3.2 Labels or Instructions (A)
**Location:** `<p class="hint">At least 8 characters.</p>`
**Issue:** The requirement is visually adjacent but not programmatically linked, so screen reader users in forms mode will skip it.
**Fix:** Add `id="password-hint"` and reference it with `aria-describedby` on the password input (shown in A11Y-02).

### A11Y-10 · Medium · No required-field marking and no error handling
**WCAG:** 3.3.1 Error Identification (A), 3.3.3 Error Suggestion (AA), 3.3.2 Labels or Instructions (A)
**Location:** Whole form
**Issue:** Nothing is marked `required`, the terms checkbox is not enforced, and `form.submit()` bypasses browser constraint validation entirely. The source contains no error message region. Assumption: any validation is server-side and its output is unknown; if the server redisplays the page with errors, those must be text, associated to the field, and announced.
**Fix:** Add `required` to all three inputs, `minlength="8"` to the password, and plan an inline error pattern (`aria-invalid="true"` plus an `aria-describedby` error message, with a focus move or live region on failed submit).

### A11Y-11 · Low · No viewport meta tag
**WCAG:** 1.4.4 Resize Text (AA), 1.4.10 Reflow (AA)
**Location:** `<head>`
**Issue:** Mobile browsers will render the page at a desktop width and shrink it, making text and targets tiny until the user pinch-zooms. Zoom is not blocked, so this is a usability defect more than a strict failure, but reflow at 320px will not happen.
**Fix:** `<meta name="viewport" content="width=device-width, initial-scale=1">`. Do not add `user-scalable=no` or `maximum-scale`.

### A11Y-12 · Low · No landmark structure
**WCAG:** 1.3.1 Info and Relationships (A), best practice
**Location:** `<body>`
**Issue:** The page has a heading but no `<main>` or `<header>`. Small today, but screen reader users rely on landmarks to jump to content, and the pattern should be set now.
**Fix:** Wrap the logo in `<header>` and the heading plus form in `<main>`.

### A11Y-13 · Low · Button target size is at the minimum
**WCAG:** 2.5.8 Target Size (Minimum) (AA, 2.2)
**Location:** `.btn { padding: 4px 8px; }`
**Issue:** At the default 16px font, the button is roughly 26 to 27px tall. That clears the 24px floor but is well under the 44px recommended for touch (2.5.5 AAA). Needs runtime measurement to confirm.
**Fix:** Increase to at least `padding: 10px 16px` and set `min-height: 44px`.

## What passes

| Check | Result |
|---|---|
| Body text `#222` on `#fff` | ≈15.9:1, passes AA and AAA |
| Hint text `#595959` on `#fff` at 14.4px | ≈7.0:1, passes AA and AAA |
| Button text `#fff` on `#0a58ca` | ≈6.4:1, passes AA for normal text |
| Terms checkbox | Correctly labelled by wrapping `<label>` |
| Link text "Read the terms" | Descriptive, makes sense out of context |
| `<title>` present | Passes 2.4.2, though "Sign up · Brand" would be more useful in tab lists |
| Single `<h1>` | Correct heading start |
| Font sizes in `rem` | Scales with user preferences |
| No `user-scalable=no` | Zoom is not blocked |

## Could not verify without a browser

- Actual placeholder contrast. Browser defaults are around 4.6:1 in Chromium but vary; irrelevant once real labels exist.
- Rendered button height for A11Y-13.
- Screen reader announcement of the checkbox and link in each AT and browser pairing.
- Server-side validation and error rendering (A11Y-10).
- Logo contrast and legibility against the white background.

## Out of scope but worth flagging

- **No `name` attributes on any input.** Even with a working submit button the form posts no data. This is a functional bug that blocks sign-up for everyone, not only assistive technology users.
- **JS-only submission** means the form is dead with scripts blocked or failed. The native `<button type="submit">` fix removes this dependency.
- **No show-password toggle** is a usability gap that disproportionately affects users with motor or cognitive impairments.

## Recommended remediation order

1. A11Y-01 and A11Y-02 together, including the `name` attributes. These unblock keyboard and screen reader users and fix the data-loss bug in one change.
2. A11Y-03, A11Y-04, A11Y-05: three one-line deletions or renames.
3. A11Y-06, A11Y-07, A11Y-08, A11Y-09: attribute additions, no layout impact.
4. A11Y-10 and A11Y-11: require a short design decision on error presentation and viewport.
5. A11Y-12 and A11Y-13: structural and visual polish.

## Corrected reference markup

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up · Swareco</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    label { display: block; margin-top: 1rem; }
    .btn { display: inline-block; padding: 10px 16px; min-height: 44px;
           background: #0a58ca; color: #fff; border: 0; font: inherit; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; }
  </style>
</head>
<body>
  <header><img src="/img/logo-2024-final.png" alt="Swareco"></header>
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

Re-test after the fix with a keyboard-only pass, one screen reader (NVDA with Firefox or VoiceOver with Safari), and an automated scan such as axe to confirm no regressions.
