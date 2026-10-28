---
type: regex
target: last_message
flags: i
pattern: '\b500\b[^\n]{0,200}(?:undocumented|not documented|not declared|isn''t documented|is not in|not listed|missing from|absent from|201\b[^\n]{0,30}\b(?:or|and)\b[^\n]{0,30}\b400\b)|(?:undocumented|not documented|not declared|not listed)[^\n]{0,200}\b500\b|\b(?:only|just)\s+`?201`?\s*(?:and|,)\s*`?400`?[^\n]{0,200}\b500\b'
---

The 500 response is not documented in the contract (said in those words, or by setting it against the only statuses documented, 201 and 400).
