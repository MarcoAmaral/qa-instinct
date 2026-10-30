# Accessibility Audit: Sign-up Page

## Critical Issues

### 1. Focus Indicators Removed
- **Location:** `style` tag, `:focus { outline: none; }`
- **Issue:** Removes visible focus indicators, preventing keyboard users from seeing which element is focused
- **Impact:** WCAG 2.1 Level AA violation (2.4.7 Focus Visible)
- **Fix:** Remove this rule or replace with a visible focus style (e.g., `outline: 2px solid #0a58ca`)

### 2. Logo Image Missing Alt Text
- **Location:** `<img src="/img/logo-2024-final.png">`
- **Issue:** No alt attribute; screen readers cannot describe the image
- **Impact:** WCAG 2.1 Level A violation (1.1.1 Non-text Content)
- **Fix:** Add `alt="Company Logo"` or similar descriptive text

### 3. "Create Account" Button Not Keyboard Accessible
- **Location:** `<div class="btn" onclick="submitForm()">Create account</div>`
- **Issue:** A div cannot receive keyboard focus by default; users navigating by keyboard cannot activate it
- **Impact:** WCAG 2.1 Level A violation (2.1.1 Keyboard)
- **Fix:** Change to `<button type="submit">Create account</button>` and remove the inline onclick script

### 4. Duplicate Input IDs
- **Location:** Password input has `id="email"` (same as email input)
- **Issue:** Duplicate IDs break form association and programmatic access
- **Impact:** WCAG 2.1 Level A violation (4.1.1 Parsing)
- **Fix:** Change password input to `id="password"`

## Major Issues

### 5. Missing Form Labels
- **Location:** Email and password inputs
- **Issue:** Only placeholders; no `<label>` elements. Placeholders disappear when typing, leaving no persistent label for screen reader users
- **Impact:** WCAG 2.1 Level A violation (1.3.1 Info and Relationships; 3.3.2 Labels or Instructions)
- **Fix:** Add `<label for="email">Email</label>` and `<label for="password">Password</label>`

### 6. Hint Text Not Associated with Input
- **Location:** `<p class="hint">At least 8 characters.</p>` after password input
- **Issue:** No semantic link between hint and password field; screen readers won't announce it as related
- **Impact:** WCAG 2.1 Level A violation (1.3.1 Info and Relationships)
- **Fix:** Move hint inside label or add `aria-describedby="pwd-hint"` to password input and `id="pwd-hint"` to hint

### 7. Unusual Tabindex Value
- **Location:** `<a href="/terms" tabindex="3">Read the terms</a>`
- **Issue:** Explicit tabindex="3" disrupts logical tab order. Avoid explicit positive tabindex values
- **Impact:** WCAG 2.1 Level A violation (2.4.3 Focus Order)
- **Fix:** Remove `tabindex="3"` to follow document order

## Minor Issues

### 8. Missing Required Attributes
- **Location:** Email and password inputs
- **Issue:** No `required` attribute; screen readers won't announce these as mandatory
- **Fix:** Add `required` attribute: `<input type="email" required>`

### 9. Insufficient Color Contrast (Borderline)
- **Location:** `.hint` text with `color: #595959` on white background
- **Issue:** Contrast ratio ~4.9:1 (just above 4.5:1 minimum for normal text; below 7:1 for enhanced contrast)
- **Fix:** Darken hint text to `#333333` or similar for better readability

### 10. Missing Form Attributes
- **Location:** `<form id="signup">`
- **Issue:** No `method` or `action` attributes; unclear where form submits
- **Fix:** Add `method="POST" action="/signup"` or equivalent

## Summary

**Accessibility Level:** Does not meet WCAG 2.1 Level A  
**Critical Blockers:** 4 (focus indicators, alt text, button keyboard access, duplicate IDs)  
**Major Fixes Needed:** 4 (form labels, hint association, tabindex, required attributes)  
**Estimated Remediation:** 30 minutes

**Assumption:** The page is in English and does not require language declaration (though `<html lang="en">` is recommended).
