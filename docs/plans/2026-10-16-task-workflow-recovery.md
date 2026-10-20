# Task Workflow Recovery Implementation Plan

> **For Claude:** Execute the tasks below in order in this session. The user has authorized implementation; do not create commits, restart the service, or start the DuckDB workflow.

**Goal:** Make task notifications passive and workflow rounds durable, attributable, and recoverable without repeating completed work or overriding a user stop.

**Architecture:** Keep the existing Git task directory, atomic state file, reports, and RPC UI. Persist the prompt identity and round input before admission, reconcile the durable inbox/message/event log and receipt before submitting more work, and consume receipts together with continuation state. Register recovery only for tasks enrolled in the new executor so installing this change does not start legacy tasks.

**Tech Stack:** OpenCode V2.0.30 plugin/client contracts, TypeScript, Bun tests, Git temporary repositories; existing Rust/Tokio DuckDB tests.

---

### Task 1: Align contracts and add regression scenarios

**Files:** `opencode/plugins/task-workflow/package.json`, `package-lock.json`, `workflow.test.ts`, new executor tests.

1. Pin `@opencode/plugin` to the running 2.0.30 contract and install without lifecycle scripts.
2. Cover passive synthetic notifications, queued prompt delivery with a stale interrupted outcome, lost admission responses, replay of an existing receipt, restart recovery, persisted budgets, and a user stop.
3. Cover quota versus transport/rate-limit classification and MANUAL transaction text versus explicit review requests.
4. Run targeted Bun tests and require the scenarios to fail against the old executor before implementing them where practical.

### Task 2: Implement durable round execution and recovery

**Files:** `opencode/plugins/task-workflow/index.ts`, new `execution.ts` and its tests.

1. Set `resume:false` on every synthetic notification; ordinary progress uses persisted state/RPC events.
2. Persist a stable message ID, input text, receipt token, code fingerprint, and log position before prompt admission. Reuse the identity after uncertain admission.
3. Inspect this round's durable delivery/completion events instead of the session-wide outcome; take inbox and receipt state into account and stop on explicit user interruption.
4. Save receipt consumption and continuation updates atomically; rebuild checkpoint.json from the committed state after a crash.
5. Add cleanup cancellation, a shared ownership guard, and setup/event recovery for enrolled running tasks. Do not reset budgets during resume.
6. Inject the active receipt identity into the current context so compaction cannot make an older receipt authoritative.

**Implemented recovery details:** The recovery registry is the existing task state in the repository's Git common directory, scanned at setup and every five seconds; no plugin storage registry is needed. A new task begins as pending and is enrolled by the executor before its first service request; explicit resumes persist enrollment before accessing the service. A shared controller map prevents multiple location instances from running the same task. Live execution/inbox events are saved through a serialized write queue without advancing the historical replay cursor; the subscription reconnects after failure. Read-only service clients use discovery, finite request deadlines, and rediscovery after transport failure. On services whose experimental log omits historical events, the executor pages through projected messages and matches the saved prompt ID or legacy token. Unknown interruption reasons remain paused.

### Task 3: Correct review/error policy and bound tests

**Files:** `opencode/plugins/task-workflow/progress.ts`, `index.ts`, `workflow.test.ts`, `README.md`.

1. Use explicit receipt fields to request completion review; preserve only narrowly recognized legacy human acceptance phrases.
2. After a review returns concrete required work, enter implementation without re-triggering review from prose or erasing previous review counts.
3. Treat quota as terminal until capacity changes; retry bounded transport and short-term rate-limit failures; distinguish lifecycle cancellation from user stops.
4. Require finite timeouts for automated verification and avoid immediately repeating the same hanging test.

### Task 4: Repair and verify the known DuckDB test hang

**Files:** `/Users/yelog/workspace/tui/lazydb-worktree/add-duckdb-support/src/db/duckdb.rs` only.

1. Respect the existing transaction backend's lifetime-based session lease, consistent with SQLite and the transaction worker.
2. End the backend lifetime before querying its session and wrap transaction test execution in a finite Tokio timeout.
3. Run the exact transaction test with an outer process timeout and the existing DuckDB adapter tests if the relevant binary builds successfully. Do not implement the remaining DuckDB feature work.

### Task 5: Validate and document

1. Run `npm run check`, the plugin Bun suite, and `git diff --check` in `/Users/yelog/.config`.
2. Document recovery enrollment, passive notifications, retained budgets, error handling, and test timeout behavior.
3. Review the final diff for unrelated changes and accidental task starts. Report exact validation and whether live activation has occurred; do not invoke `/task-resume` or restart the shared service.

## Completion and validation — 2026-10-16

- Plugin: `npm run check` passed; `bun test execution.test.ts recovery.test.ts workflow.test.ts` passed 47 tests with 383 assertions. Coverage includes recovery after unload, retained phase/review budgets, duplicate location ownership, passive status notifications, live-only user stops, explicit-resume authorization, replay gaps, initial service failure, and message pagination/attribution.
- DuckDB: the exact `manual_transaction_clone_commits_and_rolls_back_shared_memory_database` unit test passed (0.06 seconds in the test, 38.98 seconds including build); the existing adapter suite passed all 9 tests (0.21 seconds in tests, 32.14 seconds including build). Both commands had an external process-group timeout. `cargo +1.94.0 fmt --all -- --check` passed.
- `git diff --check` passed in both repositories. The DuckDB change only ends the test transaction object's lifetime before reuse of its session and adds a five-second scenario timeout; remaining feature work is untouched.
- A read-only reconciliation against the running 2.0.30 service recovered the legacy DuckDB prompt identity, its succeeded outcome, and the saved progress receipt with 7 required items. This used an in-memory state copy and made no task-state writes or model calls.
- Dependencies are pinned to plugin/client/theme 2.0.30. npm reports the existing OpenTUI Node engine constraint with the current Node 23; validation runs successfully with Bun 1.3.14.
- No service restart/reload, task resume, commit, merge, or push was performed. The existing DuckDB task has no executor enrollment and will not be started by installing this update. Live model end-to-end continuation and independent/remote server contexts remain unverified.
