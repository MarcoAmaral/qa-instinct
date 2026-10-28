---
type: regex
target: last_message
flags: i
pattern: '(?:`code`|"code"|\bcode (?:field|property)|\b(?:field|property) .?code\b)[^\n]{0,200}(?:missing|absent|lacks|lacking|not (?:present|returned|included)|omitted|without)|(?:missing|absent|lacks|lacking|not (?:present|returned|included)|omitted|without)[^\n]{0,200}(?:`code`|"code"|\bcode (?:field|property)|\b(?:field|property) .?code\b)|\bcode\b (?:is |was )?(?:missing|absent|not (?:present|returned|included)|omitted)|\bno\s+(?:`code`|\"code\"|code\b)|\b404\b[^\n]{0,250}(?:only `?message`?|fails on `?code`?)'
---

The 404 body lacks `code`, which the Error schema requires.
