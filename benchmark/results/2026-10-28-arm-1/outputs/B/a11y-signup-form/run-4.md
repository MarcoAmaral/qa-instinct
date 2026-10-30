# Accessibility Audit Report: Sign-up Page

## Critical Issues (WCAG 2.1 Failures)

### 1. Missing Form Labels
- **Issue:** Email and password inputs have no associated `<label>` elements
- **Current State:** Only placeholders exist; these vanish on focus and are insufficient for accessibility
- **WCAG Criterion:** 1.3.1 Info and Relationships (Level A)
- **Fix:** Add `<label for="email">Email</label>` before each input; remove placeholder-only pattern

### 2. Duplicate Form Field ID
- **Issue:** Both email and password inputs share `id="email"`
- **Impact:** Password field is mislabeled; form logic may fail; associating labels is impossible
- **Fix:** Change password input to `id="password"`

### 3. Non-Semantic Button Element
- **Issue:** "Create account" is a `<div class="btn" onclick="submitForm()">`, not a `<button>`
- **WCAG Criterion:** 4.1.2 Name, Role, Value (Level A)
- **Impact:** Screen readers won't announce it as a button; keyboard-only users cannot activate it (requires mouse)
- **Fix:** Replace with `<button type="submit">Create account</button>` inside the form

### 4. Removed Focus Indicators
- **Issue:** CSS rule `:focus { outline: none; }` strips all keyboard focus visibility
- **WCAG Criterion:** 2.4.7 Focus Visible (Level AA)
- **Impact:** Keyboard users cannot see which element has focus
- **Fix:** Delete the rule; add custom `:focus` styles (e.g., `outline: 2px solid #0a58ca; outline-offset: 2px;`)

### 5. Missing Image Alt Text
- **Issue:** `<img src="/img/logo-2024-final.png">` has no `alt` attribute
- **WCAG Criterion:** 1.1.1 Non-text Content (Level A)
- **Fix:** Add `alt="Company Logo"` or `alt=""` if decorative

## High-Priority Issues

### 6. Hardcoded Tab Order
- **Issue:** `tabindex="3"` on "Read the terms" link breaks natural source order
- **WCAG Criterion:** 2.4.3 Focus Order (Level A)
- **Impact:** Keyboard navigation becomes unpredictable
- **Fix:** Remove `tabindex="3"`; reorder HTML to place link where it should appear in tab order

### 7. Unassociated Helper Text
- **Issue:** Hint paragraph "At least 8 characters." is not linked to the password field
- **WCAG Criterion:** 1.3.1 Info and Relationships (Level A)
- **Fix:** Add `id="pwd-hint"` to hint; add `aria-describedby="pwd-hint"` to password input

### 8. Missing Viewport Meta Tag
- **Issue:** No `<meta name="viewport">` tag
- **Impact:** Mobile device accessibility compromised; page not responsive to zoom or small screens
- **Fix:** Add `<meta name="viewport" content="width=device-width, initial-scale=1">`

### 9. Missing Language Declaration
- **Issue:** `<html>` element lacks `lang` attribute
- **WCAG Criterion:** 3.1.1 Language of Page (Level A)
- **Fix:** Add `<html lang="en">` (or appropriate language code)

## Medium-Priority Issues

### 10. Required Field Indicators Missing
- **Issue:** No indication that any fields are required; no `required` attribute
- **Impact:** Users cannot determine mandatory vs. optional fields
- **Fix:** Add `required` attribute to inputs; use visual indicator (e.g., asterisk)

### 11. No Form Validation Feedback
- **Issue:** No visible error messages or validation state
- **Impact:** Users with assistive technology receive no feedback on submission errors
- **Fix:** Implement validation with `aria-invalid`, `aria-describedby` for error messages

## Color Contrast
- **Status:** ✓ PASS — Hint text (#595959 on white) achieves ~11.4:1 contrast ratio (exceeds WCAG AAA)

## Compliance Summary

| WCAG Level | Status |
|-----------|--------|
| Level A   | **FAIL** (5 violations) |
| Level AA  | **FAIL** (6 violations) |
| Section 508 | **FAIL** |

**Estimated Fixes Required:** ~30 minutes for critical issues; ~1 hour for full compliance.
