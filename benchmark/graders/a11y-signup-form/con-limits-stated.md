---
type: regex
target: last_message
flags: i
pattern: 'not checked|could not (?:be )?checked|cannot (?:be )?(?:checked|confirmed|decided|determined) (?:from|without)|needs? (?:a )?(?:manual|browser|person)|requires? (?:a )?(?:manual|browser|running|screen reader)|nothing was (?:verified|tested|run)|not (?:been )?(?:verified|tested) (?:in|with) (?:a )?(?:browser|screen reader|assistive)|no browser|no (?:screen reader|assistive technology)[^\n]{0,40}(?:was|were) (?:run|used)|(?:should|must) be confirmed|needs? confirmation|needing confirmation|(?:is|are) (?:estimated|inferred)|marked (?:as )?(?:estimates?|inferred)'
---

The audit says what it could not check from the source alone.
