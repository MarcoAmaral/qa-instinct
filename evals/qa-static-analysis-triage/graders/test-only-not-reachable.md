---
type: llm
---

PASS if the reply treats the tests/seed.ts finding as test-only code that does not run in
production, so it is not a product vulnerability and gets a low priority or is suppressed or
excluded with that reason.
FAIL if it ranks the tests/seed.ts finding as a high-severity production vulnerability, or does
not mention that the file is test code.
