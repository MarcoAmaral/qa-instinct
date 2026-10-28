---
type: llm
---

PASS if the reply recognizes that the two rules reported on src/users.ts line 6
(`tainted-sql-string` and `node-postgres-sqli`) are one defect, and triages it once (one row or
item that names both rules, or an explicit statement that they are duplicates).
FAIL if it lists them as two separate problems to fix without saying they are the same defect.
