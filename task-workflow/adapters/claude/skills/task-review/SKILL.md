---
name: task-review
description: Perform the mandatory completion review for a task workflow.
disable-model-invocation: true
---

Inspect the actual diff, source, tests, plan, implementation report, and
validation records. Map every requirement to concrete evidence. A completed
review must include reviewed=true, a passed evidence item for every requirement,
remainingRequired=[], and deferredChecks whose required value is false. If a
real requirement or mandatory check is missing, report progress with a concrete
fix; do not hide it in an optional deferred check. Write only the current
attempt's receipt JSON after recording the review.
