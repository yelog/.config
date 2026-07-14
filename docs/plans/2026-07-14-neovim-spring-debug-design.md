# Neovim Spring Cloud Debug Design

## Goal

Make Maven multi-module Spring Cloud services debuggable from the existing Overseer Services panel, while preserving the selected profile and allowing project-local launch overrides.

## Root Causes

- `java-debug-adapter` is not installed, so jdtls never loads `com.microsoft.java.debug.plugin` and cannot expose `vscode.java.startDebugSession`.
- The Spring task template writes the entry point to `metadata.class`, but the Overseer debug action reads `metadata.main_class`.
- The action calls asynchronous main-class discovery and starts DAP after a fixed 100 ms delay, creating a race.
- Java debug and test bundles are not included in `init_options.bundles`; only Spring Boot extensions are loaded.
- The panel does not reflect or stop a DAP-owned process.

## Architecture

Use `mason-tool-installer.nvim` to provision `java-debug-adapter` and `java-test`. A new `custom.java_debug` module discovers their jars, merges them with Spring Boot extensions, resolves project-local debug settings, fetches launch configurations from jdtls, matches the service by fully qualified main class, and starts DAP only from the asynchronous callback.

The Spring template exposes consistent `main_class`, `module_root`, and `source` metadata. The Services panel delegates launch behavior to the new module, waits for a normally running Overseer task to stop, and mirrors DAP lifecycle state on the selected service row.

## Project Configuration

An optional `.nvim/java-debug.json` file at the repository root supports defaults and per-service overrides:

```json
{
  "defaults": {
    "vmArgs": "-Xms512m -Xmx2g",
    "env": {
      "NACOS_ADDR": "127.0.0.1:8848"
    }
  },
  "services": {
    "com.example.order.OrderApplication": {
      "args": "--server.port=8082"
    }
  }
}
```

The profile selected with `p` in the Services panel is appended as `-Dspring.profiles.active=<profile>`. Explicit project `vmArgs`, `args`, `env`, and `cwd` values override generated launch values; defaults are merged before service-specific values.

## User Flow

1. Open a Java file in the Maven multi-module repository and wait for jdtls import to finish.
2. Open Services with `<leader>oo`.
3. Select a Maven profile with `p` when needed.
4. Put the cursor on a service and press `<leader>d`.
5. The normal service process is stopped if necessary, jdtls resolves the exact launch configuration, and DAP starts it with breakpoints enabled.
6. Press `S` on the debugging service or `<leader>dt` globally to terminate it.

## Error Handling

Report actionable errors for missing Mason bundles, unavailable jdtls Java debug capability, invalid project JSON, missing main-class configuration, and ambiguous main-class matches. Do not use timing delays to sequence asynchronous APIs.

## Verification

Add headless Lua tests for bundle discovery, configuration merging, profile injection, and main-class matching. Extend the Overseer service tests for consistent metadata and run a full headless config load check.
