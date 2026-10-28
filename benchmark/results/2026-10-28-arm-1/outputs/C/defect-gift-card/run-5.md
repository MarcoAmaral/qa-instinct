The writing-guide:help-articles skill is designed for end-user help documentation (how-to, concept, troubleshooting, and reference articles). A defect report is an internal engineering document with a different audience (developers, QA, engineering leads) and different needs (root cause analysis, reproduction steps, environment details, severity, priority).

These serve fundamentally different purposes:

- **Help articles** teach users how to use the product or understand how features work
- **Defect reports** document bugs for the engineering team to diagnose and fix

To write a proper defect report for this CI failure, you'd want a bug-report template with sections like:
- **Summary**: Gift card application fails with currency service error (flaky, 30% failure rate)
- **Steps to Reproduce**: [from the CI log]
- **Expected**: Order summary updates with discounted total
- **Actual**: 500 error, "Cannot read properties of undefined (reading 'currency')"
- **Environment**: Build 4.12.0-rc.2, Chromium 129, Playwright 1.48.1
- **Root Cause**: Currency service cache inconsistency
- **Severity**: Medium (intermittent, blocks gift card checkout)

Would you like me to write this as a standard engineering defect report instead, or did you mean something else?
