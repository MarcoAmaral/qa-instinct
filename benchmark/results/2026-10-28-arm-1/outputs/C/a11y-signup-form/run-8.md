# Accessibility Audit: Sign-up Page

## Critical Issues

### 1. Non-semantic button element
**Issue:** The submit control is a `<div>` with an `onclick` handler, not a `<button>`.

**Impact:** 
- Keyboard users cannot submit the form (no Enter key support)
- Screen readers don't announce it as a button or describe its action
- Cannot be focused or activated by assistive technology

**Fix:** Replace `<div class="btn" onclick="submitForm()">Create account</div>` with `<button class="btn">Create account</button>` and remove the JavaScript handler.

---

### 2. Focus outline removed without alternative
**Issue:** `:focus { outline: none; }` removes the default focus indicator.

**Impact:** Keyboard users cannot see which element has focus.

**Fix:** Remove this rule entirely or replace with a visible focus style:
```css
:focus {
  outline: 2px solid #0a58ca;
  outline-offset: 2px;
}
```

---

### 3. Inputs lack associated labels
**Issue:** Email and password inputs use only `placeholder` text; there are no `<label>` elements.

**Impact:** 
- Screen reader users don't know what the fields are
- Placeholders disappear when typing; inaccessible for users who can't remember the field purpose
- Clicking the label won't focus the field (doesn't exist)

**Fix:** Add labels and link them:
```html
<label for="email">Email</label>
<input type="email" id="email" placeholder="Email">

<label for="password">Password</label>
<input type="password" id="password" placeholder="Password">
```

---

### 4. Duplicate input ID
**Issue:** Both inputs have `id="email"`.

**Impact:** Violates HTML specification; IDs must be unique. Behavior when duplicated is undefined.

**Fix:** Change the password input ID to `id="password"`.

---

## Major Issues

### 5. Password constraint not associated with input
**Issue:** The text "At least 8 characters." is a `<p>` tag without any connection to the password field.

**Impact:** Screen reader users won't know this constraint applies to the password, or even know it exists.

**Fix:** Add `aria-describedby="password-hint"` to the password input and add `id="password-hint"` to the hint paragraph:
```html
<input type="password" id="password" aria-describedby="password-hint">
<p id="password-hint" class="hint">At least 8 characters.</p>
```

---

### 6. Logo image lacks alt text
**Issue:** `<img src="/img/logo-2024-final.png">` has no `alt` attribute.

**Impact:** Screen reader users hear only the filename, or nothing. If the logo is decorative, they should be told.

**Fix (if decorative):** `<img src="/img/logo-2024-final.png" alt="">`

**Fix (if meaningful):** `<img src="/img/logo-2024-final.png" alt="Company name">`

---

### 7. Confusing tab order
**Issue:** The link has `tabindex="3"`, creating an explicit tab order. Form inputs (which come before it in the HTML and have no tabindex) will be jumped over.

**Impact:** Keyboard navigation is unpredictable.

**Fix:** Remove `tabindex="3"`. HTML source order determines focus order for elements without explicit tabindex; place the link after the checkbox if it should come last.

---

## Minor Issues

### 8. Form missing method and action
**Issue:** The `<form>` has no `method` or `action` attribute.

**Assumption:** Assuming the form will be handled by JavaScript or a framework.

**Fix:** Add `method="POST"` and `action="/signup"` (or actual endpoint) so the form degrades gracefully.

---

## Summary

| Severity | Count | Issues |
|----------|-------|--------|
| Critical | 4 | Non-semantic button, removed focus outline, missing labels, duplicate ID |
| Major | 3 | Unassociated hint, missing alt text, confusing tab order |
| Minor | 1 | Missing form attributes |

**WCAG Level:** Currently fails Level A. Fixes address Level A and Level AA requirements.

**Keyboard accessibility:** Currently unusable without a mouse. The non-semantic button and removed focus indicator make it impossible for keyboard users to submit.

**Screen reader accessibility:** Required information (field purpose, password constraints) is absent or inaccessible; form structure is unclear.
