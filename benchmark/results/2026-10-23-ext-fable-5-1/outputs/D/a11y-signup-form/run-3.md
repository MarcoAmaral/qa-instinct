# Accessibility audit: Sign-up page (WCAG 2.2 AA)

**Audit basis.** Static review of the HTML source only. No browser, no `@axe-core/playwright` run, no screen reader, no screenshots. Every verdict below is derived from the markup and CSS, and the automated-scan section is a prediction of what the template would return, to be confirmed by a real run. Nothing here is a conformance claim.

## 1. Scope

| Item | Value |
| --- | --- |
| Target | WCAG 2.2 AA (`https://www.w3.org/TR/WCAG22/`) |
| Blocking threshold | Not given by the team. **Assumption:** `critical` and `serious` impact block a release. The team must confirm or replace this. |
| Pages | One: `/` sign-up (`<title>Sign up</title>`) |
| Viewports | None rendered. 1440 x 900, one narrow viewport and 200% zoom are **not audited**. |
| Versions | Build: unknown (source pasted 2026-10-25). Browser: none. `@axe-core/playwright` and axe-core: not run; rule IDs below are named as in axe-core 4.10 and must be confirmed against the raw results of a real scan. |

### Pages x states

| Page | State | Audited | Note |
| --- | --- | --- | --- |
| Sign-up | Default | Source only | |
| Sign-up | Focus on email | Source only | `:focus { outline: none }` applies |
| Sign-up | Focus on password | Source only | Same |
| Sign-up | Focus on checkbox | Source only | Same |
| Sign-up | Focus on "Read the terms" | Source only | Receives focus first because of `tabindex="3"` |
| Sign-up | Focus on "Create account" | Not reachable | The control is a `<div>`; it cannot take focus |
| Sign-up | Validation error | Does not exist | No `required`, no error markup, and `form.submit()` skips the browser's constraint validation. Empty submissions go through. |
| Sign-up | Success | Not audited | Navigates away; target page not supplied |
| Sign-up | Empty, loading, modal open | N/A | No such states in the source |

## 2. Automated scan (predicted, not run)

Tag list the template would use: `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`. Rules tagged only `best-practice` (`tabindex`, `region`, `landmark-one-main`, `page-has-heading-one`) **do not run** with that list. This matters below.

| Group | Rule (axe-core 4.10 name) | Element | Expected result |
| --- | --- | --- | --- |
| `violations` | `html-has-lang` | `<html>` | Fail, serious. Finding 001 |
| `violations` | `image-alt` | `img[src="/img/logo-2024-final.png"]` | Fail, critical. Finding 002 |
| `passes` | `label` | `#email` x2 | **Automated pass, misleading.** Current axe-core accepts a non-empty `placeholder` as a name. The field still has no label. Finding 003 is manual. Confirm in raw results. |
| `passes` | `color-contrast` | body text, `.hint`, `.btn`, default link | Automated pass. Measured from source: `#222`/`#fff` 15.9:1, `#595959`/`#fff` 7.0:1, `#fff`/`#0a58ca` 6.4:1, default `#0000EE`/`#fff` 9.4:1 |
| `incomplete` | `color-contrast` | placeholder text in both inputs | Browser default placeholder colour is not in the source. Manual check required. Not checked. |
| `passes` | `document-title` | `<title>` | Automated pass |
| `passes` | `duplicate-id-aria` | `id="email"` x2 | Passes because neither id is referenced by `for` or ARIA. The duplicate is real and is Finding 010. `duplicate-id` and `duplicate-id-active` are deprecated with 4.1.1 and do not run. |
| `inapplicable` | `autocomplete-valid` | inputs | No `autocomplete` attribute to validate. Absence is Finding 009, which the scanner cannot see. |
| `inapplicable` | `meta-viewport`, `video-caption`, `audio-caption`, `frame-title`, `aria-*` rules | — | Nothing to test |
| Not run | `tabindex` | `a[tabindex="3"]` | `best-practice` tag only. Finding 008 is manual. |
| No rule | — | `div.btn[onclick]` | axe has no WCAG-tagged rule for a clickable `<div>`. Findings 005 and 006 are manual. |

Raw JSON: none kept, since no scan ran.

## 3. Manual checks (from source)

