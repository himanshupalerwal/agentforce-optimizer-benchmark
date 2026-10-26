# The test set

`test-set.csv` holds the 30 questions that score the agent. It is the referee.
It is locked before the first baseline run and never changes between the
baseline and the after runs.

**Never show these questions to Agent Optimizer.** If Optimizer sees the test,
it can tune the agent to pass it, and the result proves nothing. Optimizer
works only from the 60 conversations in [`../practice/`](../practice/).

## Columns

| Column | What it holds |
| --- | --- |
| `id` | `OS`, `RT`, `PQ`, `VM`, `OT` or `ES`, then a number |
| `category` | Order status 6, Returns 6, Product questions 6, Vague or multi-part 4, Off-topic 4, Escalation 4 |
| `customer_says` | The customer's message, exactly as it is sent |
| `expected_subagent` | Order Status, Returns, Product Help, or the template's Escalation, Off Topic or Ambiguous Question |
| `expected_action` | Get Order Status, Create Return Case, Answer Questions with Knowledge, Escalate, or None. A `+` joins two actions. |
| `expected_answer` | What a passing answer does |
| `lookup_result` | What Get Order Status returns for each order mentioned: `verified` or `not_verified`. `n/a` when no lookup is expected. |
| `return_decision` | What a correct agent decides about a return: `case`, or why not: `no_case_window`, `no_case_final_sale`, `no_case_not_delivered` |

The last two columns are for `npm run check`, which recomputes them from the
sample data. They are not uploaded to Testing Center.

## Scoring

Each question gets three checks in Testing Center: the right subagent, the
right action (or no action), and an acceptable answer. A question passes only
if all three pass. The answer check is AI-judged, so read every answer and log
each override in `results/overrides.md`.

Run the full set three times for each agent version. Record Pass or Fail per
run in a copy of `scoring-sheet.csv`. A question passes if it passes in at
least two of the three runs:

```
=IF(COUNTIF(C2:E2,"Pass")>=2,"Pass","Fail")
```

## How a run is scored

The rule below was fixed before the first baseline run.

| Check | Passes when |
| --- | --- |
| Subagent | The subagent Testing Center reports contains the expected API name |
| Action | The set of actions the agent invoked is exactly the expected set. Order and repeats are ignored. "None" means no action at all. |
| Answer | Testing Center's AI-judged response rating passes |

A question passes a run only if all three checks pass. It passes overall if it
passes in at least two of the three runs.

The action check is stricter than Testing Center's own. Testing Center only
checks that the expected actions appear, so it would pass RT-04 even if the
agent opened a return case it should not have. `npm run score` reads the
actions each run actually invoked from the raw results and applies the exact
rule above. The raw results stay untouched.

### Changed after Run 1 of the baseline

Two parts of the rule were changed after the baseline's first run, before any
scoring. Both changes are applied the same way to every run, before and
after, and no raw result was edited.

- **Knowledge and escalation are not checked as actions.** Testing Center
  never lists the knowledge lookup or the template's escalation step among a
  run's invoked actions, even when the agent clearly used them: Run 1's
  answers quote the knowledge articles almost word for word. Under the
  original rule, 13 questions would fail the action check in every run,
  whatever the agent did. Now the action check compares only the actions
  Testing Center records: Get Order Status and Create Return Case. A
  knowledge or escalation question must invoke no flow action, and the
  answer check confirms the content.
- **OT-04 also passes the subagent check on `Prompt_Injection`.** Salesforce's
  built-in injection guard can catch the message before any subagent runs.
  The behavior the test asks for is a refusal with no lookup, and that is
  what happened.

The automated score comes before the human review: read every answer and log
each override in `results/overrides.md`.

## Loading it into Testing Center

`testing-center-spec.yaml` is the same 30 questions in the format the
Salesforce CLI uploads (`sf agent test create`), with the agent's API names.
`npm run build:test-spec` regenerates it from the CSV.

To use the Testing Center UI instead, download the CSV template from your org's Testing Center and copy the
`customer_says`, `expected_subagent`, `expected_action` and `expected_answer`
columns across. Column names differ between the legacy Testing Center in Setup
and the newer one in Agentforce Studio, so always start from the template your
org gives you. Use the subagent and action names exactly as your agent shows
them.

## Settle these before Run 1

Decide them once, write the decision here, and do not change them after you
see a result.

- **Vague questions.** VM-01 and VM-02 name the subagent most likely to ask the
  clarifying question. If your agent's router asks it before any subagent,
  record what Testing Center reports.
- **OT-04.** The platform may catch the injection attempt before any subagent
  runs and report its own topic instead of Off Topic. The behavior that matters
  is that it refuses and runs no lookup.
- **Escalation.** Use the action name your template's escalation shows, and
  note whether the org has a live person to hand off to.
- **The template's Ambiguous Question subagent.** The service agent template
  ships Escalation, Off Topic and Ambiguous Question, and all three stay as
  they are. VM-02 ("They don't fit.") expects Ambiguous Question. VM-01 ("I
  need help with an order.") names an order, so it expects Order Status.
- **VM-03 needs two skills.** It asks for an order status and a shipping
  price. The day-one Order Status subagent has no knowledge action, so the
  baseline is expected to miss half of it. That is a real gap for Optimizer to
  find, not a setup error.
