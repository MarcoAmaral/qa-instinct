# Accessibility Audit Report

## Scope

| Field | Value |
| --- | --- |
| **Target** | WCAG 2.2 AA |
| **Blocking threshold** | Not specified by team; assuming critical and serious block release |
| **Pages and states** | Sign-up page: default state only (no error states, success states, or modals evident) |
| **Viewports** | Cannot test: source code only, no browser environment |
| **Tool limitation** | Static code review only; automated scanner (axe-core) and browser-based manual checks not available |
| **Build/versions** | HTML source provided; no version metadata |

## Limitations

This audit is based on source code inspection only. The following cannot be verified without opening the page in a browser:

- Actual colour contrast ratios (visual rendering)
- Focus indicator visibility
- Keyboard navigation and tab order behavior
- Screen reader announcements and semantic structure
- 200% zoom rendering and text clipping
- Element clickability and pointer target sizes

## Findings

| ID | Criterion | Page/State | Element | Observed | Expected | User Impact | Source | Evidence | Suggested Fix | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | Sign-up: default | `<img src="/img/logo-2024-final.png">` | Image has no `alt` attribute | All images must have an `alt` attribute that describes the image's purpose | Screen reader users hear only the filename or nothing; logo purpose is unknown | Static analysis | Source code | Add `alt="Company logo"` or descriptive text | Serious |
| A11Y-SIGNUP-002 | 4.1.1 Parsing | Sign-up: default | `<input id="email">` (password field) | Two input elements share the same `id="email"` | Every element must have a unique `id` within the document | Duplicate IDs break DOM references and tool interoperability; assistive technology may fail; JavaScript targeting the ID finds the wrong element | Static analysis | Source code | Change password input `id` to `id="password"` | Critical |
| A11Y-SIGNUP-003 | 3.3.1 Error Identification | Sign-up: default | `<input type="email" id="email">` | No visible or programmatic label associated with email field; only placeholder text | All form inputs must have an associated `<label>` with a `for` attribute, or `aria-label` / `aria-labelledby` | Screen reader users do not hear the field's purpose; placeholder text disappears when focus enters the field, leaving no cue; sighted users without focus cannot know what each field is for | Static analysis | Source code | Add `<label for="email">Email</label>` before input | Critical |
| A11Y-SIGNUP-004 | 3.3.1 Error Identification | Sign-up: default | `<input type="password" id="email">` | No visible or programmatic label associated with password field; only placeholder text | All form inputs must have an associated `<label>` with a `for` attribute, or `aria-label` / `aria-labelledby` | Screen reader users do not hear the field's purpose; no label visible to sighted users | Static analysis | Source code | Change to `id="password"` and add `<label for="password">Password</label>` before input | Critical |
| A11Y-SIGNUP-005 | 3.3.3 Error Suggestion | Sign-up: default | `<p class="hint">At least 8 characters.</p>` | Hint text is not programmatically associated with password input | Error or requirement messages must be linked to their form control via `aria-describedby` | Screen reader users of the password field do not hear the character requirement | Static analysis | Source code | Add `id="pwd-hint"` to hint, add `aria-describedby="pwd-hint"` to password input | Serious |
| A11Y-SIGNUP-006 | 2.4.7 Focus Visible | Sign-up: default | `:focus { outline: none; }` style rule | Focus outline is removed globally with no replacement | A focused element must be visually distinguishable by its appearance | Keyboard users cannot see which control has focus; keyboard navigation becomes unusable | Static analysis | Source code | Replace with `:focus { outline: 2px solid #0a58ca; }` or similar high-contrast replacement | Critical |
| A11Y-SIGNUP-007 | 4.1.2 Name, Role, Value | Sign-up: default | `<div class="btn" onclick="submitForm()">Create account</div>` | `<div>` styled as button; no semantic button element | Submit action must use `<button>` element or have `role="button"`, `keydown` handler for Enter/Space, and be in tab order | Screen reader does not announce this as a button; keyboard users cannot activate it (no Enter/Space handling); cannot receive focus via Tab key; relies entirely on mouse | Static analysis | Source code | Replace with `<button type="submit">Create account</button>` and move onclick to form's `onsubmit` handler | Critical |
| A11Y-SIGNUP-008 | 2.1.1 Keyboard (consequence) | Sign-up: default | `<div class="btn">` submit action | Not in natural tab order; requires pointer to activate | All interactive controls must be reachable and operable via keyboard alone | Users relying on keyboard cannot submit the form | Static analysis | Source code | Use `<button type="submit">` element | Critical |
| A11Y-SIGNUP-009 | 1.4.3 Contrast (Minimum) | Sign-up: default | `<p class="hint">` with `color: #595959` | Assumed light grey (#595959) on white (#fff) background | Text must have a contrast ratio of at least 4.5:1 for normal text | Older adults, people with low vision, and users in bright environments may not be able to read the requirement text; colour-blind users may have further difficulty | Static analysis (unverified without rendering) | Source code | Increase contrast; test actual rendered ratio. `#4a4a4a` or darker recommended | Serious |
| A11Y-SIGNUP-010 | 3.1.1 Language of Page | Sign-up: default | `<html>` element | No `lang` attribute present | The document's primary language must be declared with `lang="xx"` attribute on `<html>` | Screen reader may use wrong pronunciation and hyphenation; language detection tools may fail | Static analysis | Source code | Add `<html lang="en">` (or appropriate language code) | Minor |
| A11Y-SIGNUP-011 | 2.4.3 Focus Order | Sign-up: default | `<a href="/terms" tabindex="3">Read the terms</a>` | `tabindex="3"` (positive value) used, overriding natural tab order | Positive `tabindex` values must not be used; focus order must follow DOM order | Keyboard users experience a non-intuitive tab order (jumps to link before email/password fields are reached); violates reading order | Static analysis | Source code | Remove `tabindex="3"` attribute; place link after form controls in DOM if it should come after, or before if it should come before | Serious |

## Manual Checks Not Performed

| Check | Reason | Required for WCAG 2.2 AA? |
| --- | --- | --- |
| Actual colour contrast measurement | No rendering; pixels not available | Yes (1.4.3, 1.4.11) |
| Focus indicator visibility at 200% zoom | No browser viewport available | Yes (1.4.4, 2.4.7) |
| Keyboard navigation (Tab, Shift+Tab, Enter, Space, Escape) | No browser; cannot interact | Yes (2.1.1, 2.1.2, 2.4.3) |
| Screen reader announcements (NVDA, JAWS, VoiceOver) | No assistive technology environment | Partly (1.1.1, 3.3.1, 4.1.2) |
| Pointer target size (24 × 24 CSS px minimum) | No rendering; cannot measure rendered dimensions | Partly (2.5.8) |
| Colour-blindness simulation | No visual rendering | Partly (1.4.3) |

## Conclusion

**Automated scan results:** Not available (source-code-only audit; no browser environment).

**Findings summary:**
- **Critical severity:** 4 findings (duplicate IDs, missing labels, missing focus indicator, div-as-button)
- **Serious severity:** 4 findings (missing alt text, missing hint association, contrast risk, positive tabindex)
- **Minor severity:** 1 finding (missing lang attribute)

**Conformance claim:** **Not conformant.** Multiple WCAG 2.2 AA criteria fail outright at the source-code level, independent of rendering or browser behaviour. The page does not meet the accessibility standard in its current form.

**Criteria status:**
- **Checked by static analysis:** 1.1.1 (non-text content), 2.1.1 (keyboard), 2.4.3 (focus order), 2.4.7 (focus visible), 3.1.1 (language), 3.3.1 (error identification), 3.3.3 (error suggestion), 4.1.1 (parsing), 4.1.2 (name, role, value)
- **Partially checked:** 1.4.3 (contrast — colors present but actual rendering unknown)
- **Not checked:** 1.4.4 (resize text), 1.4.11 (non-text contrast), 2.1.2 (keyboard trap), 2.4.11 (focus not obscured), 2.5.7 (dragging movements), 2.5.8 (target size), 3.2.1 (on focus), 3.2.2 (on input), 3.2.6 (consistent help), 3.3.7 (redundant entry), 3.3.8 (accessible authentication)

**Pages/states not audited:** Error states, loading state, success state, modal or overlay behaviours (not present in provided source).

**To achieve conformance:** Fix all critical findings first (duplicate IDs, labels, focus outline, semantic button). Measure and adjust contrast. Remove positive tabindex. Re-audit with browser-based tools (axe-core) and keyboard/screen-reader testing.
