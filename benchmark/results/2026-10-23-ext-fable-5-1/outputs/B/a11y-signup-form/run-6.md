# Accessibility Audit: Sign-up Page (`Sign up`)

**Standard:** WCAG 2.2 Level AA (with 2.1 mapping where relevant)
**Method:** Static review of HTML/CSS/JS source only. No browser, screen reader, or automated scanner was run. Contrast ratios were computed from the hex values in the stylesheet.
**Result:** **Fail.** Six Level A/AA failures, two of which make the form impossible to complete with a keyboard or a screen reader.

## Scope and assumptions

- The markup shown is the entire page. No external CSS, JS, or framework overrides exist.
- The page language is English.
- The logo is the company's brand mark and is the only visual identification of the site on the page. It is therefore informative, not decorative.
- Both fields and the terms checkbox are intended to be mandatory.
- The form is intended to POST to a server endpoint. The missing `action`/`method` is treated as a placeholder, not a design decision.
- "Default browser rendering" refers to current Chrome, Firefox, and Safari; placeholder colour and focus ring defaults vary by browser.

## Summary

| # | Finding | WCAG | Severity |
|---|---------|------|----------|
| 1 | Submit control is a `div` with `onclick`; not focusable, no role, no name, and Enter does not submit the form | 2.1.1, 4.1.2 | Critical |
| 2 | Inputs rely on `placeholder` as their only label | 1.3.1, 3.3.2, 4.1.2 | Critical |
| 3 | All focus indicators removed with `:focus { outline: none }` | 2.4.7 | High |
| 4 | Duplicate `id="email"` on the email and password inputs | 1.3.1, 4.1.2 (4.1.1 in 2.1) | High |
| 5 | `tabindex="3"` on the terms link breaks focus order | 2.4.3 | High |
| 6 | Logo `img` has no `alt` attribute | 1.1.1 | High |
| 7 | No `lang` attribute on `html` | 3.1.1 | Medium |
| 8 | Password hint not programmatically associated with the field | 3.3.2 | Medium |
| 9 | No `required`, no `autocomplete`, no error handling; script submit bypasses constraint validation | 1.3.5, 3.3.1, 3.3.3 | Medium |
| 10 | No viewport meta tag | 1.4.10 (risk) | Medium |
| 11 | Submit control target height is borderline at ~24–27 px | 2.5.8 | Low |
| 12 | No landmarks; form has no accessible name; page title lacks site context | Best practice | Low |

## Findings

### 1. Submit control is not a button (Critical)

**Evidence**
```html
<div class="btn" onclick="submitForm()">Create account</div>
```

**Impact**
- The `div` is not in the tab order. Keyboard users cannot reach it.
- It has no `role`, so screen readers announce it as plain text, not as a button.
- Pressing Enter inside a field will **not** submit. The HTML implicit-submission rule only fires when a form has a submit button or at most one text-like field; this form has two (`email` and `password`) and no submit button. So there is no keyboard path to submission at all.
- Voice control users cannot say "click Create account" because there is no named control.

**WCAG** 2.1.1 Keyboard (A), 4.1.2 Name, Role, Value (A).

**Fix** Replace with a native button. This also removes the need for the inline script.
```html
<button type="submit" class="btn">Create account</button>
```

### 2. Placeholder used as the only label (Critical)

**Evidence**
```html
<input type="email" placeholder="Email" id="email">
<input type="password" placeholder="Password" id="email">
```

**Impact**
- The placeholder disappears once the user types, so sighted users lose the field's purpose mid-entry. This is worst on the password field, where the typed value is masked and gives no clue.
- Screen reader support for placeholder-as-name is inconsistent. Some combinations announce it, some do not. It is not a reliable accessible name.
- Default placeholder colours in Firefox and Safari fall below 4.5:1, so the only visible label may also fail 1.4.3.

**WCAG** 1.3.1 Info and Relationships (A), 3.3.2 Labels or Instructions (A), 4.1.2 Name, Role, Value (A).

**Fix** Add visible `label` elements. Placeholders may stay as examples, not labels.
```html
<label for="email">Email</label>
<input type="email" id="email" name="email" autocomplete="email" required>
```

### 3. Focus indicator removed globally (High)

**Evidence**
```css
:focus { outline: none; }
```

**Impact** No element on the page shows focus. Sighted keyboard users cannot tell where they are. No replacement style is defined anywhere. This is a page-wide failure, not a single-control one.

**WCAG** 2.4.7 Focus Visible (AA). Would also fail 2.4.13 Focus Appearance (AAA) if targeted.

**Fix** Delete the rule. If the goal was to hide outlines for mouse clicks, use `:focus-visible` to keep keyboard focus styling.
```css
:focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
```

