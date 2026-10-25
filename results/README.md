# Results

This folder holds the raw Testing Center results from the article's test.
It stays empty until the runs are done. Nothing here is estimated or
reconstructed.

When the runs are done, it holds:

```
results/
  baseline/              the day-one agent, version 1
    run-1.csv            raw Testing Center export, unedited
    run-2.csv
    run-3.csv
    scoring-sheet.csv    a filled-in copy of test-set/scoring-sheet.csv
  after/                 the agent after applying Optimizer's recommendations
    run-1.csv
    run-2.csv
    run-3.csv
    scoring-sheet.csv
  overrides.md           every AI-judged answer that was overruled by hand, and why
  recommendations.md     each Optimizer recommendation, whether it was applied, and why
```

Rules for this folder:

- Raw exports go in exactly as Testing Center produced them. Corrections go
  in the scoring sheet's notes column and in `overrides.md`, never in the
  raw file.
- Before committing, remove anything that identifies the org or a real
  person, such as org IDs, usernames, or instance URLs.
- The baseline and after runs use the same 30 questions from
  `test-set/test-set.csv`, unchanged.
