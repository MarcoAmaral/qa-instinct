---
title: Accessibility Audit: Sign-up Page
article_type: reference
---

# Accessibility Audit Report: Sign-up Page

## Critical Issues (WCAG 2.1 Level A)

| Issue | Location | Impact | Fix |
|-------|----------|--------|-----|
| **Missing alt text** | `<img src="/img/logo-2024-final.png">` | Screen readers cannot describe the logo. | Add `alt="Company logo"` or appropriate alt text. |
| **Duplicate IDs** | Password input has `id="email"` (same as email input) | Browser behavior unpredictable; labels and scripts may target wrong element. | Change password input to `id="password"`. |
| **Missing language declaration** | `<html>` element | Screen readers may use wrong language for pronunciation. | Add `<html lang="en">` (or appropriate language code). |
| **Placeholder-only labels** | Email and password inputs | Screen reader users and those with visual impairments see no persistent labels; placeholders vanish on focus. | Add `<label>` elements for both inputs, associated via `for` and `id` attributes. |
| **No form labels** | Email input | Not associated with any label element. | Wrap input in `<label>` or add separate `<label for="email">`. |

## Serious Issues (WCAG 2.1 Level AA)

| Issue | Location | Impact | Fix |
|-------|----------|--------|-----|
| **Focus indicator removed** | `:focus { outline: none; }` in `<style>` | Keyboard users cannot see which element has focus; violates WCAG 2.4.7 (Focus Visible). | Replace with `:focus { outline: 2px solid #0a58ca; outline-offset: 2px; }` or similar. |
| **Button is a div** | `<div class="btn" onclick="submitForm()">` | Not keyboard accessible (cannot Tab or press Space/Enter); screen readers do not announce it as a button; fails WCAG 4.1.2 (Name, Role, Value). | Replace with `<button type="submit" class="btn">Create account</button>` and remove the script. |
| **Broken tab order** | `<a href="/terms" tabindex="3">` | Only this link has an explicit tabindex; tabindex 1 and 2 are missing, and explicit tabindex values > 0 can break natural tab flow. | Remove `tabindex="3"` to use natural tab order. |

## Moderate Issues

| Issue | Location | Impact | Fix |
|-------|----------|--------|-----|
| **Missing input type validation** | Password input has no `type="password"` requirement communicated to form | Hint text is not programmatically associated with input; users may not know the requirement. | Add `aria-describedby="pw-hint"` to password input and `id="pw-hint"` to the hint `<p>`. |
| **Checkbox label clarity** | `<label><input type="checkbox"> I accept the terms</label>` | Acceptable, but no indication that this field is required. | Add `required` attribute to checkbox and consider aria-required="true". |

## Accessibility Improvements Summary

- **For screen readers:** Add proper `<label>` elements, fix duplicate IDs, add language attribute, and use semantic HTML (`<button>` instead of `<div>`).
- **For keyboard users:** Remove focus outline removal, replace div button with `<button>`, fix tab order.
- **For all users:** Associate helper text with inputs via `aria-describedby`, ensure form validation and error messages are accessible.

**Assumptions made:** The page assumes English language; the logo is decorative or a company logo (exact alt text depends on its purpose); the form requires email and password; the form does not require additional accessibility features like CAPTCHA or two-factor auth.
