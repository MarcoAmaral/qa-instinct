# Accessibility Audit: Sign-up page (WCAG 2.2 AA)

Audit date: 2026-10-25. Auditor: QA (<account email, redacted>). Method: static reading of the page source only. No browser, no scanner and no assistive technology was run. Every verdict below is "by inspection of the source" unless it says otherwise, and the conclusion states what that does and does not allow the audit to claim.

## 1. Scope

| Item | Value |
| --- | --- |
| Target | WCAG 2.2 AA (`https://www.w3.org/TR/WCAG22/`). Level A criteria are included because AA contains them. |
| Blocking threshold | Not stated by the team. Assumption for this report only: Critical and High block a release. The team confirms or replaces this; the audit does not decide it. |
| Build seen | The 28-line HTML source pasted into the request on 2026-10-25. No version, commit or URL was given. Assumption: the source is the deployed page, with no external CSS or script. |
| `@axe-core/playwright` / axe-core | N/A — scan not run (no browser available) |
| Browser | N/A — none; where browser behaviour matters, Chromium default rendering is assumed |
| Viewports | 1440 x 900 (evidence rule), 320 CSS px wide (narrow), 200% zoom. None observed. |

### Pages x states

| Page | State | Audited? | Note |
| --- | --- | --- | --- |
| Sign-up (`/`, title "Sign up") | Default (empty form) | Yes, by source inspection | Default and empty are the same state: the form has no prefilled values |
| Sign-up | Loading | Not audited | No loading state exists in the source |
| Sign-up | Validation error | Not audited | No client-side validation exists: no `required`, and `form.submit()` bypasses constraint validation. Server-side error rendering is unknown. |
| Sign-up | Success | Not audited | Submission target unknown (no `action`); destination page not provided |
| Sign-up | Modal open | Not audited | No modal exists in the source |
| Sign-up | Focus on email, password, checkbox, link | Reasoned from CSS only | Focus styling is derivable from the stylesheet; the rendered result was not seen |
| Sign-up | Focus on "Create account" | Cannot occur | The control is a `div` with no `tabindex`; it never receives keyboard focus |

## 2. Automated scan

**Not run.** No raw JSON was kept because no scan produced any. The table below is a **prediction** of what the template in `accessibility-checks.md` would return with the tag list `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`, derived from the source and from axe-core rule definitions. Rule coverage depends on the installed axe-core version. A real run must replace this table, and the raw results must be read before any row here is trusted.

| Group | Predicted content | What the audit did with it |
| --- | --- | --- |
| `violations` | `html-has-lang` (line 2), `image-alt` (line 14) | Findings A11Y-SIGNUP-006 and A11Y-SIGNUP-005 |
| `incomplete` | `target-size` on the checkbox at line 20 (13 x 13 px native control inside a label; axe may not resolve the spacing exception); `color-contrast` on the two placeholders (pseudo-element text that axe does not measure) | Manual verdicts in step 3 |
| `passes` (automated pass, not "conformant") | `document-title`; `label` on both inputs (axe accepts a non-empty `placeholder` as an accessible name); `link-name`; `color-contrast` on body text, hint and button text (ratios below); `duplicate-id-aria` (no ARIA or `for` attribute references the duplicated `id`) | Recorded as automated pass per element. The `label` pass is the scanner-green trap: see A11Y-SIGNUP-004. |
| `inapplicable` | `autocomplete-valid` (no `autocomplete` attribute to validate), `video-caption`, `audio-caption`, `frame-title`, `aria-*` rules (no ARIA on the page), `meta-viewport` (no viewport meta tag) | Listed so the reader sees what the page never exercised |

Rules that would **not run** with the template's tag list, because axe tags them `best-practice`, not WCAG: `tabindex` (would otherwise flag line 21), `region`, `page-has-heading-one`, `label-title-only`. The `duplicate-id` and `duplicate-id-active` rules are deprecated and disabled by default in current axe-core, so the duplicated `id="email"` (lines 17 and 18) is expected to pass the scan silently.

Contrast ratios computed from the stylesheet (sRGB relative luminance, WCAG formula):

