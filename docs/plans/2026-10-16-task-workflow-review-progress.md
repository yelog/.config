# Task Workflow Review Progress Implementation Plan

**Goal:** Let tasks with new implementation or validation evidence continue beyond three cumulative reviews while stopping repeated reviews without progress.

**Architecture:** Keep the existing four stages, cumulative counters, receipts, prompt identities, and atomic state persistence. Replace the cumulative review ceiling with a persisted comparison of code fingerprints and normalized, deduplicated receipt checks. Record structured pause reasons and persist a one-review reassessment grant for an explicit resume after an external or no-progress pause; bind the grant to the existing receipt identity before admission. Preserve the 40-round stage limit and user-stop protection.

**Tech Stack:** TypeScript, OpenCode V2 plugin/client 2.0.30, Bun tests, temporary Git fixtures.

The user has authorized implementation in this session. Preserve existing workspace changes; do not commit, restart the service, execute a real task, or edit LazyDB task state/worktrees. No delegation or extra execution confirmation is needed.

### Task 1: Reproduce review and recovery failures

Files: `opencode/plugins/task-workflow/recovery.test.ts`, new `opencode/plugins/task-workflow/progress.test.ts`.

1. Add a legacy blocked-task regression with 24 consumed rounds, three prior reviews, pending review, new implementation, and no active receipt. Assert the fourth review is admitted without resetting history.
2. Add scenarios for repeated unchanged reviews, validation-only progress, durable reload, one-shot explicit reassessment, external blocking, and exhausted phase budgets.
3. Run `bun test recovery.test.ts progress.test.ts` and confirm the applicable new scenarios fail before implementation.

### Task 2: Add bounded review progress accounting

Files: `opencode/plugins/task-workflow/progress.ts`, `index.ts`, `progress.test.ts`.

1. Define a small review progress record containing the prior fingerprint, deduplicated normalized check evidence, and consecutive unchanged review count. Keep cumulative `reviews` unchanged.
2. Normalize check strings independently of receipt tokens, next-step prose, timestamps, and duplicate ordering. Repeated checks must not count as new evidence; a changed check result may count.
3. Initialize legacy tasks conservatively from committed checkpoint checks, retaining all counters and allowing one baseline review when previous evidence is unavailable.
4. Update progress together with receipt consumption; stop after three unchanged reviews. Keep review reports sequential and keep all new rounds subject to the existing 40-round limit.

### Task 3: Make pause and resume behavior explicit

Files: `opencode/plugins/task-workflow/index.ts`, `rpc.ts`, `execution.ts` only if the receipt type needs an optional grant marker, and recovery tests.

1. Save typed pause reasons for quota, external dependency, no progress, phase budget, protocol/user/other execution errors; expose them through status with actionable hints.
2. Distinguish periodic review, completion review, and reassessment in instructions without adding stages or changing model routing.
3. A blocked review or a declared required external dependency pauses without another implementation loop. Supplementary checks stay deferrable; the completion evidence guard stays strict.
4. On explicit resume after an external/no-progress pause, persist one reassessment grant and bind it to one review receipt. Restart recovery may only reconcile that same request; another unchanged result pauses immediately. New progress releases the no-progress stop, never the stage budget.

### Task 4: Document, validate, and review

Files: `opencode/plugins/task-workflow/README.md`, this plan's validation notes.

1. Document review progress, preserved budgets, old-task compatibility, external waiting, and one-shot reassessment.
2. Run `bun test`, `npm run check`, and `git diff --check`. Review the touched implementation and regression scenarios.
3. Report exact results and remaining limitations. Real ClickHouse and MongoDB sessions remain untouched and are not resumed automatically by this work.

## Implementation and validation results

Completed in this session. Cumulative review history and the 40-round stage limit are retained. Review progress and pause reasons are committed atomically with receipt consumption. Explicit reassessment is persisted and bound to one receipt token; automatic reload reconciles that receipt without granting another review.

- The initial regressions reproduced the legacy fourth-review rejection, the cumulative review ceiling, and repeated execution despite a declared required external condition.
- Final `bun test` in `opencode/plugins/task-workflow`: **63 pass, 0 fail, 539 expect() calls** across four test files.
- `npm run check`: passed.
- `git diff --check`: passed.
- Regression coverage includes validation-only progress, three unchanged reviews, receipt-bound reassessment across reload, unchanged external conditions, optional deferred checks reaching integration, preserved phase budgets, and user interruption.
- Checked the existing status RPC and notification integration against the OpenCode V2 plugin and RPC guides; no new API or dependency was introduced.

Progress detection remains a heuristic based on repository contents and normalized receipt check strings. It does not establish that validation ran or verify evidence claims; wording changes can still produce distinct check evidence. The cumulative stage limit remains the final bound. No real task was resumed, no service was restarted, no task state or task worktree was edited, and no changes were committed or pushed.
