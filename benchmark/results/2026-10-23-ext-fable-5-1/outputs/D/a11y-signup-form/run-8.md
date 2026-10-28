# Accessibility audit: Sign-up page (WCAG 2.2 AA)

Source-only audit, 2026-10-25. Nothing was rendered, scanned or screenshotted. Every "automated" result below is what axe-core is expected to return when the template from `accessibility-checks.md` runs against this source. It must be confirmed by running the scan and keeping the raw JSON. Where the audit needed something the source does not say, the assumption is stated inline.

## Scope

| Item | Value |
| --- | --- |
| Target | WCAG 2.2 AA (`https://www.w3.org/TR/WCAG22/`) |
| Blocking threshold | Not given by the team. Assumption for this report: `critical` and `serious` block a release. To be confirmed by the team. |
| Viewports | 1440 x 900, one narrow viewport (assumed 375 x 667), 200% zoom. None rendered: all three are **not audited**. |
| Build | Pasted HTML source, no version, no URL. Date seen: 2026-10-25. |
| Tooling | No scan ran. Assumed `@axe-core/playwright` 4.10.x bundling axe-core 4.10.x, Chromium. Rule IDs below are from that version and must be confirmed in the raw results. |
| Tag list | `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa` (the template's list). Note: axe's `tabindex`, `region` and `landmark-one-main` rules carry only the `best-practice` tag and will **not** run with this list. |

Pages x states:

| Page | State | Audited |
| --- | --- | --- |
| Sign-up | Default | Yes, from source |
| Sign-up | Focus on email, password, checkbox, link | Yes, from source (tab order derived, not observed) |
| Sign-up | Focus on "Create account" | Not reachable: the control is a `div` and never receives focus (see A11Y-SIGNUP-001) |
| Sign-up | Empty submission | Not audited. No `required` attributes, and `form.submit()` bypasses browser constraint validation, so no client-side validation-error state exists in this source. |
| Sign-up | Validation error (server-side) | Not audited. The response page is not in the source. |
| Sign-up | Loading, success, modal open | Not audited. No such states exist in the source. |
| Sign-up | Narrow viewport, 200% zoom | Not audited. |

## Scan and manual checks

**Automated scan (expected, not run).** Raw JSON: none exists. One file per page and state must be produced when the scan is run.

| Group | Expected items |
| --- | --- |
| `violations` | `html-has-lang` on `html` (serious). `image-alt` on `img[src="/img/logo-2024-final.png"]` (critical). `target-size` possibly on `a[href="/terms"]`, see `incomplete`. |
| `incomplete` | `target-size` for the "Read the terms" link sitting inline next to the clickable label (needs measured spacing). `color-contrast` is not expected to return anything for placeholder text: axe does not evaluate placeholders, so their contrast is a manual item (A11Y-SIGNUP-008). |
| `passes` | `document-title`. `color-contrast` for `h1` (#222 on #fff, 15.9:1), `.hint` (#595959 on #fff, 7.0:1, 14.4 px text), `.btn` (#fff on #0a58ca, 6.4:1); ratios computed from the source colours and assume no background image. `label` for the checkbox (implicit label) **and for the email and password inputs**, because axe accepts a non-empty `placeholder` as a name. That last pass is an automated pass only; the manual check overrides it (A11Y-SIGNUP-003). `duplicate-id-aria`: no ARIA references, so the duplicate `id="email"` is not flagged. |
| `inapplicable` | `autocomplete-valid` (attribute absent on every field, so nothing to validate: see A11Y-SIGNUP-009). `video-caption`, `audio-caption`, `frame-title`, `list`, `th-has-data-cells`, `aria-*` rules: the page has none of these elements. |
| Not run | `tabindex`, `region`, `landmark-one-main` (best-practice tag, outside the tag list). The `tabindex="3"` is caught by hand only. |

**Manual checks.** All verdicts are from reading the source. "Pass (source)" means nothing in the source can fail the criterion; a rendered check is still owed.

| Criterion | Verdict | Page and state | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | Fail | Default | `img` has no `alt`; the file name "logo-2024-final.png" is what a screen reader would announce. |
| 1.3.1 Info and Relationships | Fail | Default | Hint "At least 8 characters." is a free `p`, not tied to the password field. |
| 1.3.5 Identify Input Purpose | Fail | Default | No `autocomplete` on email or password. |
| 1.4.3 Contrast (Minimum) | Fail (assumed colour) | Default, fields empty | Placeholder is the only visible label and uses the browser default colour. Chromium `darkgray` #a9a9a9 on #fff is about 2.3:1; Firefox renders #222 at 54% opacity, about 3.5:1. Both below 4.5:1. Must be measured. |
| 1.4.4 Resize Text | Not checked | 200% zoom | Not rendered. Source has no fixed heights or widths, so no clipping is predicted. |
| 1.4.11 Non-text Contrast | Fail | Focus on any control | Focus indicator is removed everywhere, so it has no contrast at all. Input borders are browser defaults: not measured. |
| 2.1.1 Keyboard | Fail | Default | Submit control is a `div` with `onclick`: not focusable, no key handler. Enter in a field does not submit either: the form has two implicit-submission-blocking fields (email, password) and no submit button, so the HTML implicit-submission rule does nothing. There is no keyboard way to finish the task. |
| 2.1.2 No Keyboard Trap | Pass (source) | Default | Native inputs and link only, no modal, no key handlers. |
| 2.4.3 Focus Order | Fail | Default | `tabindex="3"` puts "Read the terms" first in the sequence, before email. Derived order: link, email, password, checkbox. "Create account" is never reached. |
| 2.4.7 Focus Visible | Fail | Focus on any control | `:focus { outline: none; }` with no `:focus-visible` replacement. |
| 2.4.11 Focus Not Obscured (Minimum) | Pass (source) | Default | No sticky, fixed or overlaid content. |
| 2.5.7 Dragging Movements | Not applicable | Default | Nothing is dragged. |
| 2.5.8 Target Size (Minimum) | Not checked | Default | Checkbox is user-agent sized (exempt). Button is about 26 px tall from padding plus default line height: to measure. Link sits inline next to the clickable label with only a space between them: spacing to measure. |
| 3.1.1 Language of Page | Fail | Default | No `lang` on `html`. |
| 3.2.1 On Focus, 3.2.2 On Input | Pass (source) | Default | No focus or change handlers. |
| 3.2.6 Consistent Help | Not applicable | Default | No help mechanism on the page; a second page would be needed to compare. |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Not checked | Validation error | No client-side error state exists; server response unknown. |
| 3.3.2 Labels or Instructions | Fail | Default, after typing | Email and password have placeholder only; it disappears on the first keystroke. |
| 3.3.7 Redundant Entry | Pass (source) | Default | Single step, nothing asked twice. |
| 3.3.8 Accessible Authentication (Minimum) | Not applicable | Default | This is account creation, not an authentication step. Nothing blocks paste. |
| 4.1.2 Name, Role, Value | Fail | Default | "Create account" has no role and is not exposed as a control. |
| Tab test (checklist) | Fail | Default | Focus never lands on the submit control and is never visible. |
| Modal trap test | Not applicable | Default | No modal. |
| Colour-blindness simulation | Not checked | Default | Not rendered. No information is conveyed by colour alone in the source. |
| Screen reader pass | Not checked | Default | No person with a screen reader ran it. |

## Findings and conclusion

Severity uses axe's impact scale (critical, serious, moderate, minor). The `/qa-defect` skill was not found in this install, so its severity definitions could not be applied. Evidence: none, because nothing was rendered. Each row needs a 1440 x 900 screenshot once the page is served.

| ID | Criterion | Page and state | Element | Observed / expected | User impact | Source | Evidence | Suggested fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 2.1.1 Keyboard; 4.1.2 Name, Role, Value | Sign-up, default | `div.btn[onclick]` ("Create account") | Observed: non-focusable `div` with `onclick`; Enter in a field does not submit. Expected: a focusable control with role button, operable with Enter and Space. | Keyboard-only and screen reader users cannot create an account at all. Switch and voice-control users cannot target it by role. | manual, 2.1.1 keyboard task | none (source only) | Replace with `<button type="submit" class="btn">Create account</button>` and drop the inline script. | Critical. Blocks (assumed threshold). |
| A11Y-SIGNUP-002 | 2.4.7 Focus Visible; 1.4.11 Non-text Contrast | Sign-up, focus on any control | `:focus { outline: none; }` in `head > style` | Observed: outline removed globally, no replacement. Expected: a visible indicator on every focused element, at 3:1 against its surroundings. | Sighted keyboard users cannot see where they are on the page. | manual, 2.4.7 | none (source only) | Delete the rule, or replace with a `:focus-visible` style such as a 2 px solid outline with 2 px offset. | Serious. Blocks. |
| A11Y-SIGNUP-003 | 3.3.2 Labels or Instructions; 1.3.1 Info and Relationships | Sign-up, default and after typing | `input#email[type=email]`, `input[type=password]` | Observed: placeholder only. Expected: a persistent visible label programmatically tied to each field. | Once a user types, the field has no visible name. Voice-control users cannot say the field name reliably. axe's `label` rule passes this via placeholder, so the scan will not report it. | manual, labels | none (source only) | Add `<label for="email">Email</label>` and `<label for="password">Password</label>`; keep placeholders as examples, not names. Requires A11Y-SIGNUP-010 first. | Serious. Blocks. |
| A11Y-SIGNUP-004 | 1.1.1 Non-text Content | Sign-up, default | `img[src="/img/logo-2024-final.png"]` | Observed: no `alt`. Expected: `alt` with the organisation name if the logo identifies the site; `alt=""` if decorative. | Screen reader users hear the file name or nothing and do not learn whose site this is. | axe `image-alt` (expected) | none (source only) | Add `alt="<Organisation name>"`. Assumption: the logo is the only brand identification on the page. | Critical (axe impact). Blocks. |
| A11Y-SIGNUP-005 | 3.1.1 Language of Page | Sign-up, default | `html` | Observed: no `lang`. Expected: `lang="en"` (assumed: page text is English). | Screen readers may read the page with the wrong pronunciation rules; translation tools misdetect. | axe `html-has-lang` (expected) | none (source only) | `<html lang="en">`. | Serious. Blocks. |
| A11Y-SIGNUP-006 | 2.4.3 Focus Order | Sign-up, default | `a[href="/terms"][tabindex="3"]` | Observed: positive `tabindex` moves the link to the front of the tab sequence. Expected: natural DOM order (email, password, checkbox, link, button). | The first Tab lands on the terms link before the form; the sequence no longer matches the reading order. | manual, 2.4.3 (axe `tabindex` rule is best-practice tagged and does not run with the WCAG tag list) | none (source only) | Remove the `tabindex` attribute. | Serious. Blocks. |
| A11Y-SIGNUP-007 | 1.3.1 Info and Relationships | Sign-up, focus on password | `p.hint` ("At least 8 characters.") | Observed: hint not associated with the field. Expected: announced when the password field gets focus. | Screen reader users focused on the field do not hear the rule and may submit an invalid password. | manual, labels | none (source only) | Give the paragraph an `id` and set `aria-describedby` on the password input. | Moderate. Does not block. |
| A11Y-SIGNUP-008 | 1.4.3 Contrast (Minimum) | Sign-up, default, fields empty | Placeholder text in both inputs | Observed: browser default placeholder colour, estimated 2.3:1 (Chromium) or 3.5:1 (Firefox) on #fff. Expected: 4.5:1 for 16 px text. | Low-vision users cannot read the only visible field names. | manual, contrast (axe does not evaluate placeholders) | none (source only); measure in the browser before closing | Fixing A11Y-SIGNUP-003 removes the dependency; also style `::placeholder` to at least 4.5:1 if kept. | Serious, pending measurement. Blocks if confirmed. |
| A11Y-SIGNUP-009 | 1.3.5 Identify Input Purpose | Sign-up, default | `input[type=email]`, `input[type=password]` | Observed: no `autocomplete`. Expected: `autocomplete="email"` and `autocomplete="new-password"`. | Password managers and browser autofill cannot reliably fill or save; users with cognitive or motor impairments retype. | manual (axe `autocomplete-valid` only checks the attribute when present) | none (source only) | Add the two attributes. | Moderate. Does not block. |
| A11Y-SIGNUP-010 | Not a WCAG 2.2 failure (4.1.1 is obsolete). Defect that blocks the fix for A11Y-SIGNUP-003. | Sign-up, default | `input[type=password]#email` | Observed: `id="email"` used twice. Expected: unique ids. | Any `label for="email"` or `aria-describedby` will bind to the first input only; the password field stays unnamed. | manual, source read | none (source only) | Rename to `id="password"`. | Minor on its own; fix together with 003. |

Out of accessibility scope, seen while reading: the inputs have no `name` attributes, so the form submits no data; `form.submit()` skips constraint validation; the checkbox is not `required`. These are functional defects for `/qa-defect`, not WCAG findings.

**What this audit can claim.** This is a static reading of one page's source. It is not a statement that the page conforms to WCAG 2.2 AA, and it cannot become one until the page is rendered. The claims separate as follows:

- **Automated scan**: not run. Two violations are expected (`html-has-lang`, `image-alt`) and must be confirmed from raw results. "No violations found by the automated scan" cannot be said yet.
- **Checked by hand from source and failing**: 1.1.1, 1.3.1, 1.3.5, 1.4.3 (placeholder, pending measurement), 1.4.11, 2.1.1, 2.4.3, 2.4.7, 3.1.1, 3.3.2, 4.1.2.
- **Checked by hand from source and passing**: 2.1.2, 2.4.11, 3.2.1, 3.2.2, 3.3.7. Rendered confirmation still owed.
- **Not applicable on this page**: 2.5.7, 3.2.6, 3.3.8.
- **Not checked at all**: 1.4.4 (200% zoom), 2.5.8 (needs measurement), 3.3.1 and 3.3.3 (no error state exists client-side; server response unknown), colour-blindness simulation, screen reader pass, every item in the manual checklist that needs a rendered page.
- **Pages and states not audited**: narrow viewport, 200% zoom, empty submission, server-side validation error, loading, success. No second page exists to check 3.2.6.

No conformance score or percentage is given. The page is not conformant: five findings meet the assumed blocking threshold before anything is rendered, and the keyboard failure alone prevents the task from being completed.

**Rules not applied.** `/qa-defect` was not found in this install, so its severity scale and report format were replaced by axe's impact levels. The `test-evidence` checker `check-test-evidence.sh` was not run and no evidence files exist, because nothing was rendered. The `context-discovery` rule could not be applied beyond the pasted source: there is no repository, route list or served page to discover.
