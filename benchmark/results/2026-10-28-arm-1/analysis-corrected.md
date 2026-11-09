### Per condition

| Condition | n | Content pass | 95% CI (exact) | Contract pass | 95% CI (exact) | Content score | Judge pass | Mean cost per generation, judge included (US$) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | 90 | 21/90 (23.3%) | 15.1% to 33.4% | 2/90 (2.2%) | 0.3% to 7.8% | 75.9% | 18/30 | 0.0269 |
| B | 90 | 30/90 (33.3%) | 23.7% to 44.1% | 3/90 (3.3%) | 0.7% to 9.4% | 79.4% | 20/30 | 0.0290 |
| C | 90 | 22/90 (24.4%) | 16.0% to 34.6% | 0/90 (0.0%) | 0.0% to 4.0% | 70.1% | 13/30 | 0.0353 |
| D | 90 | 71/90 (78.9%) | 69.0% to 86.8% | 78/90 (86.7%) | 77.9% to 92.9% | 93.7% | 27/30 | 0.0523 |

### Content pass by task

| Task | A | B | C | D |
| --- | --- | --- | --- | --- |
| a11y-signup-form | 0/10 | 0/10 | 0/10 | 7/10 |
| api-orders-contract | 5/10 | 8/10 | 8/10 | 7/10 |
| bdd-loyalty-points | 1/10 | 1/10 | 0/10 | 3/10 |
| cases-order-status | 2/10 | 4/10 | 2/10 | 7/10 |
| cases-quantity | 0/10 | 2/10 | 1/10 | 10/10 |
| cases-shipping-fee | 0/10 | 0/10 | 0/10 | 7/10 |
| defect-gift-card | 0/10 | 3/10 | 0/10 | 10/10 |
| flaky-run-history | 10/10 | 10/10 | 10/10 | 10/10 |
| plan-split-payment | 3/10 | 2/10 | 1/10 | 10/10 |

### Contrasts on content pass

| Contrast | Difference (points) | 98.33% bootstrap interval | Tasks | Smallest cell | Reading |
| --- | --- | --- | --- | --- | --- |
| D vs C | +54.4 | +43.3 to +64.4 | 9 | 10 | supports the claim |
| D vs B | +45.6 | +33.3 to +56.7 | 9 | 10 | supports the claim |
| D vs A | +55.6 | +44.4 to +66.7 | 9 | 10 | supports the claim |

Content pass: every `con-` grader of the task passed. Intervals per condition are exact (Clopper-Pearson); contrasts average the per-task difference with equal task weight, bootstrap 10000 replicates resampling runs within each task and condition, seed 20261018, Bonferroni over 3 contrasts. A contrast is read only when every cell holds at least 8 generations.
