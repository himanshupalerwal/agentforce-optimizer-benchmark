# Results

This folder holds the raw Testing Center results from the benchmark.
A phase's folder fills only after its runs are done. Nothing here is
estimated or reconstructed. The baseline is done; the after phase has not
run yet.

When both phases are done, it holds:

```
results/
  baseline/                      the day-one agent, version 1
    run-1/test-result-<id>.json  raw Testing Center result, unedited
    run-2/test-result-<id>.json
    run-3/test-result-<id>.json
    scoring-sheet.csv            filled in by npm run score -- baseline
    scores.md                    per-category table and every failed check
    overrides.csv                AI-judged answers overruled by hand, and why
  after/                         the agent after applying Optimizer's recommendations
    run-1/ run-2/ run-3/         the same layout
    scoring-sheet.csv
    scores.md
    overrides.csv
  recommendations.md             each Optimizer recommendation, applied or not, and why
  model-check/                   npm run check:model output, Developer Edition and trial
  gateway/                       npm run logs:models output: model calls by feature
```

`model-check/` and `gateway/` hold the evidence for why the after phase has
not run: in both orgs, Claude Sonnet answered and Claude Opus was refused
with `limit=0`, and in the Developer Edition org, Agent Optimizer sent 120
calls to Opus and got 0 tokens back.

Run a phase with the Salesforce CLI, three times, after `npm run deploy:test`:

```bash
sf agent test run --api-name Store_Agent_30_Questions --wait 90 \
  --result-format json --output-dir results/baseline/run-1
npm run score -- baseline
```

For the after phase, set `subjectVersion` to `v2` in the test definition,
run `npm run deploy:test` again, and write to `results/after/run-1` to
`run-3`. `npm run score` refuses a phase until all three runs are there.

Rules for this folder:

- Raw exports go in exactly as Testing Center produced them. Corrections go
  in the scoring sheet's notes column and in `overrides.csv`, never in the
  raw file.
- Before committing, remove anything that identifies the org or a real
  person, such as org IDs, usernames, or instance URLs.
- The baseline and after runs use the same 30 questions from
  `test-set/test-set.csv`, unchanged.
