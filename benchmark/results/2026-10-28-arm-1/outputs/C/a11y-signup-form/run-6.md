---
title: Accessibility audit: Sign-up page
slug: accessibility-audit-signup-page
article_type: troubleshooting
product_area: Compliance
audience: Developer
plan_availability: All plans
reading_time: 4 min
related_articles: None — audit findings, not yet linked to remediation guides
last_updated: 2026-10-28
---

# Accessibility audit: Sign-up page

This sign-up form has 12 accessibility barriers that block users with disabilities from signing up. The most critical prevent keyboard navigation and screen reader use.

## Critical issues (blocks access)

**No labels for email and password fields**

The inputs rely on placeholder text only. Screen reader users cannot identify what each field is. A blind user hears only "text input" or "password input" with no context.

Add a `<label>` element before each input:
```html
<label for="email">Email</label>
<input type="email" id="email">

<label for="password">Password</label>
<input type="password" id="password">
```

**Logo image has no alt text**

Screen readers announce `<img>` with no alt attribute as "image, unlabeled". Replace with:
```html
<img src="/img/logo-2024-final.png" alt="Acme Corp logo">
```

Assumption: assumed "Acme Corp" as the brand; use your actual company name.

**Submit button is not a button**

The submit control is a `<div>` with an `onclick` handler. Keyboard and screen reader users cannot activate it. Replace with:
```html
<button type="submit">Create account</button>
```

**Focus indicator is hidden**

The CSS rule `:focus { outline: none; }` removes the visible focus ring. Keyboard users cannot see which control has focus.

Remove that rule or replace it with a visible focus style:
```css
:focus { outline: 2px solid #0a58ca; }
```

## Major issues (significantly harder to use)

**Password field has email's id**

The password input has `id="email"`, which is wrong and breaks form programmatically. Change to `id="password"`. The second input's `<label>` will then link to the correct field.

**Hint text is not associated with the password field**

"At least 8 characters" is read in isolation by screen readers. Link it:
```html
<label for="password">Password</label>
<input type="password" id="password" aria-describedby="pwd-hint">
<p class="hint" id="pwd-hint">At least 8 characters.</p>
```

**Incorrect tab order**

The link has `tabindex="3"` while the form inputs have no tabindex. Keyboard users jump to the link unexpectedly before they can submit the form. Remove the tabindex:
```html
<a href="/terms">Read the terms</a>
```

## Moderate issues (harder to read or use)

**Hint text may fail color contrast**

The hint uses `color: #595959` (dark gray) on white. Test the contrast ratio with a checker. If below 4.5:1 (WCAG AA), lighten the text or darken the background.

**Form lacks validation feedback**

No `aria-invalid`, `aria-required`, or error messages. Add after fixing labels:
```html
<input type="email" id="email" required aria-required="true">
```

**No action or method on the form**

The form element lacks `action` and `method` attributes. The submit will fail. Add:
```html
<form id="signup" action="/signup" method="post">
```

Assumption: assumed POST to `/signup`; adjust to your endpoint.

## Remediation summary

Priority order:

1. Add `<label>` elements for both inputs (blocks access).
2. Change `<div class="btn">` to `<button type="submit">` (blocks access).
3. Restore focus indicator (blocks keyboard use).
4. Fix password field `id` (data integrity).
5. Fix tabindex and remove it from the link (restores keyboard order).
6. Link hint text to password field with `aria-describedby` (improves screen reader clarity).
7. Add `required` and `aria-required="true"` to inputs (improves clarity).
8. Add `action` and `method` to form (enables submission).
9. Test color contrast on hint text; adjust if needed.

## Related articles

None: links to WCAG guidelines and remediation how-tos would go here.

---

**Assumptions made:** The logo is the company brand logo (alt text name assumed). The form submits to `/signup` via POST. The hint "At least 8 characters" applies to the password field only. No other validation rules are enforced beyond HTML5 type checking.
