# Accessibility Audit: Sign-up Page

## Critical Issues

### 1. Missing Alt Text on Logo Image
**Location:** Line 21  
**Issue:** `<img src="/img/logo-2024-final.png">` has no `alt` attribute.  
**Impact:** Screen reader users cannot identify the logo or its purpose.  
**Fix:** Add `alt="Company logo"` (or appropriate description).

### 2. Duplicate Input IDs
**Location:** Lines 24–25  
**Issue:** Both email and password inputs have `id="email"`.  
**Impact:** JavaScript and labels cannot reliably target the correct field.  
**Fix:** Change the password input's ID to `id="password"`.

### 3. Focus Outline Removed
**Location:** Line 7, `:focus { outline: none; }`  
**Issue:** All focused elements lose their visual outline.  
**Impact:** Keyboard users cannot see which control is active.  
**Fix:** Remove this rule or replace it with a visible focus style, e.g., `outline: 2px solid #0a58ca; outline-offset: 2px;`.

### 4. Non-Semantic Button
**Location:** Line 28, `<div class="btn" onclick="submitForm()">Create account</div>`  
**Issue:** A `<div>` styled as a button is not keyboard accessible and not announced as a button.  
**Impact:** Keyboard users cannot activate it; screen readers do not identify it as interactive.  
**Fix:** Replace with `<button type="submit">Create account</button>` and remove the script wrapper.

## Major Issues

### 5. Password Input Label Only in Placeholder
**Location:** Line 25  
**Issue:** Password input has only a placeholder; no `<label>` element.  
**Impact:** Placeholder disappears when the user types; screen readers have no label.  
**Fix:** Add `<label for="password">Password</label>` before the input.

### 6. Hint Text Not Associated with Input
**Location:** Line 26, `<p class="hint">At least 8 characters.</p>`  
**Issue:** The hint is not linked to the password field.  
**Impact:** Screen reader users may not associate the hint with the password requirement.  
**Fix:** Add `id="pwd-hint"` to the `<p>` and `aria-describedby="pwd-hint"` to the password input.

### 7. Missing Language Attribute
**Location:** Line 2, `<html>`  
**Issue:** No `lang` attribute.  
**Impact:** Screen readers cannot select the correct language.  
**Fix:** Add `<html lang="en">` (or appropriate language code).

### 8. Unusual Tab Order
**Location:** Line 27, `<a href="/terms" tabindex="3">Read the terms</a>`  
**Issue:** `tabindex="3"` manually sets tab order out of sequence.  
**Impact:** Keyboard navigation becomes unpredictable.  
**Fix:** Remove `tabindex="3"` and rely on natural DOM order.

## Minor Issues

### 9. Insufficient Color Contrast
**Location:** Line 6, `.hint { color: #595959; }`  
**Issue:** Gray hint text (#595959) on white background may not meet WCAG AA contrast ratio (4.5:1 for normal text).  
**Impact:** Low-vision users may struggle to read the hint.  
**Fix:** Use a darker color (e.g., `#3a3a3a` or test with a contrast checker).

### 10. No Email Label
**Location:** Line 24, `<input type="email" placeholder="Email" id="email">`  
**Issue:** Email input also lacks a visible or associated label.  
**Impact:** Less clear for all users; screen reader users have no label.  
**Fix:** Add `<label for="email">Email</label>` before the input.

### 11. No Form Feedback After Submit
**Location:** Script at line 30–31  
**Issue:** After form submission, no visual or announced feedback confirms success or failure.  
**Impact:** Users with screen readers or visual impairments cannot confirm the form submitted.  
**Fix:** Add a success message or redirect with an announcement.

---

## Summary of Assumptions
- The form submits to a server endpoint; the backend validates and responds.
- "Company logo" is assumed as the alt text; the actual company name should be substituted.
- The form is in English; `lang="en"` is assumed.
- The page should meet WCAG 2.1 Level AA accessibility standards.