| Text | Colours | Ratio | Threshold | Result |
| --- | --- | --- | --- | --- |
| Body, h1, labels | `#222` on `#fff` | 15.9:1 | 4.5:1 | Pass |
| Hint, 0.9rem (14.4 px, normal) | `#595959` on `#fff` | 7.0:1 | 4.5:1 | Pass |
| Button text | `#fff` on `#0a58ca` | 6.4:1 | 4.5:1 | Pass |
| Placeholders | Browser default on `#fff` | Not measured | 4.5:1 | Not checked |

## 3. Manual checks

All verdicts are on the Sign-up page, default state, from the source. "Pass by inspection" means nothing in the source can fail the criterion; it is not an observation of rendered behaviour.

| Criterion | Verdict | Evidence / reasoning |
| --- | --- | --- |
| 1.1.1 Non-text Content | Fail | Line 14: the logo has no `alt`. A screen reader announces the file name or "image". Finding 005. |
| 1.3.1 Info and Relationships | Fail | Lines 17 and 18: no `<label>`; line 19: the password hint is not tied to the field. Findings 004 and 008. |
| 1.3.5 Identify Input Purpose | Fail | Lines 17 and 18: no `autocomplete="email"` / `autocomplete="new-password"`. Finding 007. |
| 1.4.3 Contrast (Minimum) | Pass (styled text); not checked (placeholders) | Ratios in step 2. Placeholder colour is browser-defined and was not measured. |
| 1.4.4 Resize Text | Not checked | No fixed heights or widths in the CSS, so clipping is unlikely, but 200% zoom was not rendered. |
| 1.4.11 Non-text Contrast | Not checked | Input and checkbox borders are browser defaults; no custom focus ring exists to measure (see 2.4.7). |
| 2.1.1 Keyboard | Fail | Line 22: the submit control is a `div` with `onclick`. It is not focusable and has no key handler. Pressing Enter in a field does not submit either: the form has no submit button and two fields block implicit submission. The task cannot be finished by keyboard. Finding 001. |
| 2.1.2 No Keyboard Trap | Pass by inspection | No modal, overlay or script that captures focus. |
| 2.4.3 Focus Order | Fail | Line 21: `tabindex="3"` makes the link the first Tab stop, before the email field. Predicted order: link, email, password, checkbox. "Create account" is never reached. Finding 003. |
| 2.4.7 Focus Visible | Fail | Line 9: `:focus { outline: none; }` applies to every element and no `:focus-visible` style replaces it. Finding 002. |
| 2.4.11 Focus Not Obscured (Minimum) | Pass by inspection | No sticky, fixed or overlaying content. |
| 2.5.7 Dragging Movements | Inapplicable | Nothing on the page is dragged. |
| 2.5.8 Target Size (Minimum) | Pass pending measurement | Button: 16 px text with normal line height plus 8 px vertical padding gives about 26 px tall, above 24 px. Checkbox: the wrapping label makes the whole text the target. Confirm with a rendered measurement. |
| 3.1.1 Language of Page | Fail | Line 2: `<html>` has no `lang`. Finding 006. |
| 3.2.1 On Focus, 3.2.2 On Input | Pass by inspection | No focus, change or input handlers. |
| 3.2.6 Consistent Help | Not checked | No help mechanism on this page; other pages were not provided. |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Not checked | No error state exists client-side. Whatever the server renders after submit was not seen. |
| 3.3.2 Labels or Instructions | Fail | Placeholder-only labels disappear on typing; the password hint is visually present but not programmatically associated. Findings 004 and 008. |
| 3.3.7 Redundant Entry | Pass by inspection | Single-step form; nothing is asked twice. Earlier steps of the process, if any, were not provided. |
| 3.3.8 Accessible Authentication (Minimum) | Inapplicable here | Sign-up creates a password; it is not an authentication step. Paste is not blocked in the source. Password-manager support is weakened by the missing `autocomplete` (finding 007). |
| 4.1.2 Name, Role, Value | Fail | Line 22: "Create account" has no role, no name exposed as a control, and no focusable state. Finding 001. |

