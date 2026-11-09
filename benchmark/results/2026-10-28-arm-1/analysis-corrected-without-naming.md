### Per condition

| Condition | n | Content pass | 95% CI (exact) | Contract pass | 95% CI (exact) | Content score | Judge pass | Mean cost per generation, judge included (US$) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | 90 | 47/90 (52.2%) | 41.4% to 62.9% | 2/90 (2.2%) | 0.3% to 7.8% | 85.1% | 18/30 | 0.0269 |
| B | 90 | 54/90 (60.0%) | 49.1% to 70.2% | 3/90 (3.3%) | 0.7% to 9.4% | 87.4% | 20/30 | 0.0290 |
| C | 90 | 43/90 (47.8%) | 37.1% to 58.6% | 0/90 (0.0%) | 0.0% to 4.0% | 77.0% | 13/30 | 0.0353 |
| D | 90 | 72/90 (80.0%) | 70.2% to 87.7% | 78/90 (86.7%) | 77.9% to 92.9% | 93.2% | 27/30 | 0.0523 |

### Content pass by task

| Task | A | B | C | D |
| --- | --- | --- | --- | --- |
| a11y-signup-form | 0/10 | 0/10 | 0/10 | 7/10 |
| api-orders-contract | 5/10 | 8/10 | 8/10 | 7/10 |
| bdd-loyalty-points | 1/10 | 1/10 | 0/10 | 3/10 |
| cases-order-status | 9/10 | 10/10 | 7/10 | 7/10 |
| cases-quantity | 10/10 | 10/10 | 9/10 | 10/10 |
| cases-shipping-fee | 9/10 | 10/10 | 8/10 | 8/10 |
| defect-gift-card | 0/10 | 3/10 | 0/10 | 10/10 |
| flaky-run-history | 10/10 | 10/10 | 10/10 | 10/10 |
| plan-split-payment | 3/10 | 2/10 | 1/10 | 10/10 |

### Contrasts on content pass

| Contrast | Difference (points) | 98.33% bootstrap interval | Tasks | Smallest cell | Reading |
| --- | --- | --- | --- | --- | --- |
| D vs C | +32.2 | +21.1 to +43.3 | 9 | 10 | supports the claim |
| D vs B | +20.0 | +8.9 to +30.0 | 9 | 10 | supports the claim |
| D vs A | +27.8 | +16.7 to +38.9 | 9 | 10 | supports the claim |

Content pass: every `con-` grader of the task passed. Intervals per condition are exact (Clopper-Pearson); contrasts average the per-task difference with equal task weight, bootstrap 10000 replicates resampling runs within each task and condition, seed 20261018, Bonferroni over 3 contrasts. A contrast is read only when every cell holds at least 8 generations.
