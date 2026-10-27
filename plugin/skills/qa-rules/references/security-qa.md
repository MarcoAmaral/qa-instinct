# Security QA Rules & Guidelines

> **OWASP Top 10 Client-Side Compliance** | Penetration Auditing | Input Validation | Safe Payload Standards

This ruleset governs security-related QA processes, verification checkpoints, automated vulnerability checks, and security-focused regression test designs. AI agents and QA engineers must apply these rules to identify security vulnerabilities before code is promoted.

---

## 🔒 OWASP Client-Side Must-List

- **Injection**: escape or sanitize all rendered data (e.g. DOMPurify); no unsanitized `dangerouslySetInnerHTML` or `v-html`; never concatenate user input into scripts, event handlers or queries; queries are parameterized.
- **Sessions**: tokens live in `HttpOnly`, `Secure`, `SameSite=Strict` cookies, never in `localStorage` or `sessionStorage`; logout invalidates the session server-side and clears cookies.
- **Sensitive data**: HTTPS only, with HSTS; no passwords, card numbers, tokens or stack traces in the console or telemetry in production.
- **BOLA**: a request with another user's resource ID must not return that user's data.
- **CSRF**: state-changing requests carry an anti-CSRF token or rely on `SameSite` cookies.

Full verification list, the `npm audit` gate, the XSS payload spec and the manual checklist: the `qa-reference` skill's `references/security-checks.md`.
