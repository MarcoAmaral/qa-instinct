# WCAG 2.2 AA Accessibility Audit: Sign-up Page

**Audit Date**: 2026-10-28  
**Target**: WCAG 2.2 AA  
**Blocking Threshold**: Assumed critical and serious findings block release (team not consulted)  
**Assessment Method**: Static code analysis only (no browser rendering available)

## 1. Scope

| Aspect | Details |
| --- | --- |
| **Pages × States** | Sign-up page, default state |
| **Viewports** | Not tested (source code only; no rendering) |
| **Build & versions** | Unknown; axe-core scan not performed |
| **Browser** | Not tested |
| **Assumptions** | HTML source analyzed; dynamic rendering, keyboard interaction, screen reader output, zoom behavior, and color contrast at render-time all untested |

**Not audited:**
- Form submission flow (loading, error, success states)
- Narrow or zoomed viewports
- Responsive behavior

## 2. Automated Scan

**Not performed.** Requires browser rendering and axe-core execution.

## 3. Manual Checks (Static Code Analysis)

### Findings by Criterion

| Criterion | Check | Result | Evidence |
| --- | --- | --- | --- |
| **1.1.1 Non-text Content** | Logo image has alt text or role | Fail | `<img src="/img/logo-2024-final.png">` missing `alt` |
| **1.3.1 Info and Relationships** | Inputs associated with labels; hints tied to fields | Fail | Email and password inputs have no `<label>`; hint text not `aria-describedby` |
| **2.4.3 Focus Order** | Tab order matches reading order; no positive tabindex | Fail | `<a tabindex="3">` disrupts keyboard flow |
| **2.4.7 Focus Visible** | Focused element visibly distinct | Fail | CSS rule `:focus { outline: none; }` removes indicator; no replacement provided |
| **3.1.1 Language of Page** | Page has `lang` attribute | Fail | `<html>` tag lacks `lang` |
| **4.1.2 Name, Role, Value** | Custom controls expose accessible name and role | Fail | `<div class="btn" onclick="submitForm()">` is not a button; no `role="button"` or ARIA attributes |
| **2.5.8 Target Size (Minimum)** | Pointer targets ≥24×24 CSS px | Not checked | Cannot measure rendered size |
| **1.4.3 Contrast (Minimum)** | Text/background contrast ≥4.5:1 | Partial | Hint text (#595959 on #fff) ~4.7:1 (passes); button text requires render-time measurement |
| **2.1.1 Keyboard** | Entire task completable via keyboard | Not checked | Div-button cannot be activated by keyboard without JS interception; requires testing |
| **2.1.2 No Keyboard Trap** | Focus can always leave a widget | Not checked | Requires interaction test |
| **3.2.1 On Focus; 3.2.2 On Input** | Focusing/changing a control doesn't change context | Not checked | Requires render and interaction |

## 4. Findings

| ID | Criterion | Element | Observed | Expected | User Impact | Source | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A11Y-SIGNUP-001 | 1.1.1 Non-text Content | `<img src="/img/logo-2024-final.png">` | No `alt` attribute | Alt text describing logo purpose | Blind users cannot understand image | Static analysis | Critical |
| A11Y-SIGNUP-002 | 4.1.2 Name, Role, Value (duplicate IDs) | Both `<input id="email">` elements | Email and password inputs share `id="email"` | IDs must be unique; password should be `id="password"` | Breaks HTML validity and label association | Static analysis | Critical |
| A11Y-SIGNUP-003 | 1.3.1, 4.1.2 Name, Role, Value | Email `<input type="email">` | No associated `<label>` | `<label for="email">` wrapping or adjacent | Screen reader users cannot identify field purpose | Static analysis | Critical |
| A11Y-SIGNUP-004 | 1.3.1, 4.1.2 Name, Role, Value | Password `<input type="password">` | No associated `<label>`; placeholder only | `<label for="password">` wrapping or adjacent | Screen reader users cannot identify field purpose | Static analysis | Critical |
| A11Y-SIGNUP-005 | 1.3.1 Info and Relationships | Hint paragraph `<p class="hint">At least 8 characters.</p>` | Text after input; no programmatic tie | `<input aria-describedby="pwd-hint"><p id="pwd-hint">` | Screen reader users may miss character requirement | Static analysis | Serious |
| A11Y-SIGNUP-006 | 4.1.2 Name, Role, Value | `<div class="btn" onclick="submitForm()">Create account</div>` | Div with click handler; not a button element | `<button onclick="submitForm()">` or `<div role="button" tabindex="0">` + ARIA | Screen reader won't announce as button; keyboard Enter/Space won't activate without JS; not form-connected | Static analysis | Critical |
| A11Y-SIGNUP-007 | 2.4.7 Focus Visible | CSS rule `:focus { outline: none; }` | Focus outline removed globally; no alternative | Provide visible focus indicator (outline, ring, highlight) with ≥3:1 contrast (2.4.11) | Keyboard users cannot see focused element | Static analysis | Critical |
| A11Y-SIGNUP-008 | 2.4.3 Focus Order | `<a href="/terms" tabindex="3">Read the terms</a>` | Positive tabindex breaks natural order | Remove `tabindex`; rely on DOM order | Keyboard user navigates out of logical reading order | Static analysis | Serious |
| A11Y-SIGNUP-009 | 3.1.1 Language of Page | `<html>` tag | No `lang` attribute | `<html lang="en">` (or other language code) | Screen reader may use wrong pronunciation; browser language detection fails | Static analysis | Serious |

## 5. Report Summary

**What was checked:**
- ✓ Semantic structure (labels, alt text, roles)
- ✓ DOM and attribute errors (duplicate IDs, missing associations)
- ✓ Keyboard order (tabindex usage)
- ✓ Focus affordance (CSS rule inspection)
- ✓ Language metadata

**What was not checked:**
- ✗ Rendered color contrast at the browser (calculated theoretically only)
- ✗ Rendered target sizes
- ✗ Keyboard activation of div-button (JS behavior untested)
- ✗ Focus visibility at 200% zoom
- ✗ Screen reader announcements
- ✗ Dynamic state changes or error messages
- ✗ Modal or form submission behavior

**Conformance:**
This page **does not conform to WCAG 2.2 AA** based on static analysis. Nine defects were found, including five critical severity (missing image alt, unlabeled form inputs, non-semantic button element, removed focus indicator, and duplicate IDs). Full conformance cannot be claimed without:
1. Running an automated scan (axe-core) on the rendered page
2. Testing keyboard navigation end-to-end
3. Testing with a screen reader
4. Verifying color contrast and resize text at actual render time
5. Testing all user flows and error states

**Criteria with automated pass:** 3.1.1 Language of Page (if `lang` is added).  
**Criteria not audited:** 1.4.4 Resize Text, 2.5.7 Dragging Movements, 2.5.8 Target Size, 3.2.6 Consistent Help, 3.3.7 Redundant Entry, and manual checks for keyboard trap, color-blindness, and screen reader.
