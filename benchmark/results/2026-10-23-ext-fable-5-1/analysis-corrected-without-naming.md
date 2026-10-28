### Per condition

| Condition | n | Content pass | 95% CI (exact) | Contract pass | 95% CI (exact) | Content score | Judge pass | Mean cost per generation, judge included (US$) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | 90 | 68/90 (75.6%) | 65.4% to 84.0% | 3/90 (3.3%) | 0.7% to 9.4% | 95.2% | 20/30 | 0.4120 |
| B | 90 | 74/90 (82.2%) | 72.7% to 89.5% | 5/90 (5.6%) | 1.8% to 12.5% | 96.1% | 20/30 | 0.5140 |
| C | 90 | 74/90 (82.2%) | 72.7% to 89.5% | 3/90 (3.3%) | 0.7% to 9.4% | 96.2% | 22/30 | 0.5215 |
| D | 90 | 90/90 (100.0%) | 96.0% to 100.0% | 90/90 (100.0%) | 96.0% to 100.0% | 100.0% | 23/30 | 1.0652 |

### Content pass by task

| Task | A | B | C | D |
| --- | --- | --- | --- | --- |
| a11y-signup-form | 3/10 | 8/10 | 6/10 | 10/10 |
| api-orders-contract | 10/10 | 8/10 | 8/10 | 10/10 |
| bdd-loyalty-points | 6/10 | 10/10 | 10/10 | 10/10 |
| cases-order-status | 10/10 | 10/10 | 10/10 | 10/10 |
| cases-quantity | 10/10 | 10/10 | 10/10 | 10/10 |
| cases-shipping-fee | 10/10 | 10/10 | 10/10 | 10/10 |
| defect-gift-card | 9/10 | 10/10 | 7/10 | 10/10 |
| flaky-run-history | 9/10 | 8/10 | 9/10 | 10/10 |
| plan-split-payment | 1/10 | 0/10 | 4/10 | 10/10 |

### Contrasts on content pass

| Contrast | Difference (points) | 98.33% bootstrap interval | Tasks | Smallest cell | Reading |
| --- | --- | --- | --- | --- | --- |
| D vs C | +17.8 | +10.0 to +25.6 | 9 | 10 | supports the claim |
| D vs B | +17.8 | +12.2 to +24.4 | 9 | 10 | supports the claim |
| D vs A | +24.4 | +17.8 to +31.1 | 9 | 10 | supports the claim |

Content pass: every `con-` grader of the task passed. Intervals per condition are exact (Clopper-Pearson); contrasts average the per-task difference with equal task weight, bootstrap 10000 replicates resampling runs within each task and condition, seed 20261018, Bonferroni over 3 contrasts. A contrast is read only when every cell holds at least 8 generations.