Checklist from `accessibility-checks.md`:

| Check | Verdict | Note |
| --- | --- | --- |
| Tab test | Fail (predicted) | Order link, email, password, checkbox; button unreachable; no focus indicator at any stop. Not observed in a browser. |
| Modal trap test | Inapplicable | No modal. |
| Colour-blindness simulation | Not checked | Needs a rendered page. Nothing in the source conveys information by colour alone. |
| Screen reader | Not checked | No screen reader run. Predicted announcements are stated in the findings but are not evidence. |

## 4. Findings

Severity follows the `/qa-defect` scale (Critical, High, Medium, Low). "Blocks" is against the assumed threshold in step 1. Evidence is `N/A — not captured (source-only audit)` for every row; the Element column gives the source line and a locator instead.

| ID | Criterion | Page and state | Element | Observed / expected | User impact | Source | Evidence | Suggested fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 2.1.1 Keyboard; 4.1.2 Name, Role, Value | Sign-up, default | Line 22, `div.btn` ("Create account"); no role locator exists, which is the defect | Observed: a `div` with `onclick` only, not focusable, no role, and Enter in a field does not submit. Expected: a native `<button type="submit">` reachable by Tab and operable by Enter and Space. | Keyboard-only, switch and screen reader users cannot create an account at all. | Manual (2.1.1 check); no axe rule covers click-only `div`s | N/A — not captured (source-only audit) | Replace with `<button type="submit" class="btn">Create account</button>` and drop the inline script | Critical. Blocks. |
| A11Y-SIGNUP-002 | 2.4.7 Focus Visible | Sign-up, focus on any control | Line 9, `:focus { outline: none; }` | Observed: focus outline removed globally with no replacement. Expected: a visible indicator on every focused element. | Sighted keyboard users cannot tell where they are on the page. | Manual (2.4.7 check) | N/A — not captured (source-only audit) | Delete the rule, or replace with `:focus-visible { outline: 2px solid #0a58ca; outline-offset: 2px; }` and verify 3:1 against adjacent colours (1.4.11) | High. Blocks. |
| A11Y-SIGNUP-003 | 2.4.3 Focus Order | Sign-up, default | Line 21, `getByRole('link', { name: 'Read the terms' })` | Observed: `tabindex="3"` puts the link first in Tab order, before the fields. Expected: Tab order matches reading order. | Keyboard users land on the terms link before the form and may leave the page before filling it. | Manual; axe `tabindex` rule is best-practice and would not run with the WCAG tag list | N/A — not captured (source-only audit) | Remove the `tabindex` attribute | Medium. Does not block. |
| A11Y-SIGNUP-004 | 3.3.2 Labels or Instructions; 1.3.1 Info and Relationships | Sign-up, default and while typing | Lines 17 and 18, `getByPlaceholder('Email')`, `getByPlaceholder('Password')` | Observed: placeholder is the only label; it vanishes once the user types. Expected: a visible, persistent `<label>` bound to each input. | Users with memory or attention impairments lose the field's purpose mid-entry; some screen readers and older browsers do not use placeholder as a name. | Manual; axe `label` rule passes on `placeholder` (scanner-green trap) | N/A — not captured (source-only audit) | Add `<label for="email">Email</label>` and `<label for="password">Password</label>`; fix the duplicate `id` first (see "Also observed") | High. Blocks. |
| A11Y-SIGNUP-005 | 1.1.1 Non-text Content | Sign-up, default | Line 14, `getByRole('img')` | Observed: `<img>` with no `alt`. Expected: `alt` naming the organisation, or `alt=""` if the heading already carries the meaning. | Screen reader users hear a file name ("logo-2024-final.png") or "image" as the first item on the page. | Predicted axe `image-alt` (axe impact: critical) | N/A — not captured (source-only audit) | `alt="<Organisation> logo"`, or `alt=""` if decorative | Medium. Does not block. |
| A11Y-SIGNUP-006 | 3.1.1 Language of Page | Sign-up, all states | Line 2, `<html>` | Observed: no `lang`. Expected: `<html lang="en">` (assumption: the page is in English). | Screen readers may read the page with the wrong pronunciation rules; translation tools misdetect the language. | Predicted axe `html-has-lang` (axe impact: serious) | N/A — not captured (source-only audit) | Add `lang="en"` | Medium. Does not block. |
| A11Y-SIGNUP-007 | 1.3.5 Identify Input Purpose | Sign-up, default | Lines 17 and 18 | Observed: no `autocomplete` on fields that collect the user's email and a new password. Expected: `autocomplete="email"` and `autocomplete="new-password"`. | Browsers and password managers cannot fill or offer a generated password; users with motor or cognitive impairments must type everything. | Manual; axe `autocomplete-valid` only checks values that exist | N/A — not captured (source-only audit) | Add the two `autocomplete` attributes | Medium. Does not block. |
| A11Y-SIGNUP-008 | 3.3.2 Labels or Instructions; 1.3.1 Info and Relationships | Sign-up, focus on password | Line 19, `p.hint` ("At least 8 characters.") | Observed: the rule is visible text with no programmatic link to the field. Expected: the hint announced when the field gets focus. | Screen reader users who Tab straight into the field do not hear the length rule unless they read on. Workaround: the hint is in reading order after the field. | Manual (3.3.2 check) | N/A — not captured (source-only audit) | Give the hint an `id` and add `aria-describedby` on the password input | Low. Does not block. |

