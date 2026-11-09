# Accessibility Audit: Sign-up Page

## Critical Issues

### 1. Missing Focus Indicators
**Issue:** `:focus { outline: none; }` removes default focus outlines without replacement.
**Impact:** Keyboard users cannot identify which element has focus, making navigation impossible.
**WCAG:** 2.4.7 Focus Visible (Level AA)
**Fix:** Add visible focus styles (e.g., `outline: 2px solid blue;`)

### 2. Non-semantic Button
**Issue:** "Create account" is a `<div onclick>`, not a `<button>` element.
**Impact:** 
- Not keyboard accessible (cannot tab to or activate with Enter/Space)
- Not announced as a button to screen readers
- Missing form submission semantics
**WCAG:** 4.1.2 Name, Role, Value (Level A)
**Fix:** Use `<button type="submit">Create account</button>`

### 3. Missing Form Field Labels
**Issue:** Email and password inputs use only `placeholder` attributes, without associated `<label>` elements.
**Impact:** Screen reader users cannot identify field purposes reliably (placeholders disappear on input).
**WCAG:** 1.3.1 Info and Relationships (Level A)
**Fix:** Add `<label for="email">Email</label>` and `<label for="password">Password</label>`

### 4. Duplicate Input ID
**Issue:** Both email and password inputs have `id="email"`.
**Impact:** Labels and form references become ambiguous; JavaScript selectors may fail.
**Fix:** Change password input to `id="password"`

## Major Issues

### 5. Missing Image Alt Text
**Issue:** Logo image has no `alt` attribute.
**Impact:** Decorative status unknown; screen readers may announce a broken image.
**Assumption:** Logo is decorative for branding; if it's functional, it needs descriptive alt text.
**WCAG:** 1.1.1 Non-text Content (Level A)
**Fix:** Add `alt=""` if decorative, or descriptive text if functional

### 6. Insufficient Hint Text Association
**Issue:** "At least 8 characters" hint is not programmatically associated with the password field.
**Impact:** Screen reader users may miss the requirement; unclear which field it describes.
**WCAG:** 1.3.1 Info and Relationships (Level A)
**Fix:** Add `aria-describedby="password-hint"` to password input and `id="password-hint"` to the hint

### 7. Insufficient Color Contrast
**Issue:** Hint text (#595959) on white background fails WCAG AA contrast requirements (ratio ~3.1:1, needs 4.5:1).
**Impact:** Users with low vision cannot read the password requirement.
**WCAG:** 1.4.3 Contrast (Minimum) (Level AA)
**Fix:** Darken hint text to #333 or darker

## Minor Issues

### 8. Missing `lang` Attribute
**Issue:** No `lang` attribute on `<html>` tag.
**Assumption:** Page language is English.
**WCAG:** 3.1.1 Language of Page (Level A)
**Fix:** Add `<html lang="en">`

### 9. Explicit Tab Order on Link
**Issue:** "Read the terms" link has `tabindex="3"`, creating an explicit tab order.
**Impact:** Confusing keyboard navigation flow (users expect logical source-order navigation).
**WCAG:** 2.4.3 Focus Order (Level A)
**Fix:** Remove `tabindex`; rely on source order

### 10. Missing Form Submission Fallback
**Issue:** Form submission depends on JavaScript; no server-side fallback if JS fails.
**Assumption:** Form gracefully degrades without JS or backend handles submission.
**WCAG:** 2.1.1 Keyboard (Level A)
**Fix:** Use `<form action="/signup" method="post">` with `<button type="submit">`
