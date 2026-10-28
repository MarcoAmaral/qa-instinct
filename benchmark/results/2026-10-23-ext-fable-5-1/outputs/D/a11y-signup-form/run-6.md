# Accessibility audit: Sign-up page (WCAG 2.2 AA)

Audited from the pasted HTML source only, on 2026-10-25. No browser, scanner or screen reader ran. Every verdict below is a static reading of the source and says so; rendered checks are marked not checked.

## 1. Scope

- **Target**: WCAG 2.2 AA (W3C Recommendation, https://www.w3.org/TR/WCAG22/).
- **Blocking threshold**: not asked, no team contact in this session. Assumption for this reply only: Critical and High severity block a release. The team replaces this line with its own answer.
- **Versions**: build is the HTML as pasted, no version marker. `@axe-core/playwright` and axe-core: not run. Browser: none.
- **Severity scale**: the `/qa-defect` scale (Critical, High, Medium, Low), set by the impact on this page's users. Where axe has a fixed impact rating for a rule it is quoted separately, because the two scales measure different things.

Pages x states:

| Page | State | Audited |
| --- | --- | --- |
| Sign up (URL not in source; assumed `/signup`) | default (also the empty state: no prefilled values) | Yes, from source |
| Sign up | focus on `#email` (first) | From source only: no focus indicator (A11Y-SIGNUP-006) |
| Sign up | focus on the password input | From source only: same |
| Sign up | focus on `#terms` | From source only: same |
| Sign up | focus on "Read the terms" | From source only: reached first in tab order (A11Y-SIGNUP-007) |
| Sign up | focus on "Create account" | Not reachable: the element is a `div` (A11Y-SIGNUP-008) |
| Sign up | loading | Not present in source. Not audited |
| Sign up | validation error | No client-side error state exists: no `required`, no `minlength`, and `form.submit()` skips native validation. Server response unknown. Not audited |
| Sign up | success | Post-submit page unknown. Not audited |
| Sign up | modal open | No modal in source. Not applicable |

Viewports: 1440 x 900, one narrow viewport (assumed 360 x 800), and 200% zoom. None rendered, so all three are not audited. Note for the narrow run: the page has no `<meta name="viewport">`, so a phone lays it out at desktop width.

## 2. Automated scan

Not run. Tag list to use when it runs: `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`, one raw JSON per page and state. The table below is what the source predicts; confirm every row against the raw results, because rule coverage depends on the axe-core version.

| Group | Predicted content |
| --- | --- |
| `violations` | `html-has-lang` (axe impact serious) on `html`. `image-alt` (axe impact critical) on the logo |
| `incomplete` | Cannot be predicted from source. Read the file; each item needs a verdict in step 3 |
| `passes` (automated pass, not conformance) | `document-title`. `color-contrast` for `h1` (#222 on #fff, 15.9:1), `.hint` (#595959 on #fff, 7.0:1) and `.btn` (#fff on #0a58ca, 6.4:1). `label` on the checkbox (wrapping label). `label` on the email and password inputs is also expected to pass in recent axe-core versions, because the rule accepts a non-empty placeholder. That pass is the trap this audit exists for: see A11Y-SIGNUP-003. `link-name` |
| `inapplicable` | Media, frame, table, list, ARIA-attribute and timing rules: the page has none of those elements |
| Not run under these tags | `tabindex` and `region` are tagged best-practice, so the positive `tabindex` is not reported. `duplicate-id-active` is deprecated since 4.1.1 Parsing was removed, so the duplicate `id` is not reported |

## 3. Manual checks

"Pass (source)" and "fail (source)" mean decided by reading the HTML and CSS. They need a browser confirmation before they are evidence.

| Criterion | Verdict | Page and state | Evidence or reason |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | Fail (source) | default | Logo has no `alt`; a screen reader falls back to the file name. A11Y-SIGNUP-002 |
| 1.3.1 Info and Relationships | Fail (source) | default | Hint "At least 8 characters." is not tied to the password input. A11Y-SIGNUP-004 |
| 1.3.5 Identify Input Purpose | Fail (source) | default | No `autocomplete` on email or password. A11Y-SIGNUP-010 |
| 1.4.3 Contrast (Minimum) | Pass (source) for the three authored colours; not checked for placeholder text and native control colours | default | Ratios in step 2. Placeholder colour is a browser default and must be measured in each browser |
| 1.4.4 Resize Text | Not checked | all | Needs rendering. Source has no fixed heights or widths, so no clipping is predicted |
| 1.4.11 Non-text Contrast | Fail (source) for the focus indicator; not checked for input borders | focus on each control | The focus indicator is removed, so it has no contrast at all. Borders are browser defaults. A11Y-SIGNUP-006 |
| 2.1.1 Keyboard | Fail (source) | default | The submit control is a `div` and implicit submission on Enter is blocked by the two text-type fields. No keyboard path submits the form. A11Y-SIGNUP-008 |
| 2.1.2 No Keyboard Trap | Pass (source) | all | No script moves or holds focus; no modal |
| 2.4.3 Focus Order | Fail (source) | default | `tabindex="3"` puts the terms link before every field. A11Y-SIGNUP-007 |
| 2.4.7 Focus Visible | Fail (source) | focus on each control | Global `:focus { outline: none; }` with no replacement style. A11Y-SIGNUP-006 |
| 2.4.11 Focus Not Obscured (Minimum) | Pass (source) | all | No sticky, fixed or overlaid content |
| 2.5.7 Dragging Movements | Not applicable | default | Nothing requires dragging |
| 2.5.8 Target Size (Minimum) | Not checked | default | Needs rendered geometry. Expected: the button is about 26 px tall at the default font, the checkbox is user-agent sized (exempt), the inline link should meet the spacing exception |
| 3.1.1 Language of Page | Fail (source) | default | No `lang` on `html`. A11Y-SIGNUP-001 |
| 3.2.1 On Focus, 3.2.2 On Input | Pass (source) | default | No focus or change handlers |
| 3.2.6 Consistent Help | Not checked | n/a | No help mechanism on this page; needs the set of pages |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Not checked | validation error | No client-side error can occur. `form.submit()` also suppresses the browser's own email-format message. Server behaviour unknown |
| 3.3.2 Labels or Instructions | Fail (source) | default | Email and password have placeholders only; the visible label vanishes once the user types. A11Y-SIGNUP-003 |
| 3.3.7 Redundant Entry | Pass (source) for this step; not checked for the return from `/terms` | default | Nothing is asked twice. The terms link leaves the page in the same tab; whether typed data survives the return is a browser matter to test |
| 3.3.8 Accessible Authentication (Minimum) | Not applicable (assumption) | default | This page creates credentials rather than authenticates. Nothing in source blocks paste or a password manager |
| 4.1.2 Name, Role, Value | Fail (source) | default | "Create account" is a `div` with no role, no focusability and no button name. A11Y-SIGNUP-009 |

Checklist from the reference:

| Check | Verdict | Reason |
| --- | --- | --- |
| Tab test | Fail (source) | Predicted order: terms link, email, password, checkbox. The submit control is never reached and no stop shows an indicator. Confirm in a browser |
| Modal trap | Not applicable | No modal |
| Colour-blindness simulation | Not checked | Needs rendering. From source nothing relies on colour alone; the link keeps the browser's default underline |
| Screen reader | Not checked | No person with a screen reader ran the page |

## 4. Findings

Split into two tables keyed by ID so they stay readable. Evidence is not captured for any row: there was no browser. The file to capture when a build exists is `A11Y-SIGNUP-NNN-<state>.png` at 1440 x 900 with pointer and case label.

| ID | Criterion | Page and state | Element | Source | Severity | Blocks (assumed threshold) |
| --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 3.1.1 Language of Page | Sign up, default | `html` | axe `html-has-lang` (predicted, impact serious) | High | Yes |
| A11Y-SIGNUP-002 | 1.1.1 Non-text Content | Sign up, default | `img[src="/img/logo-2024-final.png"]` | axe `image-alt` (predicted, impact critical) | Medium | No |
| A11Y-SIGNUP-003 | 3.3.2 Labels or Instructions (also 1.3.1) | Sign up, default and while typing | `input[type="email"]`, `input[type="password"]` | Manual. axe `label` is expected to pass on the placeholder | Medium | No |
| A11Y-SIGNUP-004 | 1.3.1 Info and Relationships | Sign up, default | `p.hint` and `input[type="password"]` | Manual | Medium | No |
| A11Y-SIGNUP-005 | None of its own (4.1.1 removed in WCAG 2.2). Blocks the fixes for 003 and 004 | Sign up, default | `input[type="password"][id="email"]` | Manual. axe `duplicate-id-active` deprecated | Medium | No |
| A11Y-SIGNUP-006 | 2.4.7 Focus Visible (and 1.4.11 as a consequence) | Sign up, focus on each control | `:focus { outline: none; }` in the page stylesheet | Manual | High | Yes |
| A11Y-SIGNUP-007 | 2.4.3 Focus Order | Sign up, default | `a[href="/terms"][tabindex="3"]` | Manual. axe `tabindex` is best-practice only | Medium | No |
| A11Y-SIGNUP-008 | 2.1.1 Keyboard | Sign up, default | `div.btn[onclick="submitForm()"]` | Manual | Critical | Yes |
| A11Y-SIGNUP-009 | 4.1.2 Name, Role, Value | Sign up, default | `div.btn[onclick="submitForm()"]` | Manual | Critical | Yes |
| A11Y-SIGNUP-010 | 1.3.5 Identify Input Purpose | Sign up, default | `input[type="email"]`, `input[type="password"]` | Manual. axe `autocomplete-valid` checks only values that exist | Low | No |

| ID | Observed | Expected | User impact | Suggested fix |
| --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | `<html>` has no `lang` | `<html lang="en">` (assumption: the copy is English) | Screen readers may pick the wrong voice and pronunciation rules for the whole page | Add `lang="en"` to `html` |
| A11Y-SIGNUP-002 | Logo has no `alt` | `alt` naming the organisation, or `alt=""` if purely decorative | Screen reader users hear "logo-2024-final.png, image" or just "image" | Add `alt="<Organisation name>"` (assumption: the logo identifies the site) |
| A11Y-SIGNUP-003 | Only a placeholder names each field | A visible `<label for>` that stays while typing | Sighted users lose the field name once they type; after autofill they cannot tell which field holds what. Screen readers get the placeholder as a fallback name only | Add `<label for="email">Email</label>` and `<label for="password">Password</label>`; keep the placeholder as an example at most |
| A11Y-SIGNUP-004 | The hint is a free-standing paragraph | The hint is referenced from the password input | Screen reader users in forms mode never hear the length rule and submit a password that will be rejected | Give the hint an `id` and add `aria-describedby` on the password input, after fixing 005 |
| A11Y-SIGNUP-005 | Two elements carry `id="email"` | Each `id` unique | Any `label for`, `aria-describedby` or script targeting the password binds to the email field instead | Rename the password input's `id` to `password` |
| A11Y-SIGNUP-006 | Outline removed on every element, no `:focus-visible` style | A visible indicator with 3:1 contrast on every focus stop | Sighted keyboard users cannot see where they are | Delete the rule, or replace it with a `:focus-visible` style, for example `outline: 2px solid #0a58ca; outline-offset: 2px` |
| A11Y-SIGNUP-007 | Link has `tabindex="3"`, so it is the first tab stop | Tab order follows reading order: email, password, checkbox, link, button | Keyboard users land on the terms link before the form and lose the reading sequence | Remove `tabindex` |
| A11Y-SIGNUP-008 | Submit control is a `div` with `onclick`; Enter in a field does not submit because two text-type fields block implicit submission | A native submit control operable by Enter and Space | Keyboard-only users cannot create an account at all | Replace with `<button type="submit">Create account</button>`; drop the inline handler and the `.submit()` call |
| A11Y-SIGNUP-009 | Same element has no role and no focusability | Role button with name "Create account" | Screen reader users hear plain text, cannot find a button and cannot activate it | Same fix as 008 |
| A11Y-SIGNUP-010 | No `autocomplete` on either input | `autocomplete="email"` and `autocomplete="new-password"` | Users who rely on autofill or a password manager get heuristic filling or none | Add the two attributes |

Related risk, not a WCAG finding: `form.submit()` bypasses constraint validation and the `submit` event, and the hint's 8-character rule is not enforced by `minlength`. Fixing 008 with a real submit button restores native validation, which then creates a validation-error state that must be audited for 3.3.1 and 3.3.3.

## 5. What this audit can claim

No automated scan ran, so there is no statement about `violations` on this page. The predicted axe results in step 2 are predictions until the raw JSON exists.

The page is not conformant to WCAG 2.2 AA. Reading the source alone establishes failures of 1.1.1, 1.3.1, 1.3.5, 2.1.1, 2.4.3, 2.4.7, 3.1.1, 3.3.2 and 4.1.2. Fixing every finding above does not make the page conformant either, because the criteria below were not checked.

- **Checked by scanner**: none.
- **Checked by reading the source**: 1.1.1, 1.3.1, 1.3.5, 1.4.3 (authored colours only), 1.4.11 (focus indicator only), 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11, 3.1.1, 3.2.1, 3.2.2, 3.3.2, 3.3.7 (this step only), 4.1.2. Not applicable from source: 2.5.7, 3.3.8 (assumption stated above).
- **Not checked at all**: 1.4.3 for placeholder and native control colours, 1.4.4, 1.4.10, 1.4.11 for input borders, 1.4.12, 2.4.1, 2.5.8, 3.2.3, 3.2.4, 3.2.6, 3.3.1, 3.3.3, 3.3.4, 4.1.3, the colour-blindness simulation, and the screen reader pass.
- **Pages and states not audited**: loading, validation error, success, the narrow viewport, 200% zoom, and the `/terms` page the link opens.

No conformance score is given. Evidence files and recordings: none exist, and `check-test-evidence.sh` was not run because no audit specs were written. The `code-style-qa` rule was not applied because no test code was written.