| Criterion | Verdict | Evidence from source |
| --- | --- | --- |
| 1.1.1 Non-text Content | Fail | Logo has no `alt`. Finding 002 |
| 1.3.1 Info and Relationships | Fail | Hint "At least 8 characters." is a free `<p>`, not tied to the password field. Findings 003, 004 |
| 1.3.5 Identify Input Purpose | Fail | No `autocomplete` on email or password. Finding 009 |
| 1.4.3 Contrast (Minimum) | Pass for authored colours; placeholder not checked | Ratios in section 2. Placeholder colour is user-agent default and needs a render. |
| 1.4.4 Resize Text | Not checked | Needs a render at 200%. Source has no fixed heights, `.hint` uses `rem`. |
| 1.4.10 Reflow, 1.4.12 Text Spacing | Not checked | Needs a render. No fixed widths or heights in the source. |
| 1.4.11 Non-text Contrast | Not measurable | Input borders are user-agent default, author-unmodified. The focus indicator has been removed, so there is nothing to measure. Reported under 2.4.7. |
| 2.1.1 Keyboard | Fail | Submit control is a `<div onclick>`. Enter in a field does not submit either: the form has no submit button and two fields that block implicit submission. Finding 005 |
| 2.1.2 No Keyboard Trap | Pass by source | No modal, no key handlers |
| 2.4.3 Focus Order | Fail | `tabindex="3"` puts "Read the terms" first in the tab sequence, before the email field. Finding 008 |
| 2.4.7 Focus Visible | Fail | `:focus { outline: none; }` globally, no replacement style. Finding 007 |
| 2.4.11 Focus Not Obscured (Minimum) | Pass by source | No sticky or fixed content |
| 2.5.7 Dragging Movements | N/A | Nothing drags |
| 2.5.8 Target Size (Minimum) | Not checked | Native checkbox is user-agent sized and exempt. Link height and spacing to the checkbox label need a render. `.btn` is about 26 px tall at default font size; width unmeasured. |
| 3.1.1 Language of Page | Fail | No `lang`. Finding 001 |
| 3.2.1 On Focus, 3.2.2 On Input | Pass by source | No focus, change or input handlers |
| 3.2.6 Consistent Help | Not checked | No help mechanism on this page; other pages not supplied |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Not checked | No error state exists in the source. See the scope table: the form submits empty. |
| 3.3.2 Labels or Instructions | Fail | Placeholder is the only label on both inputs. Finding 003 |
| 3.3.7 Redundant Entry | Pass | Single step, nothing asked twice |
| 3.3.8 Accessible Authentication (Minimum) | N/A to this step | Account creation is not authentication. Paste is not blocked in the source. Password-manager support depends on Finding 009. |
| 4.1.2 Name, Role, Value | Fail | "Create account" exposes no role. Finding 006 |

Checklist items from `accessibility-checks.md`:

| Check | Verdict |
| --- | --- |
| Tab test | Predicted from source, not run: link, email, password, checkbox, then end of document. The submit control is never reached and no stop is visible. |
| Modal trap test | N/A, no modal |
| Colour-blindness simulation | Not checked |
| Screen reader | Not checked |

## 4. Findings

Severity uses the axe impact scale (critical, serious, moderate, minor) because the `/qa-defect` scale could not be loaded. "Blocks" is against the assumed threshold in section 1.

