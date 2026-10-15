---
name: task-analyze
description: Analyze a task workflow requirement without changing business code.
disable-model-invocation: true
---

Analyze the repository and the requirement. Establish the root cause, constraints,
alternatives, decision, risks, and evidence. Do not modify business code. Write
the non-empty analysis artifact at the exact path supplied by the task workflow.
At the end, write only the current attempt's receipt JSON. Never edit state.json.
