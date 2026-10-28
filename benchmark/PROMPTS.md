# Benchmark prompts (frozen with METHODOLOGY.md)

Every condition sends the same task prompt. Only the preamble before it and the plugin the run loads
differ (`METHODOLOGY.md`, "Conditions"). `benchmark/build.js` reads this file and nothing else for
the text it sends, so what is below is exactly what the model receives, with two mechanical steps:

1. Each `{{fixture:<file>}}` line is replaced by the contents of
   `benchmark/fixtures/<task>/<file>`, without its final newline.
2. The message is the preamble, one space, the task prompt, a blank line and the common closing. With
   no preamble (condition A) the message starts at the task prompt.

The prompts name no technique, no format and no command: whatever the output contains beyond the
request comes from the model and the condition. The fixtures use made-up products and data.

## Preambles

### A

(none)

### B

```text
Work as a thorough, professional QA engineer.
```

### C

```text
/writing-guide:help-articles
```

### D

```text
/qa-instinct:{{command}}
```

`{{command}}` is the task's command or skill, from the line "D invokes" under each task.

## Common closing

```text
Where information is missing, state your assumption and continue; do not ask questions. Reply with the deliverable only, as Markdown, starting at its first line, with no introduction and no code fence around it. Do not create or edit files.
```

## Task 1: cases-quantity

D invokes: `qa-cases`

```text
Write test cases for the user story below.

{{fixture:story.md}}
```

## Task 2: cases-order-status

D invokes: `qa-cases`

```text
Write test cases for the user story below.

{{fixture:story.md}}
```

## Task 3: cases-shipping-fee

D invokes: `qa-cases`

```text
Write test cases for the user story below.

{{fixture:story.md}}
```

## Task 4: defect-gift-card

D invokes: `qa-defect`

```text
Write a defect report for the failure in the CI log below.

~~~text
{{fixture:failure-log.txt}}
~~~
```

## Task 5: plan-split-payment

D invokes: `qa-plan`

```text
Write a risk-based test plan for the feature below.

{{fixture:brief.md}}
```

## Task 6: api-orders-contract

D invokes: `qa-api`

```text
Check the recorded responses below against the API's OpenAPI contract, report every mismatch, and design the tests this API needs.

~~~yaml
{{fixture:openapi.yaml}}
~~~

{{fixture:responses.txt}}
```

## Task 7: a11y-signup-form

D invokes: `qa-a11y`

```text
Audit the accessibility of the sign-up page below. You have its source only; you cannot open it in a browser.

~~~html
{{fixture:signup.html}}
~~~
```

## Task 8: flaky-run-history

D invokes: `qa-flaky`

```text
Analyse the CI history below and tell the team which tests are flaky, why, and what to do with each.

{{fixture:run-history.md}}
```

## Task 9: bdd-loyalty-points

D invokes: `qa-bdd`

```text
Write BDD scenarios in Gherkin for the user story below.

{{fixture:story.md}}
```
