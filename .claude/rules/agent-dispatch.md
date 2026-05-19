# Mandatory Agent Dispatch

**When a skill specifies worker-critic pairs, dispatch each as a separate subagent via the Task tool. Never run worker-critic work inline.**

---

## The Rule

Skills that specify `allowed-tools: [..., "Task"]` and define worker-critic pairs (e.g., Strategist → strategist-critic, Coder → coder-critic) MUST dispatch those agents via `Task`, not by executing them inline in the main conversation.

Running worker-critic work inline is a **protocol violation**. The adversarial separation is the point — a worker that reviews its own output is not a critic.

## Mandatory pairs

| Skill | Worker | Critic |
|-------|--------|--------|
| `/strategize` | strategist | strategist-critic |
| `/analyze` | coder | coder-critic |
| `/write` | writer | writer-critic |
| `/review` | domain-referee + methods-referee | editor |
| `/talk` | storyteller | storyteller-critic |
| `/stata-analysis` | (inline) | coder-critic (review phase) |

## How to dispatch

Use the `Task` tool with `subagent_type` matching the agent name:

```
Task({
  subagent_type: "strategist",
  description: "Draft identification strategy",
  prompt: "..."
})
```

Wait for the worker to complete, then dispatch the critic:

```
Task({
  subagent_type: "strategist-critic",
  description: "Review identification strategy",
  prompt: "Review the strategy memo at [path]. Score against the rubric..."
})
```

## When this rule applies

- Any invocation of a skill listed above
- Any time the user says "use agents", "dispatch agents", or "run the full pipeline"

## When this rule does NOT apply

- Simple utility skills (`/checkpoint`, `/compile-latex`, `/context-status`) — no worker-critic pairs
- Quick one-off tasks explicitly scoped by the user ("just run this script")
- The simplified research orchestrator loop (`orchestrator-research.md`) — that's a single-agent loop by design
