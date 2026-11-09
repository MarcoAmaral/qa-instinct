### Per condition

| Condition | n | Content pass | 95% CI (exact) | Contract pass | 95% CI (exact) | Content score | Judge pass | Mean cost per generation, judge included (US$) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | 90 | 16/90 (17.8%) | 10.5% to 27.3% | 2/90 (2.2%) | 0.3% to 7.8% | 72.1% | 18/30 | 0.0269 |
| B | 90 | 26/90 (28.9%) | 19.8% to 39.4% | 3/90 (3.3%) | 0.7% to 9.4% | 77.0% | 20/30 | 0.0290 |
| C | 90 | 16/90 (17.8%) | 10.5% to 27.3% | 0/90 (0.0%) | 0.0% to 4.0% | 66.7% | 13/30 | 0.0353 |
| D | 90 | 63/90 (70.0%) | 59.4% to 79.2% | 78/90 (86.7%) | 77.9% to 92.9% | 90.5% | 27/30 | 0.0523 |

### Content pass by task

| Task | A | B | C | D |
| --- | --- | --- | --- | --- |
| a11y-signup-form | 0/10 | 0/10 | 0/10 | 6/10 |
| api-orders-contract | 3/10 | 6/10 | 6/10 | 7/10 |
| bdd-loyalty-points | 0/10 | 0/10 | 0/10 | 0/10 |
| cases-order-status | 2/10 | 4/10 | 2/10 | 4/10 |
| cases-quantity | 0/10 | 2/10 | 1/10 | 10/10 |
| cases-shipping-fee | 0/10 | 0/10 | 0/10 | 7/10 |
| defect-gift-card | 0/10 | 3/10 | 0/10 | 9/10 |
| flaky-run-history | 8/10 | 9/10 | 7/10 | 10/10 |
| plan-split-payment | 3/10 | 2/10 | 0/10 | 10/10 |

### Contrasts on content pass

| Contrast | Difference (points) | 98.33% bootstrap interval | Tasks | Smallest cell | Reading |
| --- | --- | --- | --- | --- | --- |
| D vs C | +52.2 | +41.1 to +63.3 | 9 | 10 | supports the claim |
| D vs B | +41.1 | +28.9 to +53.3 | 9 | 10 | supports the claim |
| D vs A | +52.2 | +41.1 to +63.3 | 9 | 10 | supports the claim |

Content pass: every `con-` grader of the task passed. Intervals per condition are exact (Clopper-Pearson); contrasts average the per-task difference with equal task weight, bootstrap 10000 replicates resampling runs within each task and condition, seed 20261018, Bonferroni over 3 contrasts. A contrast is read only when every cell holds at least 8 generations.
