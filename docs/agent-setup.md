# Agent setup: the day-one agent

This is the agent exactly as it stood before the baseline runs: the standard
service agent template plus three short subagents. Nothing here is tuned.
That is the point: it is the version most teams ship first, and the version
the test measures.

The whole agent is in one Agent Script file:
[`Gear_Store_Service_Agent.agent`](../force-app/main/default/aiAuthoringBundles/Gear_Store_Service_Agent/Gear_Store_Service_Agent.agent).
You can publish that file, or build the same agent by hand in Agentforce
Builder. Both routes give the same agent.

Build it after `npm run deploy`, `npm run load:orders` and
`npm run load:knowledge` (see the [README](../README.md#quick-start)).

## What you need in the org

| Need | Why |
| --- | --- |
| Agentforce | To build and run the agent |
| Lightning Knowledge | The eight articles live there |
| **Data Cloud** | Knowledge answers go through an Agentforce Data Library, and a Data Library needs Data Cloud. Without it, every knowledge question fails with "We couldn't find a data library assigned to this agent." |
| Testing Center | To run the 30 questions |
| Agent Optimizer (beta) | Only for the "after" half |

Scratch orgs get Data Cloud only by special request through Salesforce
Partner Support, so a standard scratch org can run the order and return
questions but not the knowledge questions.

## 1. The template

The agent starts from the standard **Agentforce Service Agent** template. It
ships three standard subagents, and all three stay exactly as generated:

- **Escalation** hands the conversation to a person.
- **Off Topic** redirects requests outside the agent's job.
- **Ambiguous Question** asks for detail when a request is too vague.

Leave the template's escalation and off-topic handling as they are, and its
Ambiguous Question subagent too. The test's Escalation, Off-topic and vague
questions measure those defaults.

The template's system instructions ("You are an AI Agent."), welcome message,
and messaging variables are also left as generated. The only template change
is the router: it gets three more transitions, one per custom subagent.

## 2. The agent's user

Create the user the agent runs as, then give it the permission set that lets
it run the two flows, read orders, and open return cases:

```bash
sf org create agent-user --first-name Store --last-name Agent
sf org assign permset --name Store_Orders_Agent --on-behalf-of <agent user's username>
```

Put that username in the agent file's `default_agent_user`. The one in the
repo belongs to the org the article's test runs in; yours will differ.

Without the permission set, Get Order Status finds nothing, and every order
question fails for a reason that has nothing to do with the agent's
reasoning.

## 3. Connect the knowledge articles

Create a Data Library from the published articles, indexed on Title and
Summary. Each article's text is in the standard Summary field.

```bash
sf agent adl create --name "Store Knowledge" --developer-name Store_Knowledge \
  --source-type knowledge --primary-index-field1 Title --primary-index-field2 Summary \
  --content-fields Summary --wait 15
```

Then assign the library to the agent. In Agentforce Builder, add it as the
agent's data library. In the agent file, its knowledge configuration ID goes
in `rag_feature_config_id` in the `knowledge:` block.

If knowledge questions still come back empty in the preview while order
questions work, give the agent's user Knowledge read access (the Allow View
Knowledge permission) and preview again.

Two topics are left out on purpose: kayaks and warranties. Questions PQ-05
and PQ-06 check that the agent says it does not know instead of inventing an
answer.

## 4. The three subagents

Each subagent gets the day-one instructions below, word for word, and a
one-line routing description.

### Order Status

**Routing description:** Checks the status of a customer's order.

**Instructions:**

> Help customers check an order. Ask for the order number and the email on the order. Use Get Order Status, then share the status and the expected delivery date.

**Actions:** Get Order Status (the `Get_Order_Status` flow).

### Returns

**Routing description:** Helps customers with returns and the return policy.

**Instructions:**

> Help customers with returns. Explain the return policy from knowledge. If they want to return an order, look it up and open a return case.

**Actions:** Get Order Status, Create Return Case (the `Create_Return_Case`
flow), and Answer Questions with Knowledge.

### Product Help

**Routing description:** Answers questions about products and shipping.

**Instructions:**

> Answer questions about our products and shipping using knowledge articles.

**Actions:** Answer Questions with Knowledge.

## 5. Action inputs and outputs

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

## 6. Publish and save version 1

```bash
sf agent validate authoring-bundle --api-name Gear_Store_Service_Agent
sf agent publish authoring-bundle --api-name Gear_Store_Service_Agent
sf agent activate --api-name Gear_Store_Service_Agent --version 1
```

Publishing creates version 1. Every baseline run uses it, and you can come
back to it at any time. Publishing alone does not activate the agent.

## 7. Check it before Run 1

Preview one order question and one product question:

```bash
sf agent preview start --api-name Gear_Store_Service_Agent
sf agent preview send --api-name Gear_Store_Service_Agent --session-id <id> \
  --utterance "Where is my order RO-1003? My email is taylor@example.com."
```

The order question should call Get Order Status and return `verified` true.
The product question should call Answer Questions with Knowledge without an
error. If either fails, fix the setup before Run 1. A setup failure is not a
result.
