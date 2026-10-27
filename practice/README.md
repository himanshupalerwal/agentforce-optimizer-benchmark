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
| `customer_turn_2` | A follow-up, usually the details the agent asks for. The runner sends it as the second message. Usually empty. |
| `lookup_result`, `return_decision` | What a correct agent would get and decide, recomputed from the sample data by `npm run check` |

## Using them

1. Turn on session tracing: Setup, Einstein Audit, Analytics, and Monitoring
   Setup. Select the default data space and turn on Agentforce Session
   Tracing. Without it, conversations leave no record for Optimizer.
2. Run all 60 against the published agent, one session each:

   ```bash
   npm run practice -- <target-org>
   ```

   The script runs `npm run check` first and refuses to send a line that
   matches a test question. Each transcript is saved under `practice/runs/`.
3. Point Optimizer at those sessions. Never point it at the test set, and
   never upload `test-set/test-set.csv` anywhere Optimizer can read it.

## A note on setup previews

While checking the setup on October 26, 2026, I ran four previews in the test
org that used test questions word for word: PQ-02 three times and OS-01 once.
That breaks the rule in [docs/agent-setup.md](../docs/agent-setup.md) to check
the setup with questions outside the test set. Session tracing was not on yet,
so those previews left no record for Optimizer to read. The 60 practice
conversations ran after tracing was turned on.
