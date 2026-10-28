# Accessibility Audit: Sign-Up Page

## Critical Issues

### 1. **Focus Indicator Removed**
**Severity:** Critical  
**Issue:** CSS rule `:focus { outline: none; }` removes all keyboard focus indicators.  
**Impact:** Keyboard users cannot see which element has focus, making navigation impossible.  
**WCAG Criterion:** 2.4.7 Focus Visible (Level AA)  
**Recommendation:** Remove this rule and provide a visible focus indicator via outline, box-shadow, or border.

### 2. **Button Not Keyboard Accessible**
**Severity:** Critical  
**Issue:** "Create account" is a `<div class="btn">` with `onclick` handler, not a `<button>` element.  
**Impact:** 
- Not focusable with Tab key
- Not announced as a button to screen readers
- Cannot be activated via Enter or Space keys
- Complete keyboard navigation failure for form submission

**WCAG Criterion:** 2.1.1 Keyboard (Level A), 4.1.2 Name, Role, Value (Level A)  
**Recommendation:** Replace with `<button type="submit" class="btn">Create account</button>` inside the form.

### 3. **Duplicate ID Attribute**
**Severity:** Critical  
**Issue:** Both email and password inputs have `id="email"`.  
**Impact:** Invalid HTML; associated labels/aria-describedby references will fail; JavaScript getElementById will only target the first element.  
**WCAG Criterion:** 4.1.1 Parsing (Level A)  
**Recommendation:** Change password input to `id="password"`.

## Major Issues

### 4. **Missing Form Labels**
**Severity:** Major  
**Issue:** Email and password inputs use only `placeholder` attributes; no `<label>` elements.  
**Impact:** 
- Screen reader users won't hear field purposes
- Placeholder text disappears on focus, leaving no visible label
- Mobile users have reduced touch target area
- Placeholders do not satisfy WCAG labeling requirements

**WCAG Criterion:** 1.3.1 Info and Relationships (Level A), 3.3.2 Labels or Instructions (Level A)  
**Recommendation:** Add explicit labels:
```html
<label for="email">Email</label>
<input type="email" id="email" placeholder="Email" required>

<label for="password">Password</label>
<input type="password" id="password" placeholder="Password" required>
```

### 5. **Password Hint Not Associated**
**Severity:** Major  
**Issue:** "At least 8 characters" is a separate `<p>` with no connection to the password field.  
**Impact:** Screen readers won't announce this requirement to password field users; users don't know the constraint.  
**WCAG Criterion:** 1.3.1 Info and Relationships (Level A), 3.3.2 Labels or Instructions (Level A)  
**Recommendation:** Use `aria-describedby`:
```html
<input type="password" id="password" aria-describedby="pwd-hint">
<p id="pwd-hint" class="hint">At least 8 characters.</p>
```

### 6. **Missing Alt Text on Logo**
**Severity:** Major  
**Issue:** `<img src="/img/logo-2024-final.png">` has no `alt` attribute.  
**Impact:** Screen reader users won't know what the image is; decorative intent is ambiguous.  
**WCAG Criterion:** 1.1.1 Non-text Content (Level A)  
**Recommendation:** Add `alt="Company Logo"` or `alt=""` if purely decorative. Assuming it's a branding element: `<img src="/img/logo-2024-final.png" alt="Company Logo">`.

## Moderate Issues

### 7. **Marginal Color Contrast on Hint Text**
**Severity:** Moderate  
**Issue:** `.hint` uses `color: #595959` (gray) on white background (#fff).  
**Impact:** Contrast ratio is approximately 5.5:1. Meets WCAG AA for normal text (4.5:1) but is at the threshold; does not meet AAA (7:1).  
**WCAG Criterion:** 1.4.3 Contrast (Minimum) (Level AA)  
**Recommendation:** Darken hint text to `#474747` or darker for safer compliance margin.

### 8. **Manual Tab Index**
**Severity:** Moderate  
**Issue:** Link to terms has `tabindex="3"`.  
**Impact:** Explicit positive tabindex values override document order and can create confusing keyboard navigation flow.  
**WCAG Criterion:** 2.4.3 Focus Order (Level A)  
**Recommendation:** Remove `tabindex="3"` and allow natural document order.

### 9. **Ambiguous Checkbox Label**
**Severity:** Minor  
**Issue:** Checkbox label text "I accept the terms" is functional but doesn't link to or describe the terms document clearly.  
**Impact:** Users may not understand what terms they're accepting.  
**Recommendation:** Consider: `<label><input type="checkbox" id="terms" required> I accept the <a href="/terms">terms and conditions</a></label>` and make terms a required field via `aria-required="true"` or HTML `required` attribute.

## Missing Features

### 10. **No Error Feedback Mechanism**
**Severity:** Moderate  
**Issue:** Form has no client-side validation feedback or error announcement for screen readers.  
**Impact:** If form submission fails, users won't be notified of required fields or validation errors.  
**Recommendation:** Add `aria-live="polite"` error container and announce validation errors.

### 11. **Required Field Indicators**
**Severity:** Minor  
**Issue:** No indication (visual or programmatic) of which fields are required.  
**Assumption:** Email, password, and terms checkbox are required.  
**Recommendation:** 
- Add `required` attribute to inputs
- Add `aria-required="true"` for extra clarity
- Visually indicate required fields (e.g., asterisk with explanation)

## Summary Table

| Issue | Severity | Type | WCAG Level |
|-------|----------|------|-----------|
| Focus outline removed | Critical | Keyboard | A |
| Div button not keyboard accessible | Critical | Keyboard/ARIA | A |
| Duplicate ID attribute | Critical | HTML | A |
| Missing form labels | Major | ARIA/Semantics | A |
| Password hint not associated | Major | ARIA | A |
| Missing image alt text | Major | Non-text Content | A |
| Hint text contrast marginal | Moderate | Color Contrast | AA |
| Manual tab index | Moderate | Keyboard | A |
| Ambiguous checkbox label | Minor | Semantics | A |
| No validation error feedback | Moderate | ARIA/UX | A |
| Required fields not marked | Minor | Semantics | A |

**Current Compliance Level:** Fails WCAG 2.1 Level A in multiple areas.
