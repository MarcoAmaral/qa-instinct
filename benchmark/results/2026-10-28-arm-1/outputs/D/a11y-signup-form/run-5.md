# Accessibility Audit: Sign-up Page

## Scope

**Target**: WCAG 2.2 AA

**Blocking threshold**: Critical and Serious

**Assumption**: Source-code-only access prevents running automated scanners or visual checks in a browser. Audit is based on static code analysis.

**Pages and states audited**:
| Page | State | Status |
| --- | --- | --- |
| Sign-up | Default (initial load) | Audited |
| Sign-up | Validation error | Not audited |
| Sign-up | Success | Not audited |

**Viewports and zoom**:
| Viewport | Status |
| --- | --- |
| 1440 × 900 | Assumed standard |
| Mobile (narrow) | Not audited |
| 200% zoom | Not audited |

**Versions**: Static code analysis only; no automated scanner executed.

---

## Automated Scan

**Status**: Not executed (browser required).

**Code-level violations** identified through static analysis:

1. Missing `alt` attribute on logo image (1.1.1 Non-text Content)
2. No `<label>` elements for email and password inputs (4.1.2 Name, Role, Value)
3. Duplicate `id="email"` on password input (malformed HTML)
4. Focus outline removed with no replacement (2.4.7 Focus Visible)
5. Submit button is a `<div>` with `onclick`, not a semantic button (2.1.1 Keyboard, 4.1.2 Name, Role, Value)
6. `tabindex="3"` disrupts natural focus order (2.4.3 Focus Order)
7. Missing `lang` attribute on `<html>` element (3.1.1 Language of Page)
8. Password hint text not programmatically associated (1.3.1 Info and Relationships)

---

## Manual Checks

| Criterion | Check | Finding | Evidence |
| --- | --- | --- | --- |
| 1.4.3 Contrast (Minimum) | Do text colors meet minimum contrast? | Cannot verify without rendering | Browser required |
| 1.4.4 Resize Text | Is text clipped at 200% zoom? | Cannot verify | Browser required |
| 1.4.11 Non-text Contrast | Do focus indicators meet 3:1? | Focus outline is removed; cannot assess replacement | Browser required |
| 2.1.1 Keyboard | Can the entire form be completed with keyboard only? | No. Submit button is a `<div>` and not keyboard accessible | Code review |
| 2.1.2 No Keyboard Trap | Can focus leave every widget? | No clear mechanism to escape focus on submit button | Code review |
| 2.4.7 Focus Visible | Is focus visible when navigating? | No. Outline removed, no replacement style provided | Code review |
| 3.1.1 Language of Page | Is language specified? | No `lang` attribute | Code review |
| 3.2.1 On Focus, 3.2.2 On Input | Does focusing/changing a control unexpectedly change context? | No event handlers suggest this is not triggered | Code review |

**Manual checklist**:
- [ ] Tab test — Cannot verify (browser required)
- [ ] Modal trap — Not applicable (no modal in form)
- [ ] Colour-blindness simulation — Cannot verify (browser required)
- [ ] Screen reader test — Not checked (screen reader not available)

---

## Findings

| ID | Criterion | Page & State | Element | Observed / Expected | User Impact | Source | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | Sign-up / Default | `<img src="/img/logo-2024-final.png">` | Observed: No alt. Expected: `alt="Company Logo"` or similar | Blind and low-vision users cannot understand the logo's purpose | Code review | Critical |
| A11Y-SIGNUP-002 | 4.1.2 Name, Role, Value | Sign-up / Default | `<input type="email" id="email">` | Observed: No associated label. Expected: `<label for="email">Email</label>` | Screen reader users cannot identify the field purpose | Code review | Critical |
| A11Y-SIGNUP-003 | 4.1.2 Name, Role, Value | Sign-up / Default | `<input type="password" id="email">` | Observed: No label; duplicate ID. Expected: `<label for="password">Password</label>` with unique `id="password"` | Screen reader users cannot access the field; malformed HTML breaks form structure | Code review | Critical |
| A11Y-SIGNUP-004 | 1.3.1 Info and Relationships | Sign-up / Default | Password input + hint `<p>` | Observed: Hint not linked via `aria-describedby`. Expected: `aria-describedby="hint-id"` on input | Users of assistive technology do not receive the password requirement ("At least 8 characters") | Code review | Serious |
| A11Y-SIGNUP-005 | 2.4.7 Focus Visible | Sign-up / Default | CSS `:focus { outline: none; }` | Observed: Focus indicator removed, no replacement. Expected: Visible focus style e.g. `outline: 2px solid #0a58ca;` | Keyboard users cannot see which element is focused | Code review | Critical |
| A11Y-SIGNUP-006 | 2.1.1 Keyboard | Sign-up / Default | `<div class="btn" onclick="submitForm()">Create account</div>` | Observed: Submit is a `<div>`. Expected: `<button type="submit">Create account</button>` | Keyboard users cannot activate submit; no focus or keyboard semantics | Code review | Critical |
| A11Y-SIGNUP-007 | 4.1.2 Name, Role, Value | Sign-up / Default | `<div class="btn" onclick="submitForm()">` | Observed: No button role, not semantic button. Expected: Native `<button>` element | Screen reader users do not hear "Create account" as a button; cannot activate via spacebar or Enter | Code review | Critical |
| A11Y-SIGNUP-008 | 2.4.3 Focus Order | Sign-up / Default | `<a href="/terms" tabindex="3">Read the terms</a>` | Observed: `tabindex="3"`. Expected: `tabindex="0"` or no tabindex | Keyboard users tab in an unexpected order; link receives focus before other form fields | Code review | Serious |
| A11Y-SIGNUP-009 | 3.1.1 Language of Page | Sign-up / Default | `<html>` tag | Observed: No `lang` attribute. Expected: `<html lang="en">` | Screen readers cannot select the correct language for pronunciation | Code review | Serious |

---

## Report

### What was checked

**By static code analysis**:
- 1.1.1 Non-text Content (image alt text)
- 1.3.1 Info and Relationships (label associations, form structure)
- 2.1.1 Keyboard (button semantics)
- 2.1.2 No Keyboard Trap (limited)
- 2.4.3 Focus Order (tabindex usage)
- 2.4.7 Focus Visible (focus CSS)
- 3.1.1 Language of Page (lang attribute)
- 4.1.2 Name, Role, Value (semantic elements)

**By manual inspection (code only, no rendering)**:
- 3.2.1 On Focus, 3.2.2 On Input (JavaScript event handlers)

**NOT checked** (require browser, screen reader, or rendering):
- 1.4.3 Contrast (Minimum)
- 1.4.4 Resize Text
- 1.4.11 Non-text Contrast
- 2.4.11 Focus Not Obscured (Minimum)
- 3.3.1 Error Identification (no error state in source)
- 3.3.8 Accessible Authentication (Minimum) (form action/method missing; submission untestable)
- Tab order testing
- Color-blindness simulation
- Screen reader usability

### Verdict

**Not conformant to WCAG 2.2 AA.** Nine findings identified; four are Critical severity. The sign-up form is **not keyboard accessible** (non-semantic button), **lacks form labels** (inaccessible to screen readers), and **removes focus indicators** without replacement (invisible to keyboard users). **A full browser-based audit and screen reader test are required** before this page can be released. Do not publish.
