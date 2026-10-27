# Contributing

This repo is the companion to an article, so its job is to stay **correct** and
**reproducible** rather than to grow features. The most valuable contributions
are corrections: a claim that has gone stale, a platform behaviour that changed,
a step that no longer works in a fresh org.

## Before you open a PR

```bash
npm run check                 # the test set, data, flows and docs agree (no org needed)
npm run test:apex             # the flow tests, in a sandbox or Developer Edition org
sf apex run --file scripts/apex/check-model-access.apex   # what your org allows
```

## Ground rules

**The test set is locked.** The 30 questions, their expected answers and the
scoring rules in [test-set/README.md](test-set/README.md) are the referee. A pull
request that edits them changes what every result means. Add new questions in a
new file instead.

**The practice set never overlaps the test set.** `npm run check` fails if a
practice line shares four words in a row with a test question, or mentions a
test order or email. Keep it that way.

**Raw results are never edited.** Corrections to an AI-judged answer go in the
phase's `overrides.csv`, with a reason, never in the Testing Center file.

**Claims must be checkable.** Every statement about platform behaviour should be
verifiable with a command a reader can run. If you cannot verify it, soften it or
drop it.

**Never deploy to a production org.** Testing Center runs the flows for real.

## Reporting a correction

Open an issue with the command you ran and its output. Platform behaviour is the
arbiter: if the org disagrees with this repo, the repo is wrong.
