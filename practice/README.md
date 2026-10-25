# Practice conversations

`practice-conversations.csv` holds 60 conversations for Agent Optimizer to
learn from. They cover the same kinds of requests as the test set, twice over,
in different words.

They share no wording, no order numbers, and no customer emails with the 30
test questions. `npm run check` enforces that: it fails if any practice line
shares a run of four words with a test question, overlaps one too closely, or
mentions a test order or email.

The practice orders are RO-1007 to RO-1012, loaded by the same sample-data
script. Order numbers in the RO-20xx range do not exist on purpose.

## Columns

| Column | What it holds |
| --- | --- |
| `id` | `PR-01` to `PR-60` |
| `category` | The same six categories as the test set |
| `customer_turn_1` | The customer's opening message |
| `customer_turn_2` | A follow-up, sent only if the agent asks for it. Usually empty. |
| `lookup_result`, `return_decision` | What a correct agent would get and decide, recomputed from the sample data by `npm run check` |

## Using them

Run each conversation against the agent so the sessions exist for Optimizer
to analyze. Then point Optimizer at those sessions. Never point it at the test
set, and never upload `test-set/test-set.csv` anywhere Optimizer can read it.
