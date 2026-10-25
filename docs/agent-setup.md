# Agent setup: the day-one agent

This is the agent exactly as it stood before the baseline runs: template
defaults plus three short subagents. Nothing here is tuned. That is the point:
it is the version most teams ship first, and the version the test measures.

Build it after `npm run deploy`, `npm run load:orders` and
`npm run load:knowledge` (see the [README](../README.md#quick-start)).

## 1. Start from the template

In Agentforce Builder, create a new agent from the standard
**Agentforce Service Agent** template.

Leave the template's escalation and off-topic handling as they are. Do not
edit their instructions. The test's Escalation and Off-topic questions measure
those defaults.

Check which other subagents the template adds, such as a general FAQ or an
ambiguous-question handler. They can take product and vague questions away
from Product Help and the others. Write down what the template contained and
what you kept, and settle the test set's expected subagents to match before
Run 1 (see [test-set/README.md](../test-set/README.md#settle-these-before-run-1)).

## 2. Give the agent's user access

The template creates an agent user. Assign it the permission set that lets it
run the two flows, read orders, and open return cases:

```bash
sf org assign permset --name Store_Orders_Agent --on-behalf-of <agent user's username>
```

Without it, Get Order Status finds nothing and every order question fails for
a reason that has nothing to do with the agent's reasoning.

## 3. Connect the knowledge articles

Point the agent's knowledge source at the eight published articles. Each
article's text is in the standard **Summary** field, so pick **Title** and
**Summary** as the fields to use.

If knowledge questions come back empty in the Builder preview while order
questions work, the agent's user cannot read the articles. Give it Knowledge
read access (the Allow View Knowledge permission) and preview again.

Two topics are left out on purpose: kayaks and warranties. Questions PQ-05
and PQ-06 check that the agent says it does not know instead of inventing an
answer.

## 4. Add the three subagents

Each subagent gets the day-one instructions below, word for word.

### Order Status

**Instructions:**

> Help customers check an order. Ask for the order number and the email on the order. Use Get Order Status, then share the status and the expected delivery date.

**Actions:** Get Order Status (the `Get_Order_Status` flow).

### Returns

**Instructions:**

> Help customers with returns. Explain the return policy from knowledge. If they want to return an order, look it up and open a return case.

**Actions:** Get Order Status, Create Return Case (the `Create_Return_Case`
flow), and the template's knowledge action.

### Product Help

**Instructions:**

> Answer questions about our products and shipping using knowledge articles.

**Actions:** the template's knowledge action.

### Routing descriptions

Builder also asks each subagent for a short description, which the router
uses to pick it. The day-one instructions above do not include one. Write a
one-line description that just names the job, for example "Checks the status
of a customer's order." Keep it that plain, so the baseline stays untuned, and
copy the exact text you used into this file before Run 1.

## 5. Action inputs and outputs

Both flows describe each input and output, and Builder offers those
descriptions as the action's instructions. Keep them.

| Flow | Inputs | Outputs |
| --- | --- | --- |
| Get Order Status | `orderNumber`, `customerEmail` | `verified`, `status`, `item`, `finalSale`, `deliveredDate`, `expectedDeliveryDate`, `daysSinceDelivery` |
| Create Return Case | `orderNumber`, `customerEmail`, `reason` | `created`, `caseNumber` |

When `verified` is false, every other output is blank. A wrong email and a
missing order look the same, so the agent cannot be used to discover who owns
an order.

Get Order Status also returns `finalSale`. Without it the agent could not
know that RO-1006 is final sale, and question RT-04 could not be answered.

Neither flow decides whether a return is allowed. Create Return Case opens a
case for any matching order, final sale or not. The agent must apply the
policy first. `StoreOrderFlowsTest.createReturnCaseDoesNotJudgeEligibility`
pins this.

## 6. Save version 1

Save and activate the agent as its own version before any test run. Every
baseline run uses this version, and you can come back to it at any time.

## 7. Retrieve the agent into the repo

After you build and activate the agent, its metadata is retrieved into
`force-app/` so the day-one version is on record. The exact command depends
on how your org stores the agent, and is filled in here once it has been run
against the real org.
