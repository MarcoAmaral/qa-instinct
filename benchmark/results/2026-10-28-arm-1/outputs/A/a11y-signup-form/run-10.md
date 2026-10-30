# Accessibility Audit: Sign-up Page

## Critical Issues

### 1. **Non-semantic Button Element**
The "Create account" element uses a `<div>` with `onclick` instead of a `<button>`.
- **Impact**: Not keyboard accessible; screen reader users cannot interact with it
- **Fix**: Replace `<div class="btn" onclick="submitForm()">Create account</div>` with `<button type="submit">Create account</button>`

### 2. **Removed Focus Indicator**
`:focus { outline: none; }` removes the default keyboard focus outline.
- **Impact**: Keyboard users cannot see where focus is; violates WCAG 2.1 SC 2.4.7
- **Fix**: Remove this rule or replace with a visible focus style (e.g., `outline: 2px solid #0a58ca`)

### 3. **No Associated Labels for Inputs**
Email and password inputs use only `placeholder` text; no `<label>` elements.
- **Impact**: Screen reader users don't get clear field labels; placeholders disappear when typing
- **Fix**: Add `<label for="email">Email</label>` and `<label for="password">Password</label>` before inputs

### 4. **Duplicate ID Attributes**
Both email and password inputs have `id="email"`.
- **Impact**: Breaks programmatic associations and validation; violates HTML validity
- **Fix**: Change password input to `id="password"`

### 5. **Insufficient Color Contrast**
Hint text uses `#595959` on white background (~2.86:1 ratio).
- **Impact**: Does not meet WCAG AA standard (4.5:1); illegible for low-vision users
- **Fix**: Darken to `#3a3a3a` or darker (~8:1 ratio)

## Major Issues

### 6. **Missing Image Alt Text**
Logo image lacks `alt` attribute.
- **Impact**: Decorative intent unclear to screen reader users
- **Assumption**: Logo is decorative; use `alt=""`
- **Alternative**: If it conveys meaning, provide descriptive text

### 7. **Inappropriate Positive Tabindex**
"Read the terms" link has `tabindex="3"`.
- **Impact**: Disrupts natural tab order for keyboard navigation
- **Fix**: Remove `tabindex` entirely; links are keyboard accessible by default

### 8. **No Language Declaration**
Missing `lang` attribute on `<html>` element.
- **Impact**: Screen readers cannot determine language for pronunciation
- **Fix**: Add `<html lang="en">`

## Minor Issues

### 9. **Password Field Hint Text**
"At least 8 characters" hint lacks programmatic association.
- **Fix**: Add `aria-describedby="pwd-hint"` to password input and `id="pwd-hint"` to the hint `<p>`

### 10. **Missing Form Attributes**
Form lacks `method` and `action` attributes (may be intentional if handled by JavaScript).
- **Assumption**: Form submission is handled client-side; if server-side, add appropriate attributes

---

## Summary
**7 WCAG violations** (5 Level A, 2 Level AA) prevent basic keyboard navigation and screen reader functionality. The non-semantic button and missing labels are the highest priority fixes.
