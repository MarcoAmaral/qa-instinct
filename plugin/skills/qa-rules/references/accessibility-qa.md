# Accessibility (a11y) QA Rules & Guidelines

> **WCAG 2.2 AA Standard** | Semantic HTML | Screen Reader Testing | Automated & Manual Audits

This ruleset governs all Accessibility (a11y) testing processes, test criteria, and automated verification rules. AI agents and QA engineers must apply these rules to ensure the user interface is accessible to all users, including those relying on assistive technologies.

---

## ♿ WCAG 2.2 AA Must-List

- **Text alternatives (1.1.1)**: images and icons carry `alt` or `aria-label`; decorative ones `alt=""` or `role="presentation"`.
- **Contrast (1.4.3, 1.4.11)**: 4.5:1 normal text; 3:1 large text (≥18pt, ≥14pt bold) and UI components.
- **Resize (1.4.4)**: text resizes to 200% with no clipped or lost content.
- **Keyboard (2.1.1, 2.1.2)**: everything works with `Tab`, `Enter` and `Space`; no focus trap; modals close on `Escape`.
- **Focus (2.4.7, 2.4.3)**: visible focus indicator (no `outline: none` without a `:focus-visible` style); logical order; no `tabindex` above 0.
- **Language (3.1.1)**: `<html>` has a valid `lang`.
- **Predictable (3.2.1, 3.2.2)**: focus or input never changes context unannounced.
- **Errors (3.3.1, 3.3.3)**: described in text, announced via `aria-describedby` or `role="alert"`.
- **Name, role, value (4.1.2)**: custom controls carry the correct ARIA role and state.

Full criteria, the `@axe-core/playwright` audit template and the manual checklist: the `qa-reference` skill's `references/accessibility-checks.md`.
