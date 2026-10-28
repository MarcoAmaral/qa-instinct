---
type: regex
target: last_message
flags: i
match: not_contains
pattern: '(?<!(?:obsolete|retired|deprecated|legacy|no longer|(?:was|been|is) removed|removed (?:in|from) (?:WCAG )?2\.2)[\s\S]{0,200})(?<!(?:WCAG |under |in |and |or |/)2\.[01](?!\.\d)[\s\S]{0,80})\b4\.1\.1\b(?![\s\S]{0,200}(?:obsolete|retired|deprecated|legacy|no longer|(?:was|been|is) removed|removed (?:in|from) (?:WCAG )?2\.2))(?![^\n]{0,60}(?:WCAG |under |in |and |or |/)2\.[01](?!\.\d))'
---

The duplicate id is not reported under 4.1.1 Parsing, which WCAG 2.2 made obsolete; a mention that says it is obsolete, retired or deprecated, or that applies it only under WCAG 2.0 or 2.1, is allowed.
