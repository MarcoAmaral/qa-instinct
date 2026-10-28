## Accessibility audit: sign-up page (WCAG 2.2 AA)

**Method and limits.** This is a static review of the HTML source only. No browser rendered the page, axe-core did not run, no screenshots exist, and no screen reader was used. Every verdict below comes from reading the source and computing what the browser would do. Verdicts that need rendering are marked "not checked". Standard: WCAG 2.2 (W3C Recommendation, https://www.w3.org/TR/WCAG22/).

### 1. Scope

| Item | Value |
| --- | --- |
| Target | WCAG 2.2 AA (assumed; the team did not state a level) |
| Blocking threshold | Not provided by the team. Assumed for this reply only: axe `critical` and `serious` impact, and Critical or High severity on manual findings, block a release. The team must confirm or replace this. |
| Page | Sign-up, route assumed `/signup` (not in source). Build: none; source as pasted on 2026-10-25. |
| Viewports | 1440 x 900, narrow (375 x 812) and 200% zoom: none rendered, all not checked |
| Versions | `@axe-core/playwright`: not run. axe-core: not run. Browser: none. |

Pages x states:

| State | Audited? | Note |
| --- | --- | --- |
| Default / empty | Yes, static | Same state: the page loads empty |
| Loading | Not audited | No loading state in source |
| Validation error | Not audited | No error state exists in source; `form.submit()` skips browser validation and the server response is unknown |
| Success | Not audited | Not in source |
| Modal open | Inapplicable | No modal |
| Focus on each control | Yes, static | Reasoned from the `:focus` rule; not rendered |

### 2. Automated scan

Not run. Tag list the scan would use: `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa`. No raw JSON exists, so the four groups below are **predicted from the source**, not observed. Confirm every row against the raw results once the page is reachable.

| Group | Predicted content |
| --- | --- |
| `violations` | `image-alt` (line 14), `label` (lines 17, 18), `html-has-lang` (line 2), `tabindex` (line 21). `duplicate-id-active` (line 18) only if the installed axe-core still runs it; it is deprecated in recent versions. |
| `incomplete` | None expected. All colours are flat hex values on flat backgrounds, so `color-contrast` should decide. |
| `passes` | `document-title`, `color-contrast` on body text, hint and button text, `link-name`, `label` for the checkbox (wrapped by its `<label>`), `page-has-heading-one`. Recorded as automated pass only, never as conformant. |
| `inapplicable` | Every ARIA, table, list, frame, video and audio rule. The page exercises none of them. |

Note what axe would **not** catch on this page: the global `outline: none`, the `<div>` used as a submit button, the missing `autocomplete`, and the hint not tied to its field. Those are manual.

### 3. Manual checks

All checks are static; "pass (static)" means the source gives no way to fail, not that it was seen.

| Criterion | Verdict | State | Evidence (source line) |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | Fail | Default | Line 14: `<img>` with no `alt`; the file name would be announced |
| 1.3.1 Info and Relationships | Fail | Default | Lines 17 to 19: no labels, duplicate `id`, hint not associated |
| 1.3.5 Identify Input Purpose | Fail | Default | Lines 17, 18: no `autocomplete` on email or password |
| 1.4.3 Contrast (Minimum) | Pass (computed) | Default | `#222` on `#fff` 15.9:1; `#595959` on `#fff` 7.0:1; `#fff` on `#0a58ca` 6.4:1. Placeholder colour is the browser default and was not measured |
| 1.4.4 Resize Text | Not checked | Default | No fixed heights in the CSS, so low risk; needs rendering at 200% |
| 1.4.10 Reflow | Not checked | Default | No viewport meta tag; mobile browsers will render at desktop width. Needs a narrow viewport |
| 1.4.11 Non-text Contrast | Fail | Focus | Line 9 removes the only focus indicator, so nothing reaches 3:1. Input borders are browser defaults, not measured |
| 2.1.1 Keyboard | Fail | Default | Line 22: `<div onclick>` is not focusable and has no key handler. Enter inside a field does not submit either: the form has no submit button and two text fields, so the browser's implicit submission is suppressed. The task cannot be finished by keyboard |
| 2.1.2 No Keyboard Trap | Pass (static) | Default | No handlers that capture focus; no modal |
| 2.4.3 Focus Order | Fail | Default | Line 21: `tabindex="3"` makes "Read the terms" the first Tab stop, before email, password and checkbox |
| 2.4.7 Focus Visible | Fail | Focus | Line 9: `:focus { outline: none; }` with no `:focus-visible` replacement |
| 2.4.11 Focus Not Obscured | Pass (static) | Default | No sticky or overlaid content |
| 2.5.7 Dragging Movements | Inapplicable | Default | Nothing drags |
| 2.5.8 Target Size | Not checked | Default | Button computes to about 26 px tall at default font metrics; inputs and checkbox are browser-sized (user-agent exception); the link is inline text (exception). Needs measurement |
| 3.1.1 Language of Page | Fail | Default | Line 2: `<html>` has no `lang` |
| 3.2.1 On Focus, 3.2.2 On Input | Pass (static) | Default | No focus or change handlers |
| 3.2.6 Consistent Help | Not checked | Default | No help mechanism on this page; needs the other pages to compare |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Not checked | Error | No error state can be reached from the source (see A11Y-SIGNUP-010) |
| 3.3.2 Labels or Instructions | Fail | Default | Placeholder is the only label; it disappears on typing |
| 3.3.7 Redundant Entry | Pass (static) | Default | Single step, nothing asked twice |
| 3.3.8 Accessible Authentication | Not applicable | Default | This is account creation, not authentication. Paste is not blocked. Missing `autocomplete="new-password"` weakens password-manager support and is reported under 1.3.5 |
| 4.1.2 Name, Role, Value | Fail | Default | Line 22: the submit control has no role, no name exposed as a control and no focusable state. Lines 17, 18: inputs have no reliable accessible name |

Checklist from the reference: tab test fails (static, see 2.1.1 and 2.4.7). Modal trap test inapplicable. Colour-blindness simulation not checked; no information in the source relies on colour alone. Screen reader pass not checked. 4.1.1 Parsing is obsolete and was not tested; the duplicate `id` is reported for its effect on 1.3.1.

### 4. Findings

Evidence is the source line; no screenshot exists. Severity per the defect skill scale (Critical, High, Medium, Low). "Blocks" refers to the assumed threshold in section 1.

| ID | Criterion | Page and state | Element | Observed / expected | User impact | Source | Evidence | Suggested fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 2.1.1 Keyboard; 4.1.2 Name, Role, Value | Sign-up, default | `div.btn` "Create account" | Observed: a `<div onclick>`, not focusable, no role, no key handler; Enter in a field does not submit. Expected: a native submit button | Keyboard-only and screen reader users cannot create an account at all | Manual (static) | Line 22 | Replace with `<button type="submit" class="btn">Create account</button>` and delete the script | Critical. Blocks |
| A11Y-SIGNUP-002 | 2.4.7 Focus Visible; 1.4.11 Non-text Contrast | Sign-up, focus on each control | `:focus` rule | Observed: focus ring removed on every element with no replacement. Expected: a visible indicator at 3:1 or better | Sighted keyboard users cannot tell which control is active | Manual (no axe rule) | Line 9 | Delete the rule, or replace with `:focus-visible { outline: 2px solid #0a58ca; outline-offset: 2px; }` | High. Blocks |
| A11Y-SIGNUP-003 | 1.3.1 Info and Relationships; 3.3.2 Labels or Instructions; 4.1.2 | Sign-up, default | `#email` and the password input | Observed: placeholder only. Expected: a visible `<label for>` on each field | Screen reader users may hear an unnamed edit field; every user loses the field name once they type | axe `label` (predicted, critical impact) and manual | Lines 17, 18 | Add `<label for="email">Email</label>` and `<label for="password">Password</label>` | High. Blocks |
| A11Y-SIGNUP-004 | 1.3.1 Info and Relationships | Sign-up, default | Password input `id="email"` | Observed: two elements share `id="email"`; any `for` or `aria-describedby` reaches only the first. Expected: unique `id="password"` | A label or description added for the password binds to the email field instead; password managers may mis-fill | Manual; axe `duplicate-id-active` only if still enabled in the installed version | Line 18 | Rename the id to `password` and add `name` attributes | Medium. Does not block on its own, but 003 and 009 cannot be fixed without it |
| A11Y-SIGNUP-005 | 3.1.1 Language of Page | Sign-up, default | `<html>` | Observed: no `lang`. Expected: `lang="en"` (assumed language) | Screen readers may use the wrong voice and pronunciation for the whole page | axe `html-has-lang` (predicted, serious impact) | Line 2 | `<html lang="en">` | Medium. Blocks under the assumed axe `serious` threshold |
| A11Y-SIGNUP-006 | 1.1.1 Non-text Content | Sign-up, default | `img[src="/img/logo-2024-final.png"]` | Observed: no `alt`. Expected: `alt` naming the organisation, or `alt=""` if decorative next to the heading | Screen reader users hear a file name or "image" | axe `image-alt` (predicted, critical impact) | Line 14 | Add `alt="<Company name>"`, or `alt=""` if decorative | Medium. Blocks under the assumed axe `critical` threshold |
| A11Y-SIGNUP-007 | 2.4.3 Focus Order | Sign-up, default | `a[href="/terms"]` | Observed: `tabindex="3"` moves the link to the first Tab stop. Expected: natural DOM order | Keyboard users land on the terms link before any field; the order contradicts the reading order | axe `tabindex` (predicted, serious impact) | Line 21 | Remove `tabindex` | Medium. Blocks under the assumed axe `serious` threshold |
| A11Y-SIGNUP-008 | 1.3.5 Identify Input Purpose | Sign-up, default | `#email` and the password input | Observed: no `autocomplete`. Expected: `autocomplete="email"` and `autocomplete="new-password"` | Users who depend on autofill or a password manager must type by hand; generators may not trigger | Manual (axe `autocomplete-valid` checks only invalid values) | Lines 17, 18 | Add the two `autocomplete` values | Medium. Does not block |
| A11Y-SIGNUP-009 | 3.3.2 Labels or Instructions; 1.3.1 | Sign-up, default | `p.hint` "At least 8 characters." | Observed: hint is loose text after the field. Expected: tied to the password field | Screen reader users in forms mode never hear the rule and fail on first submit | Manual | Line 19 | Give the hint an `id` and set `aria-describedby` on the password input | Medium. Does not block |
| A11Y-SIGNUP-010 | 3.3.1 Error Identification; 3.3.3 Error Suggestion | Sign-up, validation error | Form `#signup` and `submitForm()` | Observed: `form.submit()` bypasses constraint validation and the submit event; no `required`, no error text anywhere. Expected: errors in text, tied to the field and announced | Any user submits an empty or malformed email with no feedback; what happens next depends on a server response not in source | Manual | Lines 22, 25 | Fixing 001 restores native validation; add `required`, then error text with `aria-describedby` or `role="alert"` | Medium pending the server response. Does not block on its own |

Outside WCAG but worth a functional defect: neither input has a `name`, so the form submits no data, and the terms checkbox is never enforced.

### 5. Conclusion

- **No automated scan ran.** The audit cannot say "no violations found by the automated scan". The predicted violations in section 2 are reading, not results.
- **Not conformant** to WCAG 2.2 AA on the evidence available. Ten criteria fail from the source alone, and the sign-up task cannot be completed by keyboard.
- **Checked by scanner:** none.
- **Checked by hand (static):** 1.1.1, 1.3.1, 1.3.5, 1.4.3 (computed, placeholder excluded), 1.4.11 (focus only), 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11, 2.5.7, 3.1.1, 3.2.1, 3.2.2, 3.3.2, 3.3.7, 3.3.8, 4.1.2.
- **Not checked at all:** 1.4.4, 1.4.10, 1.4.11 for input borders, 2.5.8, 3.2.6, 3.3.1, 3.3.3, the screen reader pass, the colour-blindness simulation, 200% zoom and the narrow viewport.
- **Pages and states not audited:** loading, validation error, success, and whatever the server returns after submit.
- **Rules not applied:** the evidence checker was not run and no evidence files exist, because nothing was rendered. The `accessibility-qa`, `test-evidence` and `code-style-qa` rules and the accessibility checks reference were loaded and applied.

Next step when the page becomes reachable: run the axe template per state with the tag list above, keep the raw JSON, retake every row in section 3 that says "not checked" in a 1440 x 900 viewport, and ask the team for the real blocking threshold before triaging severity.