### 4. Duplicate `id="email"` (High)

**Evidence** Both the email and password inputs carry `id="email"`.

**Impact**
- Any `label for="email"` or `aria-describedby="email"` will bind to the first element only, so the password field can never be labelled by reference. This blocks the fix for finding 2 until corrected.
- `getElementById("email")` in any script will silently return the wrong element for the password case.
- Invalid DOM; assistive technology behaviour with duplicate IDs is undefined.

**WCAG** 1.3.1 (A), 4.1.2 (A). Also 4.1.1 Parsing under WCAG 2.1.

**Fix** Rename the second to `id="password"`.

### 5. Positive `tabindex` breaks focus order (High)

**Evidence**
```html
<a href="/terms" tabindex="3">Read the terms</a>
```

**Impact** Elements with a positive `tabindex` are visited before all elements with `tabindex="0"` or natural order. The resulting Tab sequence is:

1. "Read the terms" link
2. Email
3. Password
4. Terms checkbox
5. (Nothing. The submit `div` is unreachable.)

A keyboard user lands on the terms link before the first field, which contradicts the visual order. Screen reader users navigating by Tab hear "Read the terms" before they know what form they are in.

**WCAG** 2.4.3 Focus Order (A).

**Fix** Remove `tabindex="3"`. Natural DOM order already matches the visual order.

### 6. Logo has no text alternative (High)

**Evidence**
```html
<img src="/img/logo-2024-final.png">
```

**Impact** With no `alt` attribute, screen readers typically announce the file name: "logo-2024-final.png, image". The user does not learn which company or product they are signing up for.

**WCAG** 1.1.1 Non-text Content (A).

**Fix** Under the assumption that the logo identifies the site, use the brand name as the text alternative. If a separate visible site name is added, make the image decorative instead with `alt=""`.
```html
<img src="/img/logo-2024-final.png" alt="Acme">
```

### 7. Missing `lang` attribute (Medium)

**Evidence** `<html>` has no `lang`.

**Impact** Screen readers may use the wrong pronunciation rules. Browser translation prompts and hyphenation also depend on it.

**WCAG** 3.1.1 Language of Page (A).

**Fix** `<html lang="en">`.

### 8. Password hint not associated with the field (Medium)

**Evidence**
```html
<input type="password" placeholder="Password" id="email">
<p class="hint">At least 8 characters.</p>
```

**Impact** The hint is visually adjacent but programmatically unrelated. A screen reader user who Tabs directly to the password field never hears the requirement. Visual contrast of the hint is fine (7.0:1 for `#595959` on white).

**WCAG** 3.3.2 Labels or Instructions (A).

**Fix** Give the hint an `id` and reference it with `aria-describedby` on the input. Also enforce it with `minlength="8"` so the rule and the behaviour agree.

### 9. No required marking, no autocomplete, no error handling (Medium)

**Evidence**
- No `required` on any field. No `minlength` on password.
- No `autocomplete` on email or password.
- `submitForm()` calls `form.submit()`, which bypasses HTML constraint validation entirely, so even added `required` attributes would be ignored.
- No error message region or pattern exists for server-side errors.

**Impact**
- Users are not told which fields are mandatory. Submission of an empty form is possible.
- Password managers and browser autofill cannot reliably identify the fields. `autocomplete="email"` and `autocomplete="new-password"` are also a 1.3.5 requirement for fields collecting personal data.
- If the server rejects the submission, there is no accessible mechanism to identify the error.

**WCAG** 1.3.5 Identify Input Purpose (AA), 3.3.1 Error Identification (A), 3.3.3 Error Suggestion (AA). 3.3.1 and 3.3.3 are currently unmet rather than failed, because no error path exists at all. They will become failures as soon as the server returns any error.

**Fix** Add `required`, `minlength`, and `autocomplete`. Use a native submit button so constraint validation runs. Add a live region for server-side errors and link each error to its field with `aria-describedby` and `aria-invalid="true"`.

### 10. No viewport meta tag (Medium)

**Evidence** `head` contains no `<meta name="viewport">`.

**Impact** Mobile browsers render the page at a desktop width (typically 980 px) and scale it down. Text becomes small and the user must zoom to operate controls. Reflow to a 320 px viewport does not happen.

**WCAG** 1.4.10 Reflow (AA). Flagged as a risk rather than a confirmed failure because the content is narrow enough that it may still fit after scaling.

**Fix** `<meta name="viewport" content="width=device-width, initial-scale=1">`. Do not add `user-scalable=no` or a `maximum-scale`.

### 11. Submit target size is borderline (Low)

**Evidence** `.btn { padding: 4px 8px }` on an inline-block with default 16 px font.

