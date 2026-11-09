# Accessibility Audit: Sign-up Page

## Critical Issues (Must Fix)

### 1. Missing Alternative Text on Logo
**Location:** `<img src="/img/logo-2024-final.png">`
- Missing `alt` attribute required for screen readers
- **Fix:** Add `alt="Company Logo"` or descriptive alt text

### 2. Form Inputs Lack Associated Labels
**Locations:** Email and password inputs
- Both inputs use only `placeholder` attributes; no `<label>` elements
- Placeholders are not accessible alternatives to labels (they hide on input, aren't read consistently by screen readers)
- **Fix:** Add proper labels: `<label for="email">Email</label><input type="email" id="email">`

### 3. Duplicate ID on Password Field
**Location:** `<input type="password" placeholder="Password" id="email">`
- Password input has `id="email"` (same as email input) — invalid HTML
- **Fix:** Change to `id="password"`

### 4. Button Not Keyboard Accessible
**Location:** `<div class="btn" onclick="submitForm()">Create account</div>`
- Divs cannot receive keyboard focus by default; keyboard users cannot activate it
- Clicking with mouse is the only way to submit
- **Fix:** Use a native `<button>` element instead: `<button type="submit">Create account</button>`

### 5. Focus Outline Removed with No Alternative
**Location:** `:focus { outline: none; }`
- Removes the browser's default focus indicator
- Keyboard users cannot see which element is focused
- **Fix:** Remove the rule or provide a visible focus style (e.g., `outline: 2px solid #0a58ca;`)

### 6. Missing Language Attribute
**Location:** `<html>` tag
- No `lang` attribute; screen readers cannot determine page language
- **Fix:** Add `lang="en"` (assuming English)

## Serious Issues

### 7. Insufficient Color Contrast on Hint Text
**Location:** `.hint { color: #595959; }`
- Contrast ratio of gray text (#595959) on white background is ~2.9:1
- WCAG AA requires 4.5:1 for normal text; this fails
- **Fix:** Use darker gray like `#333` or similar (achieves ~12:1 contrast)

### 8. Programmatic Association Missing for Hint Text
**Location:** Password field and `.hint` paragraph
- Hint "At least 8 characters" is not linked to the password input
- Hint should be associated using `aria-describedby`
- **Fix:** Add `aria-describedby="pwd-hint"` to password input; add `id="pwd-hint"` to hint paragraph

### 9. Unclear Tab Order
**Location:** `tabindex="3"` on "Read the terms" link
- Positive tabindex values disrupt natural tab order (should only use 0 or -1)
- At only 3 focusable elements, tabindex="3" is confusing
- **Fix:** Remove the `tabindex` attribute to use natural tab order

## Assumptions Made
- Page language is English
- Logo is a company branding image
- Form has no required field indicators, assuming none are required
- Form does not validate or display errors (cannot audit missing patterns)
