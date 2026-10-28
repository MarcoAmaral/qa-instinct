---
type: regex
target: last_message
flags: i
pattern: '^(?=[\s\S]*Severity\b[^\n]{0,40}(?:\n[ \t>*#_-]*)?[^\n]{0,20}?\b(?:Critical|High|Medium|Low|Major|Minor|S[1-4])\b)(?=[\s\S]*Priority\b[^\n]{0,40}(?:\n[ \t>*#_-]*)?[^\n]{0,20}?\b(?:P[0-4]|Critical|High|Medium|Low|Urgent|Blocker)\b)'
---

Severity and priority are both given, each with a value (on the same line or the line after its label).
