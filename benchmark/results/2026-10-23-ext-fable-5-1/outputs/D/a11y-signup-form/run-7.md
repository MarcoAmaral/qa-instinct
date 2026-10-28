# Accessibility audit: Sign-up page (source review only)

**Status of this audit.** The page was audited from its HTML source alone. No browser, no `@axe-core/playwright` run, no screenshots, no screen reader. Every verdict below is a static reading of the source and is labelled "source". Anything that needs a rendered page is "not checked". The raw axe JSON files this skill normally keeps do not exist for this audit. This document is the content that would go in `a11y/audit.md`; no file was written, as instructed.

## 1. Scope

| Item | Value |
| --- | --- |
| Target | WCAG 2.2 AA (W3C Recommendation, https://www.w3.org/TR/WCAG22/) |
| Blocking threshold | Not provided by the team. Recorded as **not set**. Findings carry the axe impact (where an axe rule exists) and the package severity so the team can apply its threshold once chosen. No finding below is marked blocking or non-blocking. |
| Page | Sign up. Route assumed `/signup` (not in the source). |
| Viewports | 1440 x 900, one narrow viewport (360 x 800 assumed), 200% zoom: **none run**. The source has no `<meta name="viewport">`, so the narrow-viewport result cannot be predicted from the source. |
| Versions | Build: the pasted source, received 2026-10-25. `@axe-core/playwright`, axe-core and browser: **not run, versions unknown**. Rule IDs named below are from axe-core 4.8 and later; confirm in the raw results when the scan runs. |

### Pages x states

| Page | State | Audited? | How |
| --- | --- | --- | --- |
| Sign up | Default | Yes | Source |
| Sign up | Empty (nothing typed) | Yes | Source. Identical to default: the page has no `required` attributes and no client-side validation. |
| Sign up | Loading | Not applicable | No asynchronous content in the source. |
| Sign up | Validation error | **Not audited** | No client-side error state exists: `submitForm()` calls `form.submit()`, which skips constraint validation, so even `type="email"` is never enforced. The server-side error page is not in the source. |
| Sign up | Success | **Not audited** | Not in the source. |
| Sign up | Modal open | Not applicable | No modal. |
| Sign up | Focus on each control | Partly | Tab sequence derived from the source (section 3). Visual state of focus not checked: the page removes the indicator (A11Y-SIGNUP-003). |

## 2. Automated scan

**Not run.** The table below is what the template from the `qa-reference` skill's `accessibility-checks.md` is expected to return for this source, with the tag list `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`. It is a prediction, not a result. Two adaptations the scan will need:

- The template waits on `page.getByRole("main")`. This page has no `<main>` landmark, so that wait would time out. Wait on the level-1 heading "Create your account" instead.
- The axe `tabindex` rule (positive `tabindex`) and the `region` rule carry the `best-practice` tag only. Under the tag list above they **do not run**. The `tabindex="3"` defect is therefore a manual finding here, whatever the scan says.

| Group | Predicted content | What the audit does with it |
| --- | --- | --- |
| `violations` | `html-has-lang` on `<html>` (impact serious). `image-alt` on the logo `<img>` (impact critical). | Findings A11Y-SIGNUP-008 and A11Y-SIGNUP-007. |
| `incomplete` | None predicted. All text colours are flat hex values on a flat white background, so `color-contrast` should decide. Placeholder text is not a text node and, to my knowledge, is not evaluated by `color-contrast`; confirm in the raw results. | Placeholder contrast taken to the manual column (A11Y-SIGNUP-010). |
| `passes` | `document-title` ("Sign up"). `color-contrast` for the three declared pairs (section 3, 1.4.3). `label` on both inputs: axe accepts a non-empty `placeholder` as an accessible name, so the missing labels are **not** a predicted violation. `link-name` on "Read the terms". `duplicate-id-aria`: no ARIA reference points at the duplicated `id="email"`. | Recorded as automated pass for that rule on that element. Not written as conformant. The `label` pass is the scanner-green trap this audit exists for: see A11Y-SIGNUP-005. |
| `inapplicable` | `button-name` (the page has no `<button>` or `<input type="submit">`: that absence is finding 001). `autocomplete-valid` (no `autocomplete` attribute to validate: see 009). `meta-viewport` (no viewport meta). Video, audio, table, list, frame, ARIA-state and `meta-refresh` rules. | Listed so a reader sees what the page never exercised. |

## 3. Manual checks

Verdicts: **pass (source)**, **fail (source)**, **not checked**.

| Criterion | Verdict | Page and state | Evidence from the source |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | fail (source) | Default | Line 14: `<img src="/img/logo-2024-final.png">` has no `alt`. A screen reader announces the file name or "image". Finding 007. |
| 1.3.1 Info and Relationships | fail (source) | Default | Lines 17 to 19: no `<label>` for the email and password inputs; the hint "At least 8 characters." is not tied to the password field by `aria-describedby`. Findings 005 and 006. |
| 1.3.5 Identify Input Purpose | fail (source) | Default | Lines 17 and 18 collect an email and a new password with no `autocomplete` token. Finding 009. |
| 1.4.3 Contrast (Minimum) | pass (source) for declared colours; not checked for placeholders | Default | Computed from the stylesheet: body `#222` on `#fff` about 15.9:1; hint `#595959` on `#fff` about 7.0:1 at 14.4px normal text; button `#fff` on `#0a58ca` about 6.4:1. Placeholder colour is the browser default and not set by the page. Finding 010. |
| 1.4.4 Resize Text | not checked | Default | No fixed heights or widths in the CSS, so clipping is not expected, but needs a render at 200%. |
| 1.4.11 Non-text Contrast | fail (source) for focus; not checked for input borders | Focus on each control | The focus indicator is removed outright (line 9), so there is no indicator to measure. Input borders are browser defaults. Finding 003 covers the indicator under 2.4.7. |
| 2.1.1 Keyboard | fail (source) | Default, empty | Line 22: the only submit control is `<div onclick>`: not focusable, no key handler. There is no submit button, and a form with two implicit-submission-blocking fields (email, password) does not submit on Enter. **A keyboard-only user cannot create an account.** Finding 001. |
| 2.1.2 No Keyboard Trap | pass (source) | Default | No modal, no script that captures keys. |
| 2.4.3 Focus Order | fail (source) | Default | Line 21: `tabindex="3"`. Sequential focus puts positive `tabindex` first, so the Tab order is: "Read the terms" link, then email, password, checkbox. The button never receives focus. Finding 004. |
| 2.4.7 Focus Visible | fail (source) | Focus on each control | Line 9: `:focus { outline: none; }` with no `:focus-visible` replacement. No focused element is visible at any step. Finding 003. |
| 2.4.11 Focus Not Obscured (Minimum) | pass (source) | Default | No `position: fixed` or `sticky` content in the stylesheet. |
| 2.5.7 Dragging Movements | not applicable | Default | Nothing is dragged. |
| 2.5.8 Target Size (Minimum) | not checked | Default | From the source the button is about 26px high (16px text plus 8px padding) and the link is a standalone inline link on the same line as the checkbox label. Both look like they meet the size or spacing exception, but this needs a rendered layout. |
| 3.1.1 Language of Page | fail (source) | Default | Line 2: `<html>` has no `lang`. Finding 008. |
| 3.2.1 On Focus, 3.2.2 On Input | pass (source) | Default | No handlers on any input; only the div has `onclick`. |
| 3.2.6 Consistent Help | not applicable | Default | No help mechanism on the page; single page under audit. |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | not checked | Validation error | No client-side error state exists (section 1). The server response is not in the source. |
| 3.3.2 Labels or Instructions | fail (source) | Default, focus on email and password | Placeholder is the only label and disappears when the user types. Finding 005. |
| 3.3.7 Redundant Entry | pass (source) | Default | Single step; nothing is asked twice. |
| 3.3.8 Accessible Authentication (Minimum) | pass (source) | Default | This is account creation, not sign-in. Nothing blocks paste; `type="password"` lets a password manager fill the field. The missing `autocomplete="new-password"` (finding 009) weakens password-manager support but does not block it. |
| 4.1.2 Name, Role, Value | fail (source) | Default | Line 22: "Create account" has role generic, no name as a control, no state. A screen reader presents it as plain text. Finding 002. The checkbox (line 20) is inside its `<label>` and passes. |

### Checklist from `accessibility-checks.md`

| Check | Verdict | Notes |
| --- | --- | --- |
| Tab test | fail (source) | Predicted sequence: "Read the terms" link, email, password, checkbox. Submit control is skipped. Nothing shows focus at any step. |
| Modal trap test | not applicable | No modal. |
| Colour-blindness simulation | not checked | Nothing in the source conveys meaning by colour alone, but no simulation was run. |
| Screen reader | not checked | No screen reader pass was run. Heading structure from the source: one `<h1>`, nothing else; no landmarks; no live region, so a server error after submit would not be announced unless the server page handles it. |

## 4. Findings

| ID | Criterion | Page and state | Element | Observed / expected | User impact | Source | Evidence | Suggested fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 2.1.1 Keyboard | Sign up, default and empty | `div.btn[onclick="submitForm()"]`, line 22 | Observed: the only submit control is a `div`; it is not in the tab order and ignores Enter and Space. Enter inside a field does not submit because the form has no submit button and two blocking fields. Expected: the form submits from the keyboard. | Keyboard-only users, switch users and most screen reader users cannot create an account at all. | manual (2.1.1). No axe rule covers a clickable div. | none: source review, line 22 | Replace the div with `<button type="submit" class="btn">Create account</button>` and drop `onclick` and `submitForm()`. | Critical (complete feature failure). Threshold not set. |
| A11Y-SIGNUP-002 | 4.1.2 Name, Role, Value | Sign up, default | `div.btn`, line 22 | Observed: role generic, no accessible name as a control, no state. Expected: role button, name "Create account". | Screen reader users hear plain text and have no button to activate. | manual (4.1.2). axe `button-name` is inapplicable because no button element exists. | none: source review, line 22 | Same fix as 001. | Critical (same defect as 001; file as one ticket). Threshold not set. |
| A11Y-SIGNUP-003 | 2.4.7 Focus Visible (also 1.4.11) | Sign up, focus on each control | `:focus { outline: none; }`, line 9 | Observed: global rule removes the focus indicator on every element with no replacement. Expected: a visible indicator on every focusable element. | Sighted keyboard users cannot see where focus is on any of the four focusable elements. | manual (2.4.7). Not decidable by axe. | none: source review, line 9 | Delete the rule, or replace with a `:focus-visible` style of at least 3:1 against adjacent colours, for example a 2px solid `#0a58ca` outline with offset. | High (no workaround). Threshold not set. |
| A11Y-SIGNUP-004 | 2.4.3 Focus Order | Sign up, default | `a[href="/terms"][tabindex="3"]`, line 21 | Observed: positive `tabindex` moves the terms link to the first Tab stop, before the fields. Expected: Tab order follows the reading order. | Keyboard users land on a link before the form; combined with 003 they get no visual cue that this happened. | manual. The axe `tabindex` rule is `best-practice`-tagged and does not run under the WCAG tag list. | none: source review, line 21 | Remove the `tabindex` attribute. | Medium (workaround: keep tabbing). Threshold not set. |
| A11Y-SIGNUP-005 | 3.3.2 Labels or Instructions (also 1.3.1) | Sign up, default and focus on email and password | `input#email` (email) and the second `input` with the same id, lines 17 and 18 | Observed: placeholder is the only label; it vanishes once the user types. Expected: a visible, persistent `<label>` bound to each input. | Users with memory or attention impairments lose the field's purpose after typing. Screen readers get the placeholder as a name, which hides this from an axe `label` pass. | manual. axe `label` is a predicted pass because it accepts a non-empty placeholder; confirm in the raw results. | none: source review, lines 17 and 18 | Add `<label for="email">Email</label>` and `<label for="password">Password</label>`; give the password input `id="password"` (see note on the duplicate id below). Keep placeholders only as examples. | Medium. Threshold not set. |
| A11Y-SIGNUP-006 | 1.3.1 Info and Relationships | Sign up, focus on password | `p.hint`, line 19 | Observed: "At least 8 characters." is visually under the password field but not programmatically associated. Expected: the hint is announced with the field. | Screen reader users in forms mode never hear the password rule. | manual | none: source review, line 19 | Give the paragraph `id="password-hint"` and the password input `aria-describedby="password-hint"`. | Low. Threshold not set. |
| A11Y-SIGNUP-007 | 1.1.1 Non-text Content | Sign up, default | `img[src="/img/logo-2024-final.png"]`, line 14 | Observed: no `alt`. Expected: `alt` naming the organisation, or `alt=""` if the heading already carries the identity. | Screen reader users hear a file name or "image" at the top of the page on every visit. | axe `image-alt`, impact critical (predicted) | none: source review, line 14 | Add `alt="<Company name>"` or `alt=""` if decorative. | Medium. Threshold not set. |
| A11Y-SIGNUP-008 | 3.1.1 Language of Page | Sign up, default | `<html>`, line 2 | Observed: no `lang`. Expected: `<html lang="en">` (assumed English from the content). | Screen readers may read the page with the wrong pronunciation rules; translation tools misdetect the language. | axe `html-has-lang`, impact serious (predicted) | none: source review, line 2 | Add `lang="en"`. | Medium. Threshold not set. |
| A11Y-SIGNUP-009 | 1.3.5 Identify Input Purpose | Sign up, default | email and password inputs, lines 17 and 18 | Observed: no `autocomplete`. Expected: `autocomplete="email"` and `autocomplete="new-password"`. | Users who rely on autofill or a password manager get no reliable fill; browsers may autofill the current password into a new-password field. | manual. axe `autocomplete-valid` only validates tokens that are present. | none: source review, lines 17 and 18 | Add the two tokens. | Medium. Threshold not set. |
| A11Y-SIGNUP-010 | 1.4.3 Contrast (Minimum) | Sign up, empty | placeholder text of both inputs, lines 17 and 18 | Observed: placeholder colour is not set, so the browser default applies. Assumption to confirm by measurement: Chromium's default placeholder colour is `darkGray` (`#a9a9a9`), about 2.3:1 on white. Expected: 4.5:1, since the placeholder is currently the only label. | Low-vision users may not read the only label the field has. | manual; to confirm with a contrast measurement in the browser | none: assumption from the Chromium UA stylesheet, not measured | Fixing 005 makes the placeholder secondary; still set `::placeholder { color: #595959; }` or darker. | Low, pending measurement. Threshold not set. |

### Notes that are not WCAG 2.2 findings

- **Duplicate `id="email"`** on lines 17 and 18. 4.1.1 Parsing is obsolete in WCAG 2.2 and is not reported. It still matters: a `<label for="email">` added for finding 005 would bind to the first input only. Fix the id in the same change.
- **No `<main>` landmark.** The axe `region` rule is best-practice only. Adding `<main>` also lets the audit template's wait work unchanged.
- **No `<meta name="viewport">`.** Mobile browsers will render the page at a desktop layout width. This is why the narrow-viewport check and 1.4.10 Reflow are "not checked" rather than predicted.
- **Out of scope for this audit, flagged for the security review:** `form.submit()` bypasses constraint validation, and the form has no `method`, so the email and password are sent as GET query parameters.

## 5. What this audit can and cannot claim

**No automated scan was run.** The statement "no violations found by the automated scan" cannot be made for any page, state or rule.

**The page is not conformant to WCAG 2.2 AA** on the evidence of the source alone: findings 001 to 009 fail criteria 1.1.1, 1.3.1, 1.3.5, 2.1.1, 2.4.3, 2.4.7, 3.1.1, 3.3.2 and 4.1.2. The audit does not claim conformance for the remaining criteria, because not every criterion in the mapping was checked by the means it names. No score or percentage is given.

- **Checked by scanner:** none.
- **Checked by hand from the source:** 1.1.1, 1.3.1, 1.3.5, 1.4.3 (declared colours only), 1.4.11 (focus only), 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11, 3.1.1, 3.2.1, 3.2.2, 3.3.2, 3.3.7, 3.3.8, 4.1.2.
- **Not applicable on this page:** 2.5.7, 3.2.6.
- **Not checked at all:** 1.4.4 (200% zoom), 1.4.10 (narrow viewport), 1.4.11 for input borders, 2.5.8, 3.3.1, 3.3.3, placeholder contrast measurement (010), colour-blindness simulation, screen reader pass, and every WCAG 2.2 AA criterion not named in the mapping.
- **Pages and states not audited:** validation error, success, and any page other than sign-up.

**Next step to turn this into an audit with evidence:** deploy the page, run the template from `accessibility-checks.md` with the WCAG tag list on the default and empty states, keep the raw JSON per state, then do the not-checked rows above in a browser with a screen reader. Expect the scan to report only 007 and 008; the Critical finding 001 will not appear in `violations`, which is the reason the manual column exists.

**Rules not applied in this reply:** the `test-evidence` checker and the `code-style-qa` rule were not exercised because no specs or screenshots were produced; the `context-discovery` rule could not be applied because there is no repository, only the pasted source.
