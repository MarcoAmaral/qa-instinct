### Per condition

| Condition | n | Content pass | 95% CI (exact) | Contract pass | 95% CI (exact) | Content score | Judge pass | Mean cost per generation, judge included (US$) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | 90 | 31/90 (34.4%) | 24.7% to 45.2% | 3/90 (3.3%) | 0.7% to 9.4% | 82.8% | 20/30 | 0.4120 |
| B | 90 | 35/90 (38.9%) | 28.8% to 49.7% | 5/90 (5.6%) | 1.8% to 12.5% | 83.6% | 20/30 | 0.5140 |
| C | 90 | 36/90 (40.0%) | 29.8% to 50.9% | 3/90 (3.3%) | 0.7% to 9.4% | 84.3% | 22/30 | 0.5215 |
| D | 90 | 86/90 (95.6%) | 89.0% to 98.8% | 90/90 (100.0%) | 96.0% to 100.0% | 99.5% | 23/30 | 1.0652 |

### Content pass by task

| Task | A | B | C | D |
| --- | --- | --- | --- | --- |
| a11y-signup-form | 0/10 | 0/10 | 3/10 | 6/10 |
| api-orders-contract | 7/10 | 6/10 | 6/10 | 10/10 |
| bdd-loyalty-points | 6/10 | 10/10 | 10/10 | 10/10 |
| cases-order-status | 0/10 | 0/10 | 0/10 | 10/10 |
| cases-quantity | 1/10 | 1/10 | 0/10 | 10/10 |
| cases-shipping-fee | 2/10 | 0/10 | 0/10 | 10/10 |
| defect-gift-card | 5/10 | 10/10 | 4/10 | 10/10 |
| flaky-run-history | 9/10 | 8/10 | 9/10 | 10/10 |
| plan-split-payment | 1/10 | 0/10 | 4/10 | 10/10 |

### Contrasts on content pass

| Contrast | Difference (points) | 98.33% bootstrap interval | Tasks | Smallest cell | Reading |
| --- | --- | --- | --- | --- | --- |
| D vs C | +55.6 | +46.7 to +64.4 | 9 | 10 | supports the claim |
| D vs B | +56.7 | +50.0 to +63.3 | 9 | 10 | supports the claim |
| D vs A | +61.1 | +51.1 to +71.1 | 9 | 10 | supports the claim |

Content pass: every `con-` grader of the task passed. Intervals per condition are exact (Clopper-Pearson); contrasts average the per-task difference with equal task weight, bootstrap 10000 replicates resampling runs within each task and condition, seed 20261018, Bonferroni over 3 contrasts. A contrast is read only when every cell holds at least 8 generations.
