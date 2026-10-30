# Accessibility Audit: Sign-Up Page

## Critical Issues (WCAG 2.1 Level A)

### 1. Missing Image Alt Text
**Issue:** Logo has no `alt` attribute: `<img src="/img/logo-2024-final.png">`
- **Impact:** Screen reader users cannot understand the logo's purpose
- **Fix:** Add `alt="Company Logo"` or appropriate descriptive text
- **WCAG:** 1.1.1 Non-text Content (Level A)

### 2. Focus Indicator Removed Without Replacement
**Issue:** CSS rule `:focus { outline: none; }` removes focus styling
- **Impact:** Keyboard users cannot see which element has focus; breaks keyboard navigation visibility
- **Fix:** Remove the rule or replace with visible focus styling (e.g., `outline: 2px solid #0a58ca;`)
- **WCAG:** 2.4.7 Focus Visible (Level AA)

### 3. Duplicate Element IDs
**Issue:** Both password input and email input have `id="email"`:
```html
<input type="email" placeholder="Email" id="email">
<input type="password" placeholder="Password" id="email">
```
- **Impact:** Violates HTML specification; JavaScript selectors will only select first element; screen readers may misidentify elements
- **Fix:** Change password field to `id="password"`
- **WCAG:** 1.3.1 Info and Relationships (Level A)

### 4. Non-Semantic Button Element
**Issue:** Submit button is a div: `<div class="btn" onclick="submitForm()">Create account</div>`
- **Impact:** Not keyboard accessible (Tab+Enter won't work); screen readers don't announce as button; not accessible to assistive technology
- **Fix:** Use `<button type="submit">Create account</button>`
- **WCAG:** 2.1.1 Keyboard (Level A), 4.1.2 Name, Role, Value (Level A)

## Major Issues (WCAG 2.1 Level AA)

### 5. Missing Associated Labels for Form Inputs
**Issue:** Email and password fields lack `<label>` elements; only have `placeholder` attributes
```html
<input type="email" placeholder="Email" id="email">
<input type="password" placeholder="Password" id="email">
```
- **Impact:** Screen reader users won't know field purposes; placeholders disappear on focus; no persistent label
- **Fix:** Add labels:
```html
<label for="email">Email</label>
<input type="email" id="email">
<label for="password">Password</label>
<input type="password" id="password">
```
- **WCAG:** 1.3.1 Info and Relationships (Level A), 3.3.2 Labels or Instructions (Level A)

### 6. Unassociated Hint Text
**Issue:** Password hint "At least 8 characters" is not programmatically linked to the password field
- **Impact:** Screen reader users won't know the hint applies to password field
- **Fix:** Add `aria-describedby="password-hint"` to password input and `id="password-hint"` to hint paragraph

### 7. Broken Tab Order
**Issue:** "Read the terms" link has `tabindex="3"` with no corresponding tab order for form fields
- **Impact:** Tab key navigation order is unclear and likely illogical
- **Fix:** Remove explicit `tabindex` values; let natural source order (or use `tabindex="0"`) determine order

### 8. Missing Form Action
**Issue:** `<form id="signup">` has no `action` attribute
- **Impact:** Unclear where form data goes; reduces semantic meaning
- **Fix:** Add `action` attribute (e.g., `action="/api/signup"`) or ensure JavaScript handles it with clear feedback

## Minor Issues

### 9. No Required Field Indicators
**Issue:** No indication which fields are required
- **Impact:** Users, especially those using screen readers, may not know all fields must be completed
- **Fix:** Add `required` attribute to inputs and mark labels with asterisk or similar

### 10. Missing Form Validation/Error Handling
**Issue:** No visible error messages or validation feedback
- **Impact:** If form submission fails, users won't know why
- **Fix:** Implement and announce validation errors with ARIA live regions for dynamic updates

---

## Summary
| Priority | Count |
|----------|-------|
| **Critical** | 4 |
| **Major** | 4 |
| **Minor** | 2 |

**Overall WCAG Compliance:** Fails Level A (due to critical issues #1, #3, #4 and #5)
