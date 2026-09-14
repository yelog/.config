# OpenCode 2 Plugin Migration Implementation Plan

> Execute this plan task-by-task in the current session.

**Goal:** Make the normal `opencode2` command start with an isolated V2 configuration and working notifications and VibeBar integration.

**Architecture:** Keep legacy plugins in the V1 global configuration directory. The V2 launcher selects a separate config and service-state directory while retaining existing credentials and session data. VibeBar shares its existing broker runtime between a V1 `server` entrypoint and a V2 `setup` entrypoint, translating the actual V2 event and interaction APIs.

**Tech Stack:** Zsh, OpenCode 1.18.30 / 0.0.0-beta-19059, JavaScript ES modules, Node.js tests, local Unix sockets.

---

### Task 1: Repair the launcher and select the V2 profile

**Files:**
- Modify `opencode/opencode2`.
- Modify `zsh/zshrc`.
- Modify `opencode-v2/opencode.json` and `opencode-v2/cli.json`.
- Move `~/.opencode/plugin/notification.js` to `opencode/plugins/notification.js`.
- Pin the installed OMO version in `opencode/tui.json`.

1. Set `OPENCODE_CONFIG_DIR` to `~/.config/opencode-v2` and `XDG_STATE_HOME` to `~/.local/state/opencode-v2` inside the launcher.
2. Invoke the absolute installed binary to avoid wrapper recursion.
3. Add `--standalone` only to the TUI, run, mini, and API commands. Preserve explicit server selection and normal management-command arguments.
4. Route the interactive Zsh command through this launcher.
5. Move the legacy notification out of the home-level discovery directory.
6. Configure V2 CLI plugins as an empty list and enable built-in attention notifications; initially leave V2 server plugins empty until the port passes tests.
7. Set the V2 global lazydb entry to `disabled: true`, documenting project-level enablement.
8. Check syntax with `zsh -n opencode/opencode2 zsh/zshrc`, command resolution with `zsh -ic 'whence -v opencode2'`, and paths with `opencode/opencode2 debug paths`.

### Task 2: Port VibeBar and verify its lifecycle

**Repository:** `~/workspace/swift/VibeBar`

**Files:**
- Modify `plugins/opencode-vibebar-plugin/index.js`.
- Add the V2 adapter and its Node.js tests beside the existing runtime.
- Extend `plugins/opencode-vibebar-plugin/index.test.js` for cleanup regression coverage.

1. Confirm APIs against the installed Beta's OpenAPI document and a disposable plugin-context probe.
2. Cover state transitions, location/session isolation, permission replies, form replies/cancellation, and unload cleanup with meaningful tests.
3. Reuse the existing VibeBar broker and pending-interaction machinery. Prevent any V2 reply from falling back to a V1 HTTP route.
4. Track and cancel heartbeat/retry timers, pending sockets, and subscriptions on unload. Ignore late interaction responses after disposal.
5. Export an object with a stable ID, V1 `server`, and V2 `setup`; no empty compatibility shim.
6. Run `node --test plugins/opencode-vibebar-plugin/*.test.js`.
7. Verify the installed Beta loads the plugin and emits events through a temporary local broker without a model request.
8. Restore the VibeBar entry in the V2 configuration after the checks pass.

### Task 3: Verify the integrated profiles and document operation

**Files:**
- Add `opencode-v2/README.md`.

1. Validate the V2 CLI configuration against the published schema and load the server configuration with the installed binary.
2. Print only config source paths and plugin/MCP status; never print resolved provider settings.
3. Start and exit an isolated TUI to verify plugin activation and absence of startup failures.
4. Check that V1 continues to discover the legacy notification and accepts the VibeBar V1 entrypoint.
5. Document the launcher, profile locations, project-only lazydb enablement, upstream-dependent plugins, restart requirements, and rollback steps.
6. Review diffs in both repositories and preserve the pre-existing `hammerspoon/config/apps.lua` change.

## References

- https://opencode.ai/v2/docs/build/plugins/migrate-v1
- https://opencode.ai/v2/docs/build/plugins
- https://opencode.ai/v2/docs/cli/config
- https://opencode.ai/v2/docs/plugins/
- https://github.com/code-yeongyu/oh-my-openagent/issues/7847
