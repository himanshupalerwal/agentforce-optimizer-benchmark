# Results

This folder holds the raw Testing Center results from the article's test.
It stays empty until the runs are done. Nothing here is estimated or
reconstructed.

When the runs are done, it holds:

```
results/
  baseline/                      the day-one agent, version 1
    run-1/test-result-<id>.json  raw Testing Center result, unedited
    run-2/test-result-<id>.json
    run-3/test-result-<id>.json
    scoring-sheet.csv            filled in by npm run score -- baseline
    scores.md                    per-category table and every failed check
  after/                         the agent after applying Optimizer's recommendations
    run-1/ run-2/ run-3/         the same layout
    scoring-sheet.csv
    scores.md
  overrides.md                   every AI-judged answer overruled by hand, and why
  recommendations.md             each Optimizer recommendation, applied or not, and why
```

Run a phase with the Salesforce CLI, three times:

```bash
sf agent test run --api-name Store_Agent_30_Questions --wait 90 \
  --result-format json --output-dir results/baseline/run-1
npm run score -- baseline
```

Rules for this folder:

- Raw exports go in exactly as Testing Center produced them. Corrections go
  in the scoring sheet's notes column and in `overrides.md`, never in the
  raw file.
- Before committing, remove anything that identifies the org or a real
  person, such as org IDs, usernames, or instance URLs.
- The baseline and after runs use the same 30 questions from
  `test-set/test-set.csv`, unchanged.
