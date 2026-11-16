# Java Service Memory Implementation Plan

> Execute in this session using the user's existing working trees. Preserve unrelated changes and do not commit.

**Goal:** Bound retained service logs and configure explicit local JVM budgets for moss-cloud development.

**Architecture:** Keep the existing Services renderer and launch configuration. Remove expired extmarks and disable undo only in generated log buffers. Route service stdout/stderr through the renderer using nvim-dap's output override, while preserving debugger messages and existing fallback handlers. Apply project JVM settings through `.nvim/services.json` and `.mvn/jvm.config`.

**Tech Stack:** Neovim Lua, nvim-dap, Java 21, Maven, Spring Boot.

---

### Task 1: Bound log storage — completed

Files:
- Modify `/Users/yelog/.config/nvim/lua/services/output.lua`.
- Extend `/Users/yelog/.config/nvim/tests/services_output_spec.lua`.

1. Add a regression that repeatedly exceeds a small retention limit with ANSI and semantic highlights; check retained text, highlight count and positions, clear/restart behavior, and disabled undo.
2. Run `nvim -u NONE -i NONE --headless -l /Users/yelog/.config/nvim/tests/services_output_spec.lua` and confirm the regression fails.
3. Set `vim.bo[bufnr].undolevels = -1` for ServicesLog buffers.
4. Call `vim.api.nvim_buf_clear_namespace(self.bufnr, self.namespace, 0, trimmed)` before deleting trimmed lines.
5. Rerun the regression and existing renderer tests.

### Task 2: Route debug output once — completed

Files:
- Modify `/Users/yelog/.config/nvim/lua/custom/java_debug.lua`.
- Extend `/Users/yelog/.config/nvim/tests/java_debug_spec.lua`.

1. Test stdout/stderr routing, debugger console messages, telemetry, terminal mode, unknown services, and preservation of existing output handlers.
2. Confirm the new output-handler regression fails.
3. Limit `route_output` to stdout/stderr and install `dap.defaults.java_service.on_output`.
4. Remove the service `after.event_output` listener; preserve configured fallback output behavior for events the Services renderer does not own.
5. Rerun `nvim -u NONE -i NONE --headless -l /Users/yelog/.config/nvim/tests/java_debug_spec.lua`.

### Task 3: Set local JVM budgets — completed

Files:
- Modify `/Users/yelog/workspace/lenovo/moss/moss-cloud/.nvim/services.json`.
- Create `/Users/yelog/workspace/lenovo/moss/moss-cloud/.mvn/jvm.config`.
- Add one argument in `/Users/yelog/.config/nvim/lua/plugins/lsp/jdtls.lua`, preserving existing startup changes.

1. Set service defaults to `-Xms128m -Xmx1024m -XX:+UseG1GC -XX:G1PeriodicGCInterval=60000`.
2. Override Common with `-Xms256m -Xmx2048m -XX:+UseG1GC -XX:G1PeriodicGCInterval=60000`.
3. Set local default program arguments to `--logging.level.com.lenovo.moss=INFO`, retaining existing service entries.
4. Configure Maven with `-Xms128m` and `-Xmx1024m`.
5. Append JDT LS `--jvm-arg=-Xms256m`, retaining its 4 GiB maximum heap and other options.

### Task 4: Verify integration and memory — completed

1. Run renderer, Java debug, service provider/configuration/runtime/lifecycle, and JDT LS startup tests.
2. Use the installed nvim-dap in an isolated Neovim process to verify that routed application output does not allocate a REPL buffer and console messages remain available.
3. Feed 100,000 representative colored log lines into the real renderer with a 10,000-line retention limit; record extmark counts and RSS.
4. Resolve all four actual project service configurations, check normal and debug launch arguments, and validate JVM flags without starting business services.
5. Use Maven version execution with `-XX:+PrintFlagsFinal` to verify `.mvn/jvm.config` is applied.
6. Inspect focused diffs and whitespace checks. Report restart requirements and the remaining need for an overnight business-load observation.

## Validation results

- Confirmed both regressions fail before the fix: expired highlights remained (28 instead of 20), and debugger console messages were incorrectly accepted as service output.
- Passed ten existing/extended suites: Services output, Java debug, launch configuration, providers, JDT LS startup, Services runtime, lifecycle, panel, zoom, and shutdown dialog.
- Actual renderer stress test: 10,000 / 50,000 / 100,000 input lines retained 10,000 lines and 40,000 extmarks throughout. RSS was approximately 36.4 / 37.2 / 38.4 MiB.
- Installed nvim-dap integration: 100,000 application lines retained 10,000 service lines without creating a REPL buffer. A subsequent debugger console message appeared in the REPL.
- Resolved all four real project configurations and verified normal launch commands. Ran each service's JVM flags with `java -XX:+PrintFlagsFinal -version`; all maximum heap sizes matched the intended budgets.
- Captured the generated Debug launch configurations with build and adapter execution stubbed; all four retained the intended heap flags, periodic GC option, and INFO logging argument.
- Verified Maven startup with `mvn --version` and JVM flag output: initial heap 134,217,728 bytes, maximum heap 1,073,741,824 bytes.
- Whitespace checks passed in both repositories.

## Activation and remaining observation

Restart the Neovim instances that use this configuration, then start services again. This loads the new handlers and releases retained state from old log buffers.

The project already ignores `.nvim/services.json`, so those service settings remain local. `.mvn/jvm.config` is a new uncommitted project file. No business services were started, and no overnight business-load observation was performed.
