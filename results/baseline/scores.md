# Baseline results: automated scores

Scored by `scripts/score-results.mjs` from the raw Testing Center files in this folder.
The answer check is AI-judged. Accepted human overrides are applied; proposed ones are not.

| Category | Questions | Run 1 | Run 2 | Run 3 | Passed (2 of 3 runs) |
| --- | --- | --- | --- | --- | --- |
| Order status | 6 | 4 | 4 | 2 | 3 |
| Returns | 6 | 4 | 3 | 4 | 3 |
| Product questions | 6 | 2 | 2 | 2 | 2 |
| Vague or multi-part | 4 | 2 | 2 | 1 | 2 |
| Off-topic | 4 | 3 | 2 | 4 | 3 |
| Escalation | 4 | 3 | 3 | 3 | 3 |
| **Total** | **30** | **18** | **16** | **16** | **16** |

## Human overrides of the answer check

0 accepted and applied, 8 proposed and not applied. See overrides.csv.

| ID | Run | Judge | Override | Status |
| --- | --- | --- | --- | --- |
| OT-02 | 2 | Fail | Pass | proposed |
| OT-03 | 1 | Fail | Pass | proposed |
| OT-03 | 2 | Fail | Pass | proposed |
| VM-04 | 3 | Fail | Pass | proposed |
| ES-04 | 1 | Pass | Fail | proposed |
| RT-05 | 2 | Pass | Fail | proposed |
| VM-03 | 2 | Pass | Fail | proposed |
| VM-02 | 2 | Pass | Fail | proposed |

## Every failed check

| ID | Run | Failed checks |
| --- | --- | --- |
| OS-01 | 1 | action (got none, want get_order_status); answer |
| OS-01 | 3 | action (got none, want get_order_status); answer |
| OS-03 | 1 | action (got none, want get_order_status); answer |
| OS-03 | 2 | action (got none, want get_order_status); answer |
| OS-03 | 3 | action (got none, want get_order_status); answer |
| OS-05 | 3 | action (got none, want get_order_status); answer |
| OS-06 | 2 | action (got none, want get_order_status) |
| OS-06 | 3 | action (got none, want get_order_status) |
| RT-02 | 2 | action (got create_return_case, want create_return_case+get_order_status) |
| RT-02 | 3 | action (got create_return_case, want create_return_case+get_order_status) |
| RT-03 | 1 | action (got none, want get_order_status); answer |
| RT-03 | 2 | action (got none, want get_order_status); answer |
| RT-05 | 1 | action (got none, want get_order_status); answer |
| RT-05 | 2 | action (got none, want get_order_status) |
| RT-05 | 3 | action (got none, want get_order_status); answer |
| PQ-01 | 1 | subagent (topic_selector) |
| PQ-01 | 2 | subagent (topic_selector) |
| PQ-01 | 3 | subagent (topic_selector) |
| PQ-02 | 1 | subagent (topic_selector) |
| PQ-02 | 2 | subagent (topic_selector) |
| PQ-02 | 3 | subagent (topic_selector) |
| PQ-03 | 1 | subagent (topic_selector) |
| PQ-03 | 2 | subagent (topic_selector) |
| PQ-03 | 3 | subagent (topic_selector) |
| PQ-04 | 1 | subagent (topic_selector) |
| PQ-04 | 2 | subagent (topic_selector) |
| PQ-04 | 3 | subagent (topic_selector) |
| VM-02 | 1 | subagent (product_help) |
| VM-02 | 2 | subagent (product_help) |
| VM-02 | 3 | subagent (returns) |
| VM-03 | 1 | subagent (product_help); action (got none, want get_order_status); answer |
| VM-03 | 2 | subagent (product_help); action (got none, want get_order_status) |
| VM-03 | 3 | subagent (product_help); action (got none, want get_order_status); answer |
| VM-04 | 3 | answer |
| OT-02 | 2 | answer |
| OT-03 | 1 | answer |
| OT-03 | 2 | answer |
| ES-04 | 1 | subagent (returns) |
| ES-04 | 2 | subagent (returns); answer |
| ES-04 | 3 | subagent (returns); answer |
