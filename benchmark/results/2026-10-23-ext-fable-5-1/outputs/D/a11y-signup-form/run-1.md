# Accessibility audit: Sign-up page (WCAG 2.2 AA)

Audit method: static read of the page source only. No browser, no `@axe-core/playwright` run, no screen reader, no screenshots. Every verdict below is what the source shows; anything that needs rendering or a run is marked **not checked**. Nothing was written to `a11y/audit.md`.

## 1. Scope

| Item | Value |
| --- | --- |
| Target | WCAG 2.2 AA (W3C Recommendation, https://www.w3.org/TR/WCAG22/) |
| Blocking threshold | Not set by the team. Recorded as **pending**. Findings carry a severity per `/qa-defect`; none is marked blocking until the team states the threshold. |
| Page | `Sign up` (single HTML page as supplied; route unknown, assumed `/signup`) |
| Viewports | 1440 x 900, one narrow viewport, 200% zoom. **None rendered**. |
| Versions | Build: the source pasted on 2026-10-25. axe-core and browser: N/A — no scan ran. Rule IDs below use axe-core 4.10 names and would need confirming against the raw results of a real run. |

**Assumptions**: root font size 16 px; no external CSS or JS beyond what is in the file; page content is English; the page has no header, footer or help mechanism beyond what is shown; the server may return validation errors but their markup is unknown.

### Pages x states

| Page | State | Audited |
| --- | --- | --- |
| Sign up | Default | Yes, by static read |
| Sign up | Empty (no input) | Same as default in source |
| Sign up | Loading | Not audited (no loading state exists in source) |
| Sign up | Validation error | **Not audited**: no error markup exists in source; `submitForm()` calls `form.submit()`, which skips the browser's constraint validation, so no client-side error state can occur. Server error state unknown. |
| Sign up | Success | Not audited (not in source) |
| Sign up | Modal open | Inapplicable (no modal) |
| Sign up | Focus on each control | Analysed from CSS only; not rendered |

## 2. Automated scan

**Not run.** No raw JSON exists. Tag list that a real run must use: `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`.

Expected result groups from reading the source, to be confirmed by the real run:

| Group | Expected content (static prediction, not a result) |
| --- | --- |
| `violations` | `image-alt` (line 14), `html-has-lang` (line 2) |
| `incomplete` | Possibly `color-contrast` on `.btn` if the scanner cannot resolve the `div` as text on a solid background; `target-size` on the checkbox |
| `passes` | `label` on both text inputs. **Caution**: axe's `label` rule accepts a non-empty `placeholder` as a name, so the scan would record an automated pass for lines 17 and 18 even though they have no label (finding 003). `document-title`, `page-has-heading-one`, `color-contrast` on body and hint text. |
| `inapplicable` | Video, audio, frame, table, ARIA-widget and list rules: the page exercises none of them |
| Not run under WCAG tags | `tabindex` (best-practice tag only) would not catch line 21. `duplicate-id-active` is tied to the obsolete 4.1.1 and is disabled under a 2.2 tag list, so line 18 is not caught either. `region` (landmarks) is best-practice only. |

## 3. Manual checks

Verdicts are from the source. "Pass (source)" means nothing in the source can fail the criterion; it is not a rendered pass.

| Criterion | Verdict | Evidence from source |
| --- | --- | --- |
| 1.1.1 Non-text Content | **Fail** | `img` on line 14 has no `alt`; a screen reader announces the file name. Finding 001 |
| 1.3.1 Info and Relationships | **Fail** | Hint on line 19 is not tied to the password field. Finding 004 |
| 1.3.5 Identify Input Purpose | **Fail** | No `autocomplete` on the email or password fields. Finding 009 |
| 1.4.3 Contrast (Minimum) | Pass (computed) | See the contrast table below. All text is on solid colours; nothing for `incomplete`. |
| 1.4.4 Resize Text | Not checked | No fixed heights or widths in CSS, so low risk, but needs a rendered 200% check |
| 1.4.11 Non-text Contrast | Not checked | Input and checkbox borders are browser defaults; focus ring is removed entirely (finding 006), so there is no ring to measure |
| 2.1.1 Keyboard | **Fail** | The only submit control is a `div` with `onclick` (line 22): not focusable, not activatable by `Enter` or `Space`. Implicit submission by `Enter` is also unavailable because the form has no submit button and more than one text-type field. Finding 007 |
| 2.1.2 No Keyboard Trap | Pass (source) | No widget or script that captures focus |
| 2.4.3 Focus Order | **Fail** | `tabindex="3"` on line 21 puts the terms link first in the tab order, before the email field. Finding 008 |
| 2.4.7 Focus Visible | **Fail** | `:focus { outline: none; }` on line 9 with no replacement style. Finding 006 |
| 2.4.11 Focus Not Obscured | Pass (source) | No sticky, fixed or overlaid content |
| 2.5.7 Dragging Movements | Inapplicable | Nothing is dragged |
| 2.5.8 Target Size (Minimum) | Not checked | `.btn` computes to roughly 27 px tall at 16 px text, so likely passes; the native checkbox is about 13 x 13 px but sits inside its label, which extends the target. Needs measurement. |
| 3.1.1 Language of Page | **Fail** | `html` on line 2 has no `lang`. Finding 002 |
| 3.2.1 On Focus, 3.2.2 On Input | Pass (source) | No focus or change handlers |
| 3.2.6 Consistent Help | Inapplicable | No help mechanism on the page |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Not checked | No error state exists in the source (see scope table). The password rule "At least 8 characters" is never enforced client-side. |
| 3.3.2 Labels or Instructions | **Fail** | Both text inputs rely on `placeholder` alone, which disappears on input. Finding 003 |
| 3.3.7 Redundant Entry | Inapplicable | Single-step process, nothing re-asked |
| 3.3.8 Accessible Authentication | Pass (source) | Nothing blocks paste or password managers; no puzzle or transcription. Note this page creates credentials rather than authenticating. |
| 4.1.2 Name, Role, Value | **Fail** | Submit `div` exposes no role, no name as a control, no state (finding 007). Duplicate `id="email"` on lines 17 and 18 makes any programmatic association ambiguous (finding 005). |

Contrast values computed from the CSS (not measured on a render):

| Text | Foreground / background | Ratio | Needs | Result |
| --- | --- | --- | --- | --- |
| Body, heading, labels | #222 on #fff | 15.9:1 | 4.5:1 | Pass |
| Hint (0.9rem = 14.4 px, normal) | #595959 on #fff | 7.0:1 | 4.5:1 | Pass |
| Button text | #fff on #0a58ca | 6.4:1 | 4.5:1 | Pass |

Checklist from the reference:

| Check | Verdict |
| --- | --- |
| Tab test | **Fail by source**: focus is invisible everywhere (line 9) and never reaches the submit control (line 22). Order is link, email, password, checkbox. |
| Modal trap test | Inapplicable, no modal |
| Colour-blindness simulation | Not checked. Nothing in the source relies on colour alone. |
| Screen reader | Not checked. Heading structure is a single `h1`, which is sound. No live regions exist, so no status will ever be announced if one is added later. |

## 4. Findings

Evidence column: no screenshot exists; each row points to the source line instead.

| ID | Criterion | Page / state | Element | Observed / expected | User impact | Source | Evidence | Suggested fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | Sign up / default | `img[src="/img/logo-2024-final.png"]` | Observed: no `alt`. Expected: `alt` naming the organisation, or `alt=""` if decorative. | Screen reader users hear "logo-2024-final.png" with no meaning. | Static read; axe `image-alt` expected to flag | N/A — source line 14 | Add `alt="<Company> logo"` or `alt=""`. | Medium. Threshold pending. |
| A11Y-SIGNUP-002 | 3.1.1 Language of Page | Sign up / default | `html` | Observed: no `lang`. Expected: `lang="en"`. | Screen readers may read English with the wrong voice and pronunciation. | Static read; axe `html-has-lang` expected to flag | N/A — source line 2 | `<html lang="en">`. | Medium. Threshold pending. |
| A11Y-SIGNUP-003 | 3.3.2 Labels or Instructions (also 1.3.1) | Sign up / default and while typing | `#email` inputs (lines 17, 18) | Observed: `placeholder` is the only label and vanishes on input. Expected: a visible, programmatically associated `label`. | Once typing starts, nobody can see which field is which. Screen readers get at most the placeholder as a name, which some do not announce. | Manual. axe `label` accepts placeholder, so the scan would pass this. | N/A — source lines 17, 18 | Add `<label for=...>` for each field; keep placeholder only as an example value. | High. Threshold pending. |
| A11Y-SIGNUP-004 | 1.3.1 Info and Relationships | Sign up / default | `p.hint` | Observed: "At least 8 characters." is plain text not linked to the password field. Expected: `aria-describedby` from the password input. | Screen reader users on the password field never hear the rule. | Manual | N/A — source line 19 | Give the hint an `id` and add `aria-describedby` to the password input. | Medium. Threshold pending. |
| A11Y-SIGNUP-005 | 4.1.2 Name, Role, Value | Sign up / default | Second `input[id="email"]` | Observed: duplicate `id="email"` on the password field. Expected: unique ids. | Any `label for`, `aria-describedby` or script that targets `email` binds to the wrong field. The fix for 003 cannot work until this is fixed. | Manual; `duplicate-id-active` not run under 2.2 tags | N/A — source line 18 | Rename to `id="password"`. | Medium. Threshold pending. |
| A11Y-SIGNUP-006 | 2.4.7 Focus Visible | Sign up / focus on each control | `:focus` rule | Observed: `outline: none` globally, no replacement. Expected: a visible `:focus-visible` indicator with 3:1 contrast. | Keyboard users cannot see where focus is on any control. | Manual (no axe rule) | N/A — source line 9 | Delete the rule, or replace with `:focus-visible { outline: 2px solid #0a58ca; outline-offset: 2px; }`. | High. Threshold pending. |
| A11Y-SIGNUP-007 | 2.1.1 Keyboard and 4.1.2 Name, Role, Value | Sign up / default | `div.btn[onclick]` | Observed: submit control is a `div` with `onclick`; no role, not focusable, no key handler; `Enter` in a field does not submit either. Expected: `<button type="submit">`. | Keyboard-only and switch users cannot create an account at all. Screen readers do not announce it as a button. | Manual (no axe rule for click handlers on `div`) | N/A — source line 22 | Replace with `<button type="submit" class="btn">Create account</button>` and drop the script. | Critical. Threshold pending. |
| A11Y-SIGNUP-008 | 2.4.3 Focus Order | Sign up / default | `a[href="/terms"][tabindex="3"]` | Observed: positive `tabindex` moves the link ahead of every field. Expected: natural DOM order. | Keyboard users land on the terms link before the email field, out of reading order. | Manual; axe `tabindex` is best-practice only and would not run | N/A — source line 21 | Remove `tabindex`. | Medium. Threshold pending. |
| A11Y-SIGNUP-009 | 1.3.5 Identify Input Purpose | Sign up / default | Email and password inputs | Observed: no `autocomplete`. Expected: `autocomplete="email"` and `autocomplete="new-password"`. | Browser and assistive tools cannot autofill or identify the fields. | Manual; axe `autocomplete-valid` checks only values that are present | N/A — source lines 17, 18 | Add the two `autocomplete` attributes. | Low. Threshold pending. |

Observation outside WCAG scope but relevant to the fix of 007: calling `form.submit()` bypasses constraint validation, so `type="email"` and any `required` attribute never fire. A native submit button restores that.

## 5. Conclusion

**What this audit can claim**: a static read of the source found nine failures across eight criteria. It cannot claim "no violations found by the automated scan", because no scan ran. It cannot claim conformance.

Checked by scanner: none.

Checked by hand (source read): 1.1.1, 1.3.1, 1.3.5, 1.4.3 (computed), 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11, 3.1.1, 3.2.1, 3.2.2, 3.3.2, 3.3.8, 4.1.2.

Inapplicable on this page: 2.5.7, 3.2.6, 3.3.7, and all media, table and ARIA-widget criteria.

Not checked at all: 1.4.4, 1.4.11, 2.5.8, 3.3.1, 3.3.3, colour-blindness simulation, screen reader pass, every rendered viewport, and every criterion outside the mapping that needs a render.

Pages and states not audited: loading, validation error, success.

Next step to close the gaps: run the axe template against the real route with the tag list above, keep the raw JSON, retest 1.4.4, 1.4.11 and 2.5.8 on a render, and do one screen reader pass once findings 003, 005 and 007 are fixed.

Rules not applied: the `code-style-qa` and `context-discovery` rules were not loaded (no specs were written and no repository was supplied). The evidence checker `check-test-evidence.sh` was not run because no specs or evidence exist.
