# Accessibility audit: Sign-up page (WCAG 2.2 AA)

This is the content `a11y/audit.md` would hold. No file was written, per the request. The audit was done from the HTML source alone: nothing was rendered, no scanner ran, and no screenshot exists. Every verdict below is "by source review" unless it says otherwise, and the conclusion states what that does and does not allow the audit to claim.

## 1. Scope

| Item | Value |
| --- | --- |
| Target | WCAG 2.2 AA (W3C Recommendation, https://www.w3.org/TR/WCAG22/). Assumption: the team has not asked for a different level. |
| Blocking threshold | Not set by the team. Assumption used for the "blocks?" column: axe impact **critical** and **serious** block, **moderate** and **minor** do not. The team's answer replaces this; it was not chosen for them. |
| Build or date seen | Source pasted on 2026-10-25. No build number, commit or URL known. |
| Author | Marco (<account email, redacted>), QA |
| Browser | None run. Assumption for a later run: Chromium via Playwright. |
| `@axe-core/playwright` / axe-core | Not run. Assumption for a later run: current 4.10.x line. Rule IDs cited below are from that line and must be confirmed against the raw results, since coverage changes by version. |

### Pages x states

| Page | State | Audited? | How |
| --- | --- | --- | --- |
| Sign-up (`/`, assumed) | Default | Yes | Source review only |
| Sign-up | Focus on email field | Yes | Source review only |
| Sign-up | Focus on password field | Yes | Source review only |
| Sign-up | Focus on terms checkbox | Yes | Source review only |
| Sign-up | Focus on "Read the terms" link | Yes | Source review only |
| Sign-up | Focus on "Create account" | Not audited | The element cannot receive focus (finding A11Y-SIGNUP-003) |
| Sign-up | Validation error | Not audited | No client-side error state exists in the source (`form.submit()` skips constraint validation). Server-side error rendering is not in the source. |
| Sign-up | Loading | Not audited | No loading state in the source |
| Sign-up | Success (post-submit page) | Not audited | Not in the source |
| Sign-up | Modal open | Not applicable | No modal in the source |
| Terms page (`/terms`) | Any | Not audited | Not supplied |

### Viewports

| Viewport | Status |
| --- | --- |
| 1440 x 900 (evidence rule) | Not rendered |
| 375 x 812 (narrow) | Not rendered. Note: no `<meta name="viewport">`, so mobile browsers will render at a desktop width and shrink it. Reflow (1.4.10) not checked. |
| 200% zoom (1.4.4) | Not rendered. No fixed heights or widths in the CSS, so clipping is not expected, but this is not checked. |

## 2. Automated scan

**Status: not run.** There are no raw JSON files. The table below is what reading the source against the axe-core rule definitions predicts, so that the person who runs the scan knows what to confirm. A prediction is not a result.

Tag list to use (from the audit template): `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa`. Note that `best-practice` is **not** in that list, so the `tabindex`, `label-title-only`, `region` and `page-has-heading-one` rules will not run. Two of the real problems on this page sit behind those rules (see A11Y-SIGNUP-005 and -006), which is why the manual column matters here.

| Group | Expected content (to confirm) | What the audit does with it |
| --- | --- | --- |
| `violations` | `image-alt` on `img[src="/img/logo-2024-final.png"]` (critical). `html-has-lang` on `html` (serious). | Both are findings (A11Y-SIGNUP-001, -002). |
| `incomplete` | `color-contrast` is likely to decide all three text colours (all are solid on `#fff`), so no contrast item is expected here. `target-size` may report the checkbox and the inline link as needing review. | Each item gets a manual verdict in section 3 or is marked not checked. |
| `passes` | `label` on all three inputs (axe accepts a non-empty `placeholder` as an accessible name, so the two placeholder-only inputs **pass this rule**). `document-title`. `bypass` (an `h1` exists). `color-contrast` for body text, hint and button (computed below). `link-name`. | Recorded as automated pass for that rule on that element. Not "conformant". |
| `inapplicable` | `meta-viewport` (no viewport meta), `video-caption`, `audio-caption`, `frame-title`, `aria-*` rules (no ARIA), `autocomplete-valid` (no `autocomplete` attribute to validate, which is itself finding A11Y-SIGNUP-007), `duplicate-id-aria` (ids are duplicated but not referenced by ARIA). | Listed so a reader sees what the page never exercised. |

Note on duplicate ids: axe-core's `duplicate-id` and `duplicate-id-active` rules are deprecated and disabled by default since 4.1.1 Parsing was removed from WCAG 2.2. The scan is therefore expected to stay silent on `id="email"` appearing twice. See A11Y-SIGNUP-008.

### Contrast computed from the stylesheet (solid colours, so a scanner would decide them)

| Element | Foreground / background | Ratio | 1.4.3 threshold | Result |
| --- | --- | --- | --- | --- |
| Body text, `h1`, label text | `#222` / `#fff` | 15.9:1 | 4.5:1 | Pass |
| `.hint` (0.9rem, normal weight) | `#595959` / `#fff` | 7.0:1 | 4.5:1 | Pass |
| `.btn` "Create account" | `#fff` / `#0a58ca` | 6.4:1 | 4.5:1 | Pass |
| Placeholder text "Email", "Password" | User-agent default / `#fff` | Unknown | 4.5:1 | **Not checked.** The placeholder is the only visible label and its colour comes from the browser's stylesheet, which differs by browser. Measure it in the rendered page. |

## 3. Manual checks

Verdicts are "by source review" unless stated. "Not checked" means it needs a rendered page or a person with assistive technology.

| Criterion | Page and state | Verdict | Evidence and notes |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | Default | **Fail** | `img` has no `alt`. A screen reader will announce the file name or skip the image. Finding -001. |
| 1.3.1 Info and Relationships | Default, focus on password | **Fail** | The hint "At least 8 characters." is a loose `<p>`, not linked to the password field by `aria-describedby`. Covered in finding -005. |
| 1.3.5 Identify Input Purpose | Default | **Fail** | Email and password fields have no `autocomplete` (`email`, `new-password`). Finding -007. |
| 1.4.1 Use of Color | Default | Pass | Link keeps the user-agent underline (no `a` styling). No colour-only state. |
| 1.4.3 Contrast (Minimum) | Default | Partial pass | Three solid colours pass (table above). Placeholder colour not checked. |
| 1.4.4 Resize Text | 200% zoom | Not checked | No fixed sizes in the CSS; expectation is pass, not verified. |
| 1.4.10 Reflow | 320 CSS px | Not checked | No viewport meta; not rendered. |
| 1.4.11 Non-text Contrast | Focus on each control | **Fail** | `:focus { outline: none; }` removes the focus indicator on every element, so there is no indicator to measure. Input borders are user-agent defaults: not checked. Finding -004. |
| 2.1.1 Keyboard | Default, submit | **Fail** | "Create account" is a `div` with `onclick`: not focusable, no key handler. Enter in a text field does not submit either: the form has no submit button and two fields that block implicit submission (email and password), so the browser's implicit submission is suppressed. A keyboard-only user cannot complete sign-up. Finding -003. |
| 2.1.2 No Keyboard Trap | All | Pass | No scripts capture focus; no modal. |
| 2.4.3 Focus Order | Default | **Fail** | `tabindex="3"` puts "Read the terms" first in the tab order, before the email field. Tab sequence: link, email, password, checkbox, then out of the page. Finding -006. |
| 2.4.7 Focus Visible | Focus on each control | **Fail** | `:focus { outline: none; }` with no replacement `:focus-visible` style. Finding -004. |
| 2.4.11 Focus Not Obscured (Minimum) | All | Pass | No sticky, fixed or overlaid content. |
| 2.5.7 Dragging Movements | All | Not applicable | Nothing drags. |
| 2.5.8 Target Size (Minimum) | Default | Not checked | `.btn` is about 26 px tall (4 px padding x2 plus the line box), so it meets 24 px. The checkbox is a user-agent default (about 13 x 13 px) but its label text is part of the target. The link sits inline on the same line as the label; whether the spacing exception holds needs measurement in the rendered page. |
| 3.1.1 Language of Page | Default | **Fail** | `<html>` has no `lang`. Finding -002. |
| 3.2.1 On Focus, 3.2.2 On Input | All | Pass | No focus, change or input handlers in the source. |
| 3.2.6 Consistent Help | All | Not checked | Single page supplied; no help mechanism on it. Needs the other pages to compare. |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Validation error | **Fail / not checked** | No error state can occur client-side: `submitForm()` calls `form.submit()`, which bypasses constraint validation, so an empty or malformed email is sent without any message. Server-side errors are not in the source and are not checked. Finding -009. |
| 3.3.2 Labels or Instructions | Default, focus on email and password | **Fail** | Email and password have a placeholder only; it disappears when the user types, leaving no visible label. Finding -005. |
| 3.3.7 Redundant Entry | Default | Pass | Single step; nothing is asked twice. |
| 3.3.8 Accessible Authentication (Minimum) | Default | Pass (with a note) | This is account creation, not a login; choosing a password is not a recall or transcription test. Paste is not blocked and no CAPTCHA exists. Password-manager support is weakened by the missing `autocomplete` (finding -007) and the duplicate ids (finding -008). The actual sign-in page was not supplied and is not checked. |
| 4.1.2 Name, Role, Value | Default, submit | **Fail** | "Create account" has no role (`div`), so assistive technology exposes it as plain text, not a button. Finding -003. |

### Manual checklist from `accessibility-checks.md`

| Check | Verdict | Notes |
| --- | --- | --- |
| Tab test | Fail (by source) | Focus lands on link, email, password, checkbox, in that order, with no visible indicator at any step; it never lands on "Create account". |
| Modal trap test | Not applicable | No modal. |
| Colour-blindness simulation | Not checked | Not rendered. No colour-only information was found in the source, so a pass is expected. |
| Screen reader pass | **Not checked** | Needs a person with NVDA, VoiceOver or TalkBack. Expected announcements from the source: an image with a file name or nothing, two edit fields named by their placeholder, a checkbox "I accept the terms", a link, and the words "Create account" as static text. |

## 4. Findings

Severity is the `/qa-defect` scale (Critical, High, Medium, Low). "Blocks?" uses the provisional threshold from section 1 (axe critical or serious blocks) and must be re-read once the team sets its own. Evidence: no screenshot exists; the file name given is the one to capture at 1440 x 900 with pointer and case label when a build is available. `check-test-evidence.sh` was not run (no specs exist).

| ID | Criterion | Page / state | Element | Observed | Expected | User impact | Source | Evidence | Suggested fix | Severity / blocks? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | Sign-up / default | `img[src="/img/logo-2024-final.png"]` | No `alt` attribute. | A text alternative, or `alt=""` if the logo is decorative. | Screen reader users hear "logo-2024-final.png" or nothing, and cannot tell whose site this is. | axe `image-alt` (predicted) | `A11Y-SIGNUP-001-logo-1440x900.png` (to capture) | Add `alt="<Company> logo"`, or `alt=""` if the `h1` already carries the identity. | Medium (axe critical). Blocks under the provisional threshold. |
| A11Y-SIGNUP-002 | 3.1.1 Language of Page | Sign-up / default | `html` | No `lang` attribute. | `<html lang="en">` (assumption: the content is English). | Screen readers may read the page with the wrong voice and pronunciation rules. | axe `html-has-lang` (predicted) | `A11Y-SIGNUP-002-lang-1440x900.png` (to capture) | Add `lang="en"` to `<html>`. | Medium (axe serious). Blocks under the provisional threshold. |
| A11Y-SIGNUP-003 | 2.1.1 Keyboard; 4.1.2 Name, Role, Value | Sign-up / submit | `div.btn[onclick="submitForm()"]` | A `div` with a click handler: not focusable, no role, no Enter or Space handling. The form has no submit button, so Enter in a field does not submit either. | A real `<button type="submit">` that is focusable, announced as a button, and activated by Enter and Space. | Keyboard-only users, switch users and most screen reader users cannot create an account at all. No workaround. | manual, 2.1.1 keyboard check | `A11Y-SIGNUP-003-submit-1440x900.png` (to capture) | Replace the `div` with `<button type="submit" class="btn">Create account</button>` and drop `submitForm()`; the browser then validates and submits. | **Critical** (complete feature failure for keyboard users). Blocks. |
| A11Y-SIGNUP-004 | 2.4.7 Focus Visible; 1.4.11 Non-text Contrast | Sign-up / focus on each control | `:focus { outline: none; }` in the inline stylesheet | The focus indicator is removed on every element with no replacement style. | A visible focus indicator with at least 3:1 contrast against the adjacent colours. | Sighted keyboard users cannot see which control is active, on every step of the form. | manual, 2.4.7 | `A11Y-SIGNUP-004-focus-email-1440x900.png` (to capture, one per control) | Delete the rule, or replace it with `:focus-visible { outline: 2px solid #0a58ca; outline-offset: 2px; }`. | High. Blocks (the equivalent axe impact is serious). |
| A11Y-SIGNUP-005 | 3.3.2 Labels or Instructions; 1.3.1 Info and Relationships | Sign-up / default, focus on email and password | `input#email[type=email]`, `input[type=password]`, `p.hint` | Both inputs are labelled by `placeholder` only. The "At least 8 characters." hint is not associated with the password field. | A persistent visible `<label>` for each field; the hint tied to the password field with `aria-describedby`. | The visible label vanishes as soon as the user types, which harms users with memory or attention impairments. Screen reader users are not told the password rule when they reach the field. | manual. Note: axe's `label` rule is expected to **pass** these inputs because it accepts a non-empty placeholder; the `label-title-only` rule that would flag them is tagged best-practice and does not run with the WCAG tags. | `A11Y-SIGNUP-005-labels-1440x900.png` (to capture) | Add `<label for="email">Email</label>` and `<label for="password">Password</label>`; give the hint an `id` and set `aria-describedby` on the password field. Needs -008 fixed first. | Medium. Does not block under the provisional threshold; team to confirm. |
| A11Y-SIGNUP-006 | 2.4.3 Focus Order | Sign-up / default | `a[href="/terms"][tabindex="3"]` | Positive `tabindex` moves the link to the front of the tab order, before the email field. | Tab order matches reading order: email, password, checkbox, link, button. | Keyboard users land on the terms link first and must tab back into the form; the order contradicts the visual layout. | manual. Note: axe's `tabindex` rule is tagged best-practice and does not run with the WCAG tags; confirm in the raw results. | `A11Y-SIGNUP-006-taborder-1440x900.png` (to capture) | Remove `tabindex="3"`. | Medium. Does not block under the provisional threshold. |
| A11Y-SIGNUP-007 | 1.3.5 Identify Input Purpose | Sign-up / default | `input[type=email]`, `input[type=password]` | No `autocomplete` attribute on fields that collect an input purpose on the WCAG list. | `autocomplete="email"` and `autocomplete="new-password"`. | Password managers and browser autofill cannot reliably fill or save the fields; users with cognitive impairments lose the autofill support the criterion exists for. | manual (axe `autocomplete-valid` only checks values that are present) | `A11Y-SIGNUP-007-autocomplete-1440x900.png` (to capture) | Add the two `autocomplete` values. | Medium. Does not block under the provisional threshold. |
| A11Y-SIGNUP-008 | None (4.1.1 Parsing is obsolete in WCAG 2.2); prerequisite for fixing -005 | Sign-up / default | `input#email` (twice) | Both the email and the password input carry `id="email"`. | Unique ids. | A `<label for="email">` can only reach the first field, so the fix for -005 cannot be applied to the password field; `getElementById("email")` always returns the email input. | manual (axe's `duplicate-id` rules are deprecated and disabled; `duplicate-id-aria` does not fire because no ARIA references the id) | N/A: source defect, no visual | Rename the password field to `id="password"`. | Medium. Not a WCAG finding; log as a defect. |
| A11Y-SIGNUP-009 | 3.3.1 Error Identification; 3.3.3 Error Suggestion | Sign-up / validation error | `function submitForm()` | `form.submit()` bypasses constraint validation, so an empty form or a malformed email is sent with no message. No client-side error state exists. Server-side errors are not in the source. | Errors identified in text, tied to their field, and announced; a suggestion where one is known. | Any user can submit a broken form without being told why it failed; screen reader users get no announcement at all. | manual, 3.3.1 | N/A until an error state exists | Fixing -003 restores browser validation. Add `required` to the three fields and `minlength="8"` to the password; render server errors next to their field with `aria-describedby` and `role="alert"`. | Medium. Verdict on the server-side error state stays "not checked" until that page is supplied. |

Out of the audit's scope but seen in the source and worth a separate ticket: the form has no `method`, so it submits by GET and puts the password in the URL; and nothing enforces the terms checkbox.

## 5. Conclusion: what this audit can and cannot claim

**No automated scan ran.** The statement "no violations found by the automated scan" cannot be made for any page or state. Section 2 predicts two violations and names the rules the scan will not run.

**The page is not conformant to WCAG 2.2 AA.** That is the one claim the source alone supports, because source review shows failures of 1.1.1, 1.3.1, 1.3.5, 1.4.11, 2.1.1, 2.4.3, 2.4.7, 3.1.1, 3.3.2 and 4.1.2, and finding A11Y-SIGNUP-003 by itself stops a keyboard user from completing the task. No conformance score or percentage is given; the per-criterion table above is the record.

Checked and how:

- **By scanner:** none.
- **By hand from the source:** 1.1.1, 1.3.1, 1.3.5, 1.4.1, 1.4.3 (three solid colours only), 1.4.11 (focus indicator only), 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11, 3.1.1, 3.2.1, 3.2.2, 3.3.2, 3.3.7, 3.3.8 (on this page only), 4.1.2.
- **Not checked at all:** 1.4.3 for placeholder text, 1.4.4 at 200% zoom, 1.4.10 reflow, 1.4.11 for input borders, 2.5.8 target size, 3.2.6, 3.3.1 and 3.3.3 for the server-side error state, the colour-blindness simulation, and the screen reader pass. 2.5.7 is not applicable.
- **Pages and states not audited:** the validation error, loading and success states, "Create account" in the focused state (it cannot be focused), the `/terms` page, and the sign-in page that 3.3.8 mainly concerns.

Next steps, in order: fix -003, -004 and -008 (they block or gate the others), then run the axe template with the tag list above against a deployed build, keep the raw JSON per state, re-read every `incomplete` item against section 3, and have a person run the screen reader pass.