**Impact** Estimated rendered height is roughly 24 to 27 px depending on line-height. WCAG 2.2 requires 24 x 24 CSS px minimum. It likely passes, but with no margin, and inline-block sizing varies by font. The checkbox itself is about 13 px, but it is wrapped in a `label`, so the full label text counts as the target. That passes.

**WCAG** 2.5.8 Target Size (Minimum) (AA).

**Fix** Set an explicit `min-height: 44px` or at least `padding: 10px 16px` on the button. This also improves usability on touch.

### 12. Structure and naming gaps (Low, best practice)

- No `main` landmark. Screen reader users have no landmark to jump to. Low impact on a single-purpose page, but trivial to add.
- The `form` has no accessible name. `aria-labelledby` pointing at the `h1` gives it one.
- Page title "Sign up" lacks the site name. 2.4.2 passes as written, but "Sign up – Acme" is more useful across browser tabs and history.
- No `name` attributes on inputs, so nothing is actually submitted. Functional rather than accessibility bug.
- No `cursor: pointer` on the fake button. Moot once it becomes a real button.

## Items checked that pass or do not apply

| Check | Result |
|-------|--------|
| Body text contrast `#222` on `#fff` | Pass, 16.4:1 |
| Button text `#fff` on `#0a58ca` | Pass, 6.4:1 |
| Hint text `#595959` on `#fff` | Pass, 7.0:1 (AA and AAA) |
| Heading structure | Pass, single `h1` describing the page |
| Checkbox labelled | Pass, wrapped in `label` |
| Page title present | Pass |
| Skip link (2.4.1) | Not applicable, no repeated blocks |
| Accessible Authentication (3.3.8) | Not applicable, account creation is not an authentication step. No paste blocking present. |
| Motion, audio, timing | Not applicable, none present |
| Link text "Read the terms" | Pass, descriptive out of context |

## Out of scope but worth raising

- The form has no `method`, so it submits via GET. The password would appear in the URL, server logs, and browser history. Add `method="post"` before shipping regardless of the accessibility work.

## Remediated markup

This version resolves findings 1 through 12. Brand name and form action are placeholders.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up – Acme</title>
  <style>
    body { font-family: sans-serif; color: #222; background: #fff; }
    label { display: block; margin-top: 1rem; }
    .btn { display: inline-block; padding: 10px 16px; min-height: 44px;
           background: #0a58ca; color: #fff; border: 0; font: inherit; cursor: pointer; }
    :focus-visible { outline: 3px solid #0a58ca; outline-offset: 2px; }
    .hint { color: #595959; font-size: 0.9rem; margin: 0.25rem 0 0; }
    .error { color: #b3261e; }
  </style>
</head>
<body>
  <header>
    <img src="/img/logo-2024-final.png" alt="Acme">
  </header>
  <main>
    <h1 id="signup-heading">Create your account</h1>
    <form id="signup" method="post" action="/signup" aria-labelledby="signup-heading" novalidate>
      <div id="form-errors" class="error" role="alert" aria-live="assertive"></div>

      <label for="email">Email</label>
      <input type="email" id="email" name="email" autocomplete="email" required>

      <label for="password">Password</label>
      <input type="password" id="password" name="password"
             autocomplete="new-password" required minlength="8"
             aria-describedby="password-hint">
      <p class="hint" id="password-hint">At least 8 characters.</p>

      <label>
        <input type="checkbox" id="terms" name="terms" required>
        I accept the terms
      </label>
      <a href="/terms">Read the terms</a>

      <p><button type="submit" class="btn">Create account</button></p>
    </form>
  </main>
</body>
</html>
```

Note on `novalidate`: include it only if custom, accessible inline error messages are implemented in script. Otherwise omit it and rely on native browser validation, which is accessible by default.

## Verification steps after remediation

1. **Keyboard only.** Tab from page load. Expected order: Email, Password, checkbox, "Read the terms", "Create account". Every stop shows a visible ring. Enter on the button and Enter inside either field both submit.
2. **Screen reader.** NVDA with Firefox and VoiceOver with Safari. Confirm the logo reads as the brand name, each field announces its label and (for password) the hint, the checkbox announces checked state, and the submit announces as "button".
3. **Empty submit.** Submit with no input. Confirm each required field is identified and focus moves to the first error.
4. **Zoom and reflow.** 400% zoom on desktop and a 320 px wide viewport. No horizontal scrolling, nothing clipped.
5. **Automated scan.** Run axe-core or Lighthouse. Expected: zero violations. Treat this as a floor, not a sign-off.
6. **Validate markup.** W3C validator. Expected: no duplicate ID errors.
