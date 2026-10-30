# Accessibility Audit: Sign-up Page

## Critical Issues (Block Access)

| Issue | Impact | WCAG Level |
|-------|--------|------------|
| **Button is a `<div>`, not a `<button>`** | Keyboard users cannot submit the form. Screen readers do not announce it as a button. | A |
| **Inputs lack proper labels** | Screen readers cannot associate labels with fields. Users with cognitive disabilities cannot understand what each field is for. | A |
| **Duplicate input IDs** | Both email and password fields have `id="email"`. The password field's label and hint are unreachable. | A |
| **Logo missing alt text** | Decorative images need empty alt (`alt=""`), but missing alt fails the page entirely in some validators. | A |
| **Focus outline removed without replacement** | Keyboard users cannot see where focus is. `:focus { outline: none; }` hides focus but adds no alternative visual indicator. | A |

## Major Issues (Severely Impair Access)

| Issue | Impact | WCAG Level |
|-------|--------|------------|
| **Placeholder text is not a label** | Placeholder disappears when the user types. Screen readers do not treat it as a label. Visually, the field purpose is lost mid-entry. | A |
| **Hint text not associated with password field** | "At least 8 characters" appears after a password field with the wrong ID and no label. Screen readers cannot tie it to the password input. | A |
| **Tab order broken** | `tabindex="3"` on the link creates a non-sequential tab order. Best practice is to avoid positive tabindex values; use semantic HTML order instead. | A |
| **No error messaging or validation** | If the user enters a weak password or invalid email, there is no feedback. Error messages are essential for accessibility. | AA |

## Minor Issues (Confuse or Slow Access)

| Issue | Impact | WCAG Level |
|-------|--------|------------|
| **Form has no fieldset/legend** | Multiple related inputs benefit from grouping. A fieldset with legend (`<fieldset><legend>Account details</legend>`) helps screen reader users and groups visual focus. | AAA |
| **Hint text styling** | `.hint { color: #595959; font-size: 0.9rem; }` is small and dim. Contrast ratio is ~5:1 on white (#fff), which passes WCAG AA for normal text but is hard to read for low-vision users. | AA |
| **No skip link** | Users cannot skip the logo to reach the form. A skip link is optional for short pages but improves keyboard navigation. | AAA |

---

## Required Fixes

1. **Change the button to a `<button>` element:**
   ```html
   <button type="submit">Create account</button>
   ```

2. **Add proper labels and fix IDs:**
   ```html
   <label for="email-input">Email</label>
   <input type="email" id="email-input" required>
   
   <label for="password-input">Password</label>
   <input type="password" id="password-input" required>
   <p class="hint" id="password-hint">At least 8 characters.</p>
   ```
   Add `aria-describedby="password-hint"` to the password input to link the hint.

3. **Restore focus visibility:**
   ```css
   :focus-visible {
     outline: 2px solid #0a58ca;
     outline-offset: 2px;
   }
   ```
   Remove `:focus { outline: none; }`.

4. **Add alt text to the logo:**
   ```html
   <img src="/img/logo-2024-final.png" alt="Company logo">
   ```
   Or `alt=""` if purely decorative.

5. **Remove positive tabindex:**
   ```html
   <a href="/terms">Read the terms</a>
   ```
   Remove `tabindex="3"` and rely on DOM order.

---

## Testing Recommendations

- Test with a keyboard only (Tab, Shift+Tab, Enter).
- Test with a screen reader (NVDA, JAWS, or VoiceOver).
- Use the axe DevTools browser extension to catch remaining violations.
- Verify color contrast of hint text with a tool like WebAIM Contrast Checker.

**Assumptions made:** The page is a public sign-up form (not an internal tool), the logo is decorative, and "Create account" is the submit button. If the logo is a link or has semantic meaning, its alt text should describe that function.
