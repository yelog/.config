# Neovim Spring Cloud Debug Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Launch Maven multi-module Spring Boot services under Java DAP directly from the Overseer Services panel.

**Architecture:** Provision Java debug tooling through Mason, inject its bundles into jdtls, and centralize launch/configuration logic in `custom.java_debug`. Overseer remains the service selector and status UI while nvim-dap owns debug processes.

**Tech Stack:** Neovim 0.11, Lua, nvim-jdtls, nvim-dap, Overseer.nvim, Mason, mason-tool-installer.nvim

---

### Task 1: Add Java debug configuration tests

**Files:**
- Create: `nvim/tests/java_debug_spec.lua`

**Steps:**
1. Write tests for Mason bundle collection and Java Test jar exclusions.
2. Write tests for defaults/service override merging and selected profile injection.
3. Write tests for exact fully qualified main-class matching.
4. Run `nvim --headless -u NONE -l nvim/tests/java_debug_spec.lua` and verify it fails because `custom.java_debug` does not exist.

### Task 2: Implement the Java debug module

**Files:**
- Create: `nvim/lua/custom/java_debug.lua`

**Steps:**
1. Implement deterministic bundle discovery under Mason.
2. Implement `.nvim/java-debug.json` loading and validated merge behavior.
3. Implement jdtls config discovery with `on_ready`, exact FQN matching, and `dap.run`.
4. Implement DAP-to-service lifecycle tracking and termination helpers.
5. Run the focused headless test and verify it passes.

### Task 3: Provision tools and configure jdtls

**Files:**
- Modify: `nvim/lua/plugins/lsp/lsp.lua`
- Modify: `nvim/lua/plugins/lsp/jdtls.lua`

**Steps:**
1. Add `mason-tool-installer.nvim` with `java-debug-adapter` and `java-test` in `ensure_installed`.
2. Merge `custom.java_debug.bundles()` with `spring_boot.java_extensions()` in jdtls initialization options.
3. Remove premature DAP setup and make `<leader>jd` refresh configurations through the supported asynchronous API.
4. Run a headless config load check.

### Task 4: Integrate the Services panel

**Files:**
- Modify: `nvim/lua/overseer/template/springboot.lua`
- Modify: `nvim/lua/plugins/panel/overseer.lua`
- Modify: `nvim/tests/overseer_services_spec.lua`

**Steps:**
1. Rename task metadata to `main_class` and add module metadata needed by launch resolution.
2. Replace the fixed-delay action with `custom.java_debug.start(task)`.
3. Wait for `on_complete` when replacing a running Overseer process.
4. Render a distinct debugging state and make stop/start actions handle DAP ownership.
5. Extend and run Overseer tests.

### Task 5: Verify and document operation

**Files:**
- Modify: `nvim/README.md`

**Steps:**
1. Install ensured Mason tools with `:MasonToolsInstall` or the equivalent headless command.
2. Verify Java debug and test jars exist.
3. Run all Neovim headless tests and startup checks.
4. Document prerequisites, optional `.nvim/java-debug.json`, Services panel keys, breakpoint workflow, and troubleshooting commands.
