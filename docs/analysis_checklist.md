# Analysis checklist

## Before the analysis
- [ ] Which table is the source of truth, and at what level (one row = what)?
- [ ] Do I need a join? If yes: check no rows are lost or duplicated (row counts, LEFT JOIN null check)
- [ ] Which rows should be excluded? (cancelled/returned orders, test data, outliers)
- [ ] Is every group big enough to be reliable? (count rows per group)

## Writing the query
- [ ] Do the parts add up to the total?
- [ ] ELSE 'unassigned' in CASE WHEN, to catch gaps
- [ ] Round only for display

## Interpreting the result
- [ ] Compare with a baseline: "compared with what?"
- [ ] Every percentage: "% of what?"
- [ ] Calculate differences instead of eyeballing them
- [ ] Could something else explain it? (product mix, timing, customer type)
- [ ] Does the result look too neat? (synthetic data, generation rules)

## Writing it up
- [ ] Units and currency on every number
- [ ] Finding → recommendation → limitations
- [ ] Before/after comparison whenever a filter or assumption changes
