# Claude Code Task Workflow

This directory contains the portable workflow core and Claude Code Mod for a
resumable `/task` workflow. It is installed as a user-level local plugin by
`CLAUDE_CODE_PLUGIN_DIRS` in `~/.claude/settings.json`; remove that setting to
disable automatic loading.

The core is a dependency-free Node CLI. It owns durable state, task locks,
Git/worktree checks, receipts, validation evidence, and resumable integration.
The Claude Code Mod in `adapters/claude` calls the compiled CLI through
`$.process.run`; it does not import Node APIs or mutate Git directly.

## Development

```sh
npm run check
npm run build
npm test
npm run validate:claude
npm run test:claude
```

Build the core before launching Claude. The adapter
resolves the executable from `TASK_WORKFLOW_CORE` when set, otherwise from the
package root's `dist/` path. The nested `adapters/claude` directory is kept as
the implementation and test source; the package root is the installable plugin.

For a one-session trial without the user setting, use
`claude --plugin-dir /Users/yelog/.config/task-workflow`.

To test only the nested development fixture, run `claude plugin validate
adapters/claude --strict`; the supported installation target is the package
root.

Core tests use `tests/*_test_.ts` so Claude Code's plugin test runner does not
collect them. Claude Mod tests use `adapters/claude/tests/*.test.ts` and are
run by `npm run test:claude`.

The Claude adapter accepts `sonnet`, `opus`, `haiku`, `inherit`, or a
`claude-*` model id. OpenCode-specific provider/model names are rejected by the
adapter instead of being silently sent to Claude Code. `/task-cleanup` only
reports by default; `/task-cleanup apply` is the explicit maintenance form.

Tasks are stored below the repository's Git common directory:

```text
<git-common-dir>/task-workflow/
  bindings.json
  tasks/<task-id>/
```

The existing OpenCode records under `opencode-tasks/` are not read or modified.

## Use the Claude adapter

Start Claude from a named Git branch in the target checkout:

```sh
cd /path/to/repository
npm --prefix /Users/yelog/.config/task-workflow run build
claude --plugin-dir /Users/yelog/.config/task-workflow
```

Then use:

```text
/task <requirement>
/task-status
/task-resume
/task-cleanup
/task-cleanup apply
```

`/task-cleanup` is read-only by default. `apply` removes only residual worktrees
and branches whose reviewed commit is already merged, whose branch tip still
matches that commit, and whose worktree identity and cleanliness checks pass.
It never uses force deletion.

The default phases are analyze, plan, implement, integrate, and cleanup.
Analyze and plan use the `planner` model; implementation, review, and
integration use `executor`. The canonical configuration uses the `magpie`
provider with `codex/gpt-6.1-sol` and `codex/gpt-6-luna`; the Claude adapter
maps them to `group/auto-gpt-6-1-sol` and `group/auto-gpt-6-luna` at runtime.
Configure a project in `.task-workflow.json` if needed:

```json
{
  "models": {
    "planner": { "provider": "magpie", "model": "codex/gpt-6.1-sol" },
    "executor": { "provider": "magpie", "model": "codex/gpt-6-luna" }
  },
  "modelPolicy": "pinned",
  "planDirectory": "docs/plans",
  "maxRunRounds": 40,
  "maxTotalRounds": 160,
  "validations": [
    { "id": "tests", "command": ["npm", "test"], "required": true }
  ]
}
```

The core creates task worktrees below `.claude/worktrees/<name>` by default,
records state below Git's common directory, and requires the Claude session to
enter the recorded worktree before implementation. Integration requires the
session to exit it first. The core handles commit, merge, target validation,
and cleanup only after the corresponding task authorization and checks pass.

## Rollback and current limits

Stop using the adapter by ending the Claude session and omitting
`--plugin-dir`. No global settings or existing OpenCode task records are
modified by this package. In-progress Claude task records and worktrees remain
on disk for `/task-resume` or explicit maintenance handling.

The automated tests use simulated model turns. The real Claude host has been
verified with a read-only `/task-status` probe; a full model-driven task still
needs a user-approved trial in a disposable repository. Existing pinned task
snapshots using the former xrouter IDs remain resumable and are mapped to the
equivalent magpie runtime aliases without rewriting their state files.
