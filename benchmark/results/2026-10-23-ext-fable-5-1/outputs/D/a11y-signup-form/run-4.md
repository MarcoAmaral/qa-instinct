# Accessibility audit: Sign-up page (`Sign up`)

Audit date: 2026-10-25. Standard: WCAG 2.2 AA (W3C Recommendation, https://www.w3.org/TR/WCAG22/). Method: static review of the HTML source only. No browser, no scanner, no assistive technology and no screenshot was involved. Every verdict below is a reading of the source, and every "predicted axe result" is what the scanner is expected to report once it runs, not a result it produced.

## 1. Scope

| Item | Value |
| --- | --- |
| Target | WCAG 2.2 AA (no other level stated by the team) |
| Blocking threshold | Not set by the team. **Assumption for this report:** Critical and High block a release. The team confirms or replaces this; the severity of each finding is given so the threshold can be re-applied. |
| Build or date seen | No build identifier. Source as pasted on 2026-10-25. Logo file name mentions "2024-final". |
| `@axe-core/playwright` / axe-core | Not run. Versions unknown. |
| Browser | None opened. |
| Evidence checker | `check-test-evidence.sh` not run: no specs and no evidence files were produced. |

Pages x states (one page):

| Page | State | Audited? | How |
| --- | --- | --- | --- |
| Sign up | Default | Yes | Static source review |
| Sign up | Focus on email | Yes | Static (focus style read from CSS; no render) |
| Sign up | Focus on password | Yes | Static |
| Sign up | Focus on "I accept the terms" checkbox | Yes | Static |
| Sign up | Focus on "Read the terms" link | Yes | Static |
| Sign up | Focus on "Create account" | Not reachable | The control is a `div`; it never receives focus (finding A11Y-SIGNUP-001) |
| Sign up | Validation error | Not audited | No client-side error state exists: no `required`, and `form.submit()` bypasses constraint validation on `type="email"`. Server response unknown. |
| Sign up | Loading, success, modal open | Not audited | No such state in the source |
| Sign up | 1440 x 900 viewport | Not audited | No render |
| Sign up | Narrow viewport | Not audited | No render. Note: no `<meta name="viewport">`, so mobile browsers will lay the page out at desktop width. |
| Sign up | 200% zoom (1.4.4) | Not audited | No render. Nothing in the CSS fixes a height or hides overflow, so clipping is unlikely but unverified. |

Assumptions, continued: the logo is informative (it identifies the site, and nothing else on the page names the organisation). The page language is English. There is no other page in the sign-up process visible to this audit.

## 2. Automated scan

**Not run.** The template in the `qa-reference` skill's `references/accessibility-checks.md` would be run with tags `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`, one raw JSON per state. The table below predicts the four groups from the source so the real run can be checked against it. Rule IDs follow axe-core 4.x; confirm in the raw results which IDs actually ran.

| Group | Predicted content | Note |
| --- | --- | --- |
| `violations` | `html-has-lang` (`<html>`), `image-alt` (`img[src="/img/logo-2024-final.png"]`) | Both become findings below |
| `incomplete` | Possibly `color-contrast` on the native input borders and placeholder (UA colours, not in the author CSS) | Each gets a manual verdict below |
| `passes` (automated pass, not conformance) | `document-title`, `label` (axe accepts a non-empty `placeholder` as an accessible name, so the two inputs will **pass** this rule despite having no label; see A11Y-SIGNUP-004), `color-contrast` on body text, hint and button text, `page-has-heading-one` if best-practice tags are added | A green `label` rule here is the exact trap this audit exists for |
| `inapplicable` | Video, audio, frames, tables, ARIA state rules, `autocomplete-valid` (no `autocomplete` attribute present, so the rule has nothing to check) | The page never exercises these |
| Not covered by the tag list | `tabindex` (positive `tabindex`) is tagged `best-practice`, not `wcag*`, so the scan **will not report** `tabindex="3"` with these tags. The duplicate `id` rules are tied to the obsolete 4.1.1 and are disabled in current axe-core. | Both handled by hand below |

## 3. Manual checks

All verdicts are from the source. "Pass (static)" means nothing in the source can cause a failure; it is not an observation of a running page.

| Criterion | Page and state | Verdict | Evidence / reasoning |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | Default | Fail | Logo `<img>` (line 14) has no `alt`. Screen readers will read the file name "logo-2024-final.png" or skip the image. A11Y-SIGNUP-002 |
| 1.3.1 Info and Relationships | Default, focus on password | Fail | Hint "At least 8 characters." (line 19) is a loose `<p>`; no `aria-describedby` ties it to the password field. A11Y-SIGNUP-005 |
| 1.3.5 Identify Input Purpose | Default | Fail | Email and password fields collect user data from the 1.3.5 purpose list and carry no `autocomplete`. A11Y-SIGNUP-008 |
| 1.4.3 Contrast (Minimum) | Default | Pass (author colours); not checked (UA colours) | Computed from the CSS: body `#222` on `#fff` 15.9:1; hint `#595959` on `#fff` 7.0:1 at 14.4 px; button `#fff` on `#0a58ca` 6.4:1. Placeholder colour is the browser default and was not measured. Chromium's default placeholder colour is `darkgray` (`#a9a9a9`, about 2.3:1 on white); since the placeholder is the only visible label, see A11Y-SIGNUP-004. |
| 1.4.4 Resize Text | 200% zoom | Not checked | No render |
| 1.4.11 Non-text Contrast | Focus on each control | Fail | `:focus { outline: none; }` (line 9) removes the indicator entirely; there is nothing to measure. Input borders are UA defaults, not measured. A11Y-SIGNUP-003 |
| 2.1.1 Keyboard | Default | Fail | "Create account" is a `div` with `onclick` (line 22): not focusable, no key handler. Implicit submission on Enter does not apply because the form has two text-type fields and no submit button. A keyboard user cannot submit. A11Y-SIGNUP-001 |
| 2.1.2 No Keyboard Trap | Default | Pass (static) | No script intercepts keys; no modal |
| 2.4.3 Focus Order | Default | Fail | `tabindex="3"` on "Read the terms" (line 21) puts the link **first** in tab order, before the email field; visual order is email, password, checkbox, link. A11Y-SIGNUP-006 |
| 2.4.7 Focus Visible | Focus on each control | Fail | Global `:focus { outline: none; }` with no `:focus-visible` replacement. A11Y-SIGNUP-003 |
| 2.4.11 Focus Not Obscured (Minimum) | Default | Pass (static) | No sticky, fixed or overlaying author content |
| 2.5.7 Dragging Movements | Default | Inapplicable | No dragging interaction |
| 2.5.8 Target Size (Minimum) | Default | Not checked (estimate: pass) | Button: 16 px font plus 4 px vertical padding gives roughly 26 px height at a normal line height, above 24 px but not measured. Checkbox is wrapped by its label, so the label text is part of the target. The link is inline text (exception applies). |
| 3.1.1 Language of Page | Default | Fail | `<html>` (line 2) has no `lang`. A11Y-SIGNUP-007 |
| 3.2.1 On Focus, 3.2.2 On Input | Focus on each control | Pass (static) | No focus, change or input handlers |
| 3.2.6 Consistent Help | Default | Not checked | Single page; no help mechanism present; other pages not seen |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Validation error | Not checked | No error state exists client-side (see scope). Server behaviour unknown. Observation: `form.submit()` skips the `type="email"` validation the markup implies; worth a separate functional defect. |
| 3.3.2 Labels or Instructions | Default, focus on email and password | Fail | Only `placeholder` names the two inputs; it disappears once the user types. A11Y-SIGNUP-004 |
| 3.3.7 Redundant Entry | Default | Not checked | Only one step of the process is visible |
| 3.3.8 Accessible Authentication (Minimum) | Default | Not checked | This page creates credentials rather than authenticating; the sign-in page was not seen. Missing `autocomplete` (A11Y-SIGNUP-008) weakens password-manager support on the later sign-in. |
| 4.1.2 Name, Role, Value | Default | Fail | "Create account" has role generic, no accessible role of button. A11Y-SIGNUP-001. Duplicate `id="email"` on both inputs (lines 17 and 18) means any `for`, `aria-describedby` or `aria-labelledby` pointing at `email` resolves to the email field only. A11Y-SIGNUP-009 |

Manual checklist from `accessibility-checks.md`:

| Check | Verdict | Note |
| --- | --- | --- |
| Tab test | Fail (static) | Predicted order: link, email, password, checkbox; button never reached; no indicator visible at any step |
| Modal trap test | Inapplicable | No modal |
| Colour-blindness simulation | Not checked | No render. Nothing in the source conveys meaning by colour alone; the link has UA default underline. |
| Screen reader pass | Not checked | No screen reader session was run. Heading structure is a single `h1`, which is sound. |

## 4. Findings

Element locators are CSS plus the line number in the pasted source. Evidence is "none" for every row: no viewport screenshot could be taken. Severity per `/qa-defect`. "Blocks" applies the assumed threshold (Critical and High) and must be re-read once the team sets its own.

| ID | Criterion | Page and state | Element | Observed / expected | User impact | Source | Evidence | Suggested fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 2.1.1 Keyboard; 4.1.2 Name, Role, Value | Sign up, default | `div.btn[onclick]`, line 22 | Observed: submit control is a `div` with `onclick`, not focusable, no role. Expected: a native submit button reachable by Tab, activated by Enter or Space, announced as "button". | Keyboard-only and screen-reader users cannot create an account at all. Switch and voice-control users cannot target it by name as a button. | manual (keyboard mapping; axe has no WCAG-tagged rule for this) | none | Replace with `<button type="submit">Create account</button>` and drop the inline script | **Critical**, blocks |
| A11Y-SIGNUP-002 | 1.1.1 Non-text Content | Sign up, default | `img[src="/img/logo-2024-final.png"]`, line 14 | Observed: no `alt`. Expected: `alt` naming the organisation (assumed informative), or `alt=""` if the team decides it is decorative. | Screen-reader users hear a file name or nothing; the page never says whose service this is. | `image-alt` (predicted) | none | Add `alt="<Organisation name>"` | Medium |
| A11Y-SIGNUP-003 | 2.4.7 Focus Visible; 1.4.11 Non-text Contrast | Sign up, focus on each control | `:focus` rule, line 9 | Observed: `outline: none` globally, no replacement. Expected: a visible indicator of at least 3:1 against adjacent colours on every focusable element. | Sighted keyboard users cannot see which field they are in; combined with 001 they cannot tell whether the form can be submitted. | manual | none | Delete the rule, or replace with `:focus-visible { outline: 2px solid #0a58ca; outline-offset: 2px; }` | **High**, blocks |
| A11Y-SIGNUP-004 | 3.3.2 Labels or Instructions; 1.3.1; 1.4.3 (placeholder) | Sign up, default and focus on email and password | `input[type=email]`, line 17; `input[type=password]`, line 18 | Observed: placeholder is the only label; it vanishes on input; its colour is the browser default. Expected: a persistent visible `<label for>` for each field; placeholder, if kept, is supplementary. | Users with memory or attention impairments lose the field's purpose after typing. Some assistive technologies do not use placeholder as a name. Low-contrast placeholder is hard to read for low-vision users. | manual (axe `label` rule is predicted to pass because of the placeholder) | none | Add `<label for="email">Email</label>` and `<label for="password">Password</label>`; give the password field its own id | **High**, blocks |
| A11Y-SIGNUP-005 | 1.3.1 Info and Relationships | Sign up, focus on password | `p.hint`, line 19 | Observed: hint is not associated with the password field. Expected: the field references it via `aria-describedby`. | Screen-reader users are not told the length rule when they reach the field, then fail without knowing why. | manual | none | Give the hint an id and set `aria-describedby="password-hint"` on the password input | Medium |
| A11Y-SIGNUP-006 | 2.4.3 Focus Order | Sign up, default | `a[href="/terms"][tabindex="3"]`, line 21 | Observed: positive `tabindex` moves the link to the front of the tab order. Expected: natural DOM order (email, password, checkbox, link, button). | Keyboard users land on the terms link before the first field; the order contradicts the visual layout. | manual (axe `tabindex` rule is best-practice only and would not fire under the WCAG tag list) | none | Remove `tabindex="3"` | Medium |
| A11Y-SIGNUP-007 | 3.1.1 Language of Page | Sign up, default | `html`, line 2 | Observed: no `lang`. Expected: `lang="en"` (assumed English). | Screen readers may read the page with the wrong pronunciation rules; translation tools misdetect the language. | `html-has-lang` (predicted) | none | `<html lang="en">` | Medium |
| A11Y-SIGNUP-008 | 1.3.5 Identify Input Purpose | Sign up, default | `input[type=email]`, line 17; `input[type=password]`, line 18 | Observed: no `autocomplete`. Expected: `autocomplete="email"` and `autocomplete="new-password"`. | Users who rely on browser autofill or password managers must type both values; people with motor or cognitive impairments are most affected. | manual (axe `autocomplete-valid` only checks values that are present) | none | Add the two `autocomplete` attributes | Medium |
| A11Y-SIGNUP-009 | 4.1.2 Name, Role, Value (association integrity) | Sign up, default | `input[type=password]#email`, line 18 | Observed: `id="email"` is used twice. Expected: unique ids so label and description references resolve to the right field. | No direct failure today because nothing references the id, but the fixes for 004 and 005 will bind to the wrong field until this is corrected. | manual (duplicate-id rules are disabled in current axe-core because 4.1.1 is obsolete) | none | Rename to `id="password"` | Low |

Corrected markup for the form, for the developer picking up 001, 004, 005, 006, 008 and 009 together:

```html
<html lang="en">
...
<img src="/img/logo-2024-final.png" alt="Organisation name">
<form id="signup">
  <label for="email">Email</label>
  <input type="email" id="email" name="email" autocomplete="email" required>
  <label for="password">Password</label>
  <input type="password" id="password" name="password" autocomplete="new-password"
         aria-describedby="password-hint" minlength="8" required>
  <p class="hint" id="password-hint">At least 8 characters.</p>
  <label><input type="checkbox" id="terms" name="terms" required> I accept the terms</label>
  <a href="/terms">Read the terms</a>
  <button type="submit" class="btn">Create account</button>
</form>
```

Using a native submit button also restores constraint validation, which enables the validation-error state that this audit could not cover.

## 5. What this audit can and cannot claim

**No automated scan was run.** The predicted `violations` (`html-has-lang`, `image-alt`) and the predicted `passes` are expectations from the source, to be confirmed by a real run with the tag list in section 2. The real run must be read for all four groups; in particular the `label` rule is expected to pass and must not be taken as proof that the fields are labelled.

**The page is not conformant to WCAG 2.2 AA.** Nine findings stand from the source alone, two of them at the assumed blocking severity and one Critical. This is a statement about the criteria listed as "Fail" above, each tied to a line of source; it does not depend on a render.

**No statement of conformance is made for the criteria that passed.** "Pass (static)" means the source contains nothing that can fail the criterion; it is not an observation of the running page in any browser.

Checked by scanner: none.

Checked by hand (static source review): 1.1.1, 1.3.1, 1.3.5, 1.4.3 (author colours only), 1.4.11, 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11, 2.5.7, 3.1.1, 3.2.1, 3.2.2, 3.3.2, 4.1.2, and the tab test and modal test of the manual checklist.

Not checked at all: 1.4.3 for UA-default colours (placeholder, input borders), 1.4.4, 1.4.10, 2.5.8, 3.2.6, 3.3.1, 3.3.3, 3.3.7, 3.3.8, colour-blindness simulation, and the screen-reader pass.

Pages and states not audited: validation error, loading, success, modal, the narrow viewport, 200% zoom, and the 1440 x 900 default viewport as rendered. Any other page of the sign-up process.

Evidence: none. No screenshot meets the `test-evidence` rule because none was taken; `check-test-evidence.sh` was not run. The next step is to run the axe template against the deployed page in the three viewports, keep the raw JSON per state, re-check every row above against it, and attach viewport screenshots to each finding.
