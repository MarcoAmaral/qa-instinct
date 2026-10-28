---
type: llm
---

PASS if the reply treats the finding at src/users.ts line 6 (the request's `name` interpolated
into the SQL string) as a real SQL injection that must be fixed, and the fix it names is a
parameterized query or placeholder (for example `$1` with the value passed separately).
FAIL if it calls that finding a false positive, leaves it unfixed, or proposes only escaping or
input validation instead of a parameterized query.