| ID | Criterion | Element | Observed / expected | User impact | Source | Fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 3.1.1 Language of Page | `html` | No `lang`. Expected `lang="en"` (assumed English). | Screen readers may pick the wrong voice and mispronounce every word. | `html-has-lang` | `<html lang="en">` | Serious. Blocks. |
| A11Y-SIGNUP-002 | 1.1.1 Non-text Content | `img[src="/img/logo-2024-final.png"]` | No `alt`; readers fall back to the file name "logo-2024-final". Expected the brand name, or `alt=""` if purely decorative. | Blind users hear a file name instead of who the site belongs to. | `image-alt` | `alt="<Company> logo"` | Critical. Blocks. |
| A11Y-SIGNUP-003 | 3.3.2 Labels or Instructions, 1.3.1 Info and Relationships | `input[type=email]`, `input[type=password]` | Placeholder is the only label; it disappears once the user types. Expected a visible, programmatically associated `<label>`. | Users who type, then lose track, cannot see which field is which. Users with memory impairments are hit hardest. | Manual. axe `label` rule passes on placeholder; do not trust that pass. | Add `<label for=…>` to each field with unique ids. Depends on 010. | Serious. Blocks. |
| A11Y-SIGNUP-004 | 1.3.1 Info and Relationships | `p.hint` | Hint is not associated with the password field. Expected `aria-describedby`. | Screen-reader users in forms mode never hear the 8-character rule. | Manual | `<p id="pw-hint">` and `aria-describedby="pw-hint"` on the password input | Moderate. Does not block. |
| A11Y-SIGNUP-005 | 2.1.1 Keyboard | `div.btn[onclick]` | Not focusable, no key handler; Enter in a field does not submit because the form has no submit button and two implicit-submission-blocking fields. Expected the task to complete by keyboard. | Keyboard-only and switch users cannot create an account at all. | Manual | `<button type="submit" class="btn">Create account</button>`; drop `onclick` | Critical. Blocks. |
| A11Y-SIGNUP-006 | 4.1.2 Name, Role, Value | `div.btn[onclick]` | Exposed as plain text. Expected role `button`. | Screen-reader users hear "Create account" as text and find no way to submit. | Manual | Same as 005 | Serious. Blocks. |
| A11Y-SIGNUP-007 | 2.4.7 Focus Visible | `:focus { outline: none }` | Focus indicator removed on every control, no replacement. Expected a visible indicator, at 3:1 against adjacent colours per 1.4.11. | Sighted keyboard users cannot tell where they are. | Manual | Delete the rule, or replace with `:focus-visible { outline: 2px solid #0a58ca; outline-offset: 2px; }` | Serious. Blocks. |
| A11Y-SIGNUP-008 | 2.4.3 Focus Order | `a[href="/terms"][tabindex="3"]` | Link is first in the tab order, ahead of the email field. Expected the natural document order. | Keyboard users land on the terms link before the form and may think the form is skipped. | Manual. axe `tabindex` rule is `best-practice` and does not run with the WCAG tag list. | Remove `tabindex` | Moderate. Does not block. |
| A11Y-SIGNUP-009 | 1.3.5 Identify Input Purpose | both inputs | No `autocomplete`. Expected `autocomplete="email"` and `autocomplete="new-password"`. | Blocks autofill and password managers, which users with cognitive or motor impairments rely on. | Manual. `autocomplete-valid` is inapplicable when the attribute is absent. | Add the two tokens | Moderate. Does not block. |
| A11Y-SIGNUP-010 | None directly (4.1.1 is obsolete); blocks the fix for 003 | `input#email` x2 | Both inputs carry `id="email"`. A `<label for="email">` can only ever bind to the first. Expected unique ids. | None on its own today. Any labelling fix fails silently on the password field until this is corrected. | Manual. `duplicate-id-aria` does not fire because the id is unreferenced. | Rename the password id to `password` | Minor. Does not block, but fix with 003. |

Evidence files: none. No screenshots or recordings were produced, so the evidence rule's checks were not applied and the checker was not run.

Out of accessibility scope but noted for the team: the form has no `action` or `method`, so submission is a GET to the current URL with the password in the query string. Send that to a security review.

## 5. What this audit can and cannot claim

**No automated scan ran.** The scanner column above is a prediction from the source and from current axe-core rule behaviour. It must be replaced with the raw JSON of a real run before it counts as evidence.

**Not conformant.** The page fails nine WCAG 2.2 criteria on inspection (1.1.1, 1.3.1, 1.3.5, 2.1.1, 2.4.3, 2.4.7, 3.1.1, 3.3.2, 4.1.2). Two of the failures, 2.1.1 and 4.1.2 on the submit control, make the sign-up task impossible without a pointer. Four findings would be invisible to a scan that asserts only `violations` with the WCAG tag list (003, 005, 006, 008, 009, 010).

| Checked by | Criteria |
| --- | --- |
| Scanner (predicted only) | 1.1.1, 3.1.1, 2.4.2, 1.4.3 for authored colours |
| By hand, from source | 1.3.1, 1.3.5, 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11, 3.2.1, 3.2.2, 3.3.2, 3.3.7, 4.1.2 |
| Not applicable here | 2.5.7, 3.3.8 |
| **Not checked at all** | 1.4.3 placeholder text, 1.4.4, 1.4.10, 1.4.11 focus ring, 1.4.12, 2.5.8, 3.2.6, 3.3.1, 3.3.3, colour-blindness simulation, screen reader pass |
| Pages and states not audited | Every rendered viewport and 200% zoom; focus on the submit control (unreachable); validation error (does not exist); success page |

Next step to turn this into an audit of record: fix 005 and 010 first so the page has a real submit button and unique ids, then run the template per state, keep the JSON, and do the render-dependent checks listed as not checked.

---

Rules this run could not apply because the `qa-rules` skill is not installed: `accessibility-qa`, `test-evidence`, `code-style-qa`, `context-discovery`. The `/qa-defect` severity scale also could not be opened (file lookup was denied), so severity uses the axe impact scale instead.