### Also observed (not WCAG criteria, affects the fixes)

- **Duplicate `id="email"`** on lines 17 and 18. Any `<label for="email">` or `aria-describedby` added for finding 004 would bind to the first input only. Rename the password field's `id` before applying that fix. 4.1.1 Parsing is obsolete in WCAG 2.2 and is not reported.
- **`form.submit()` bypasses validation and the submit event**, and the form has no `method` or `action`. The browser will send a GET request with the password in the query string. This is a security and functional defect outside this audit's scope and should be filed separately.
- **No `required` attributes and no error rendering**, so the validation-error state cannot be designed or audited until the team defines it.

## 5. Conclusion: what this audit can and cannot claim

**No automated scan was run.** The "predicted violations" above are a reading of the source against axe rule definitions, not a result. The statement "no violations found by the automated scan" cannot be made for any page or state.

**The page is not conformant to WCAG 2.2 AA.** Source inspection alone is enough to establish failures of 1.1.1, 1.3.1, 1.3.5, 2.1.1, 2.4.3, 2.4.7, 3.1.1, 3.3.2 and 4.1.2 on the default state. Finding 001 on its own means a keyboard-only user cannot complete sign-up.

Coverage by means:

- **Checked by scanner**: none.
- **Checked by hand (source inspection, not a rendered page)**: 1.1.1, 1.3.1, 1.3.5, 1.4.3 (styled text only), 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11, 2.5.7, 2.5.8 (pending measurement), 3.1.1, 3.2.1, 3.2.2, 3.3.2, 3.3.7, 3.3.8, 4.1.2.
- **Not checked at all**: 1.4.3 for placeholders, 1.4.4, 1.4.10 Reflow, 1.4.11, 3.2.6, 3.3.1, 3.3.3, colour-blindness simulation, screen reader pass, every viewport and the 200% zoom.
- **Pages and states not audited**: loading, validation error, success, modal open, and the pages before and after this step.

No conformance score or percentage is given.

**Next run, once a browser is available**: fix 001 to 004 and 006 first, then run the axe template on default and validation-error states, keep the raw JSON per state, do the tab test and a screen reader pass, and capture 1440 x 900 viewport screenshots named `A11Y-SIGNUP-NNN-<state>.png` as evidence.

**Rules not applied in this reply**: the `qa-rules` skill is not installed, but the `accessibility-qa`, `test-evidence` and `context-discovery` rules were read from the project's rules folder. The `code-style-qa` rule was not applied because no test code was written. The evidence checker `check-test-evidence.sh` was not run because no spec exists; no evidence files exist either. The screen reader check was not run.
