---
type: llm
---

PASS if the reply says the `no-explicit-any` warning in src/generated/api-client.ts should be
handled by excluding the generated folder from the lint (or disabling the rule for it), not by
editing the file, because the file is generated ("DO NOT EDIT") and would be overwritten.
FAIL if it recommends editing the generated file to replace `any`, or does not address it.
