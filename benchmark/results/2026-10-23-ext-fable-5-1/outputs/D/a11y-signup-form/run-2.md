# Accessibility audit: Sign-up page (WCAG 2.2 AA)

**Method and limits.** This audit was done by reading the page source only. No browser, no `@axe-core/playwright` run, no screenshots, no screen reader. Every automated result below is a prediction of what axe-core would report on this markup and is marked as such. Every manual verdict is derived from the source and must be confirmed on the rendered page. No evidence files exist, and `check-test-evidence.sh` was not run because there are no specs to check.

## 1. Scope

| Item | Value |
| --- | --- |
| Target | WCAG 2.2 AA (W3C Recommendation, https://www.w3.org/TR/WCAG22/) |
| Blocking threshold | Not provided by the team. Severities are given per `/qa-defect`; whether a finding blocks a release is left for the team to decide. |
| Page | Sign-up (`<title>Sign up</title>`, `form#signup`). Assumed to be a single-step process with no other page in scope. |
| Viewports | None rendered. 1440 x 900, a narrow viewport and 200% zoom are all **not audited**. |
| Versions | Build: unknown (source pasted 2026-10-25). `@axe-core/playwright`, axe-core and browser: not run, unknown. Rule coverage statements below assume a recent axe-core (4.10 or later) and must be confirmed against the bundled version. |

**Pages x states**

| Page | State | Audited |
| --- | --- | --- |
| Sign-up | Default | Source review only |
| Sign-up | Focus on each form control (email, password, checkbox, terms link, submit) | Source review only (focus styling and order derived from CSS and `tabindex`) |
| Sign-up | Validation error | Not audited. The source has no client-side validation, no `required` attributes and no error region. Server-side error rendering is unknown. |
| Sign-up | Success | Not audited. The form submits to the current URL and the response is unknown. |
| Sign-up | Loading | Not applicable. No asynchronous behaviour in the source. |
| Sign-up | Modal open | Not applicable. No modal in the source. |

**Assumptions.** Default user-agent styles apply (16px base font, default input borders and placeholder colour). The image is the organisation logo and conveys the brand. Page language is English. The pasted source is the complete page.

## 2. Checks: automated (predicted) and manual

**Scan configuration that would be used.** Tags `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`, as in the template in the `qa-reference` skill's `references/accessibility-checks.md`. Note the template omits `wcag22a`; the two new 2.2 level A criteria (3.2.6, 3.3.7) have no axe rules anyway, but the tag should be added so the list is complete. Raw JSON: none, the scan was not run.

**Predicted axe-core result groups, default state**

| Group | Rule ID | Element | Note |
| --- | --- | --- | --- |
| violations (predicted) | `image-alt` | `img[src="/img/logo-2024-final.png"]` | No `alt`. Finding 006. |
| violations (predicted) | `html-has-lang` | `html` | No `lang`. Finding 007. |
| passes (predicted, automated pass only) | `label` | both text inputs | axe accepts a non-empty `placeholder` as a name, so this rule is expected to **pass**. The WCAG failure still stands (finding 005). This is the "axe is green" trap on this page. |
| passes (predicted) | `document-title`, `color-contrast` (text nodes), `page-has-heading-one` | `title`, body text, hint, button text, `h1` | Contrast values computed from the CSS, see manual table. |
| passes (predicted) | `autocomplete-valid` | inputs | Passes because the rule only validates `autocomplete` values that exist. The missing tokens are finding 008. |
| not run under WCAG tags | `tabindex` | `a[tabindex="3"]` | This rule is tagged best-practice only. The WCAG scan would **not** report `tabindex="3"`. Finding 004 is manual. |
| not run under WCAG tags | `duplicate-id`, `duplicate-id-active` | `input[id="email"]` x2 | Deprecated after 4.1.1 Parsing was removed. `duplicate-id-aria` would not fire because nothing references the id. See non-WCAG defects. |
| no rule exists | none | `div.btn[onclick]`, `:focus { outline: none }` | axe cannot detect a non-focusable click target or a removed focus ring. Findings 001, 002, 003 are manual. |
| incomplete (predicted) | none expected | | Flat colours, no background images. Confirm in the raw results. |
| inapplicable (predicted) | video, audio, caption, frame, table, ARIA widget and landmark rules | | The page never exercises them. |

**Manual checks, Sign-up page, default state and focus-on-each-control state**

| Criterion | Verdict | What the source shows |
| --- | --- | --- |
| 1.1.1 Non-text Content | Fail | Logo image has no `alt`. Screen readers fall back to the file name "logo-2024-final". |
| 1.3.1 Info and Relationships | Fail | The hint "At least 8 characters." is a loose `<p>` with no `aria-describedby` from the password field. |
| 1.3.5 Identify Input Purpose | Fail | No `autocomplete="email"` or `autocomplete="new-password"`. |
| 1.4.3 Contrast (Minimum) | Pass from CSS; placeholder not checked | Computed: body `#222` on `#fff` about 15.9:1; hint `#595959` on `#fff` about 7.0:1 (14.4px normal text, needs 4.5:1); button `#fff` on `#0a58ca` about 6.4:1. Placeholder text uses the user-agent colour and could not be measured. |
| 1.4.4 Resize Text | Not checked | No fixed heights or widths in the CSS, so clipping is unlikely. Needs a render at 200%. |
| 1.4.10 Reflow | Not checked | No `<meta name="viewport">`. Mobile browsers will render at desktop width and scale down. Needs a 320px render. |
| 1.4.11 Non-text Contrast | Fail (focus indicator), not checked (input borders) | There is no focus indicator at all to measure (finding 003). Input borders are user-agent defaults and need a measurement. |
| 2.1.1 Keyboard | Fail | The submit control is a `div` with `onclick`. It is not focusable and has no key handler. Enter in a text field does not submit either: the form has no submit button and two fields that block implicit submission (email and password). The task cannot be finished with a keyboard. |
| 2.1.2 No Keyboard Trap | Pass from source | No modal, no script that captures focus. |
| 2.4.3 Focus Order | Fail | `tabindex="3"` puts "Read the terms" first. Tab order is: terms link, email, password, checkbox. "Create account" is never reached. |
| 2.4.7 Focus Visible | Fail | `:focus { outline: none; }` removes the indicator on every element with no `:focus-visible` replacement. |
| 2.4.11 Focus Not Obscured (Minimum) | Pass from source | No sticky or fixed content. |
| 2.5.7 Dragging Movements | Not applicable | Nothing drags. |
| 2.5.8 Target Size (Minimum) | Not checked | `div.btn` is estimated at about 27px tall from padding plus line height, which would pass, but it was not measured. The checkbox is a user-agent control (exempt). The terms link is inline text (exempt). |
| 3.1.1 Language of Page | Fail | `<html>` has no `lang`. |
| 3.2.1 On Focus, 3.2.2 On Input | Pass from source | No focus or change handlers. Submission is explicit. |
| 3.2.6 Consistent Help | Not applicable | No help mechanism on the page; only one page in scope. |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Not checked | No client-side validation exists, so no error state could be reviewed. Server-side errors unknown. |
| 3.3.2 Labels or Instructions | Fail | Email and password fields have a placeholder only. It disappears when the user types. The password rule is not tied to its field. |
| 3.3.7 Redundant Entry | Pass from source | Single step, nothing asked twice. No password confirmation field. |
| 3.3.8 Accessible Authentication (Minimum) | Pass from source | This is account creation, not login. No CAPTCHA, no paste blocking, no `autocomplete="off"`. |
| 4.1.2 Name, Role, Value | Fail | "Create account" `div` has no role and no state. The checkbox is native and wrapped in a `<label>`, which passes. |

**Checklist from `accessibility-checks.md`**

| Check | Verdict | Note |
| --- | --- | --- |
| Tab test | Fail (derived) | Focus lands on the link, two inputs and the checkbox, in the wrong order, with no visible indicator, and never on the submit control. |
| Modal trap test | Not applicable | No modal. |
| Colour-blindness simulation | Not checked | Nothing in the source conveys meaning by colour alone, but no render was done. |
| Screen reader | Not checked | Requires a person with a screen reader. Expected on reading the source: heading structure is a single `h1` (fine), the logo reads as a file name, the submit control reads as plain text. |

## 3. Findings and conclusion

Evidence for every row is "none (source review)". Severity follows `/qa-defect`. The blocking threshold is unknown, so no row states whether it blocks.

| ID | Criterion | Page and state | Element | Observed / expected | User impact | Source | Suggested fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 2.1.1 Keyboard | Sign-up, default and focus states | `form#signup div.btn[onclick]` | Observed: submit is a non-focusable `div`; Enter in the fields does not submit. Expected: a native submit control reachable and activatable by keyboard. | Keyboard-only, switch and many screen-reader users cannot create an account. Complete feature failure for them. | Manual (tab test from source). No axe rule. | Replace the `div` with `<button type="submit">Create account</button>` and drop the inline `onclick`. | Critical |
| A11Y-SIGNUP-002 | 4.1.2 Name, Role, Value | Sign-up, default | `form#signup div.btn[onclick]` | Observed: no role, exposed as generic text. Expected: role button. | Screen-reader users browsing by form control or button find no submit control. | Manual. No axe rule. | Same fix as 001. | High |
| A11Y-SIGNUP-003 | 2.4.7 Focus Visible (also 1.4.11) | Sign-up, focus on each control | `:focus { outline: none; }` in the page `<style>` | Observed: focus ring removed globally, no replacement. Expected: a visible indicator with at least 3:1 against adjacent colours. | Sighted keyboard users cannot tell which control is active. | Manual. No axe rule. | Delete the rule, or replace with a `:focus-visible` style such as a 2px solid `#0a58ca` outline with offset. | High |
| A11Y-SIGNUP-004 | 2.4.3 Focus Order | Sign-up, focus states | `a[href="/terms"][tabindex="3"]` | Observed: link receives focus before the email field. Expected: focus follows reading order. | Keyboard users land on the terms link before any field and may miss the form. | Manual. axe `tabindex` rule is best-practice only and not in the WCAG scan. | Remove the `tabindex` attribute. | Medium |
| A11Y-SIGNUP-005 | 3.3.2 Labels or Instructions, 1.3.1 Info and Relationships | Sign-up, default | `input[type=email]`, `input[type=password]`, `p.hint` | Observed: placeholder is the only label; hint not linked to the password field. Expected: a visible persistent `<label for>` per field and `aria-describedby` to the hint. | Once a value is typed the field name is gone. Users with memory or attention impairments lose context. Screen readers do not read the hint with the field. | Manual. axe `label` rule is expected to pass because of the placeholder. | Add `<label for="email">Email</label>`, `<label for="password">Password</label>`, give the hint an id and reference it with `aria-describedby` on the password field. | High |
| A11Y-SIGNUP-006 | 1.1.1 Non-text Content | Sign-up, default | `img[src="/img/logo-2024-final.png"]` | Observed: no `alt`. Expected: `alt` naming the organisation, or `alt=""` if purely decorative. | Screen readers announce "logo-2024-final". | axe `image-alt` (predicted). | Add `alt="<Organisation name>"`. Assumption: the logo is informative. | Medium |
| A11Y-SIGNUP-007 | 3.1.1 Language of Page | Sign-up, default | `html` | Observed: no `lang`. Expected: `lang="en"`. | Screen readers may pick the wrong voice and mispronounce the page. | axe `html-has-lang` (predicted). | Add `<html lang="en">`. Assumption: English. | Medium |
| A11Y-SIGNUP-008 | 1.3.5 Identify Input Purpose | Sign-up, default | `input[type=email]`, `input[type=password]` | Observed: no `autocomplete`. Expected: `autocomplete="email"` and `autocomplete="new-password"`. | Browsers and password managers cannot reliably fill or generate, which hurts users with motor and cognitive impairments. | Manual. axe `autocomplete-valid` is silent on missing tokens. | Add the two tokens. | Medium |

**Defects outside WCAG 2.2, found while reading the source**

| Issue | Element | Why it matters |
| --- | --- | --- |
| Duplicate `id="email"` on the password field | `input[type=password]` | 4.1.1 Parsing is obsolete, so it is not a WCAG finding. It will break the `for` and `aria-describedby` fixes in 005 until the password field gets its own id. Fix this first. Severity Medium. |
| Form has no `method` or `action` | `form#signup` | Submits by GET to the current URL, so the password would appear in the query string. Security defect, out of this audit's scope. Report it separately. |
| No `required` attributes and `form.submit()` bypasses native validation | `form#signup`, `submitForm()` | No error state exists to audit for 3.3.1 and 3.3.3. Once validation is added, those criteria must be audited. |

**Conclusion**

- **The automated scan was not run.** The predicted violations are `image-alt` and `html-has-lang` on the default state only. This is a prediction from source, not a result.
- **The page is not conformant** with WCAG 2.2 AA. Eight criteria fail on source review: 1.1.1, 1.3.1, 1.3.5, 2.1.1, 2.4.3, 2.4.7, 3.1.1, 3.3.2, 4.1.2 (and 1.4.11 for the focus indicator). Three of these, 2.1.1, 2.4.7 and 4.1.2, are invisible to the WCAG-tagged axe scan, and 3.3.2 is expected to be reported as a pass by it.
- **Checked by scanner:** none (not run).
- **Checked by hand from source:** 1.1.1, 1.3.1, 1.3.5, 1.4.3 (text nodes), 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11, 3.1.1, 3.2.1, 3.2.2, 3.3.2, 3.3.7, 3.3.8, 4.1.2.
- **Not checked at all:** 1.4.3 for placeholder text, 1.4.4, 1.4.10, 1.4.11 for input borders, 2.5.8, 3.3.1, 3.3.3, colour-blindness simulation, screen reader pass. 2.5.7 and 3.2.6 are not applicable.
- **Not audited:** validation error and success states, every viewport, 200% zoom.
- **Next step:** fix 001 to 008 and the duplicate id, then run the axe template on the rendered page in each state, keep the raw JSON, and do the render-dependent checks listed above with evidence per the `test-evidence` rule.

Rule applied from disk: `accessibility-qa`, `test-evidence`, `references/accessibility-checks.md`, and the severity scale from `qa-defect`. No rule named by the skill was unavailable.
