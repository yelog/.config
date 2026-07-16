# Neovim Toolchain Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the Neovim configuration reliable for Java, Vue/TypeScript, Rust, and Lua by fixing key conflicts, adding project-aware test tasks, standardizing manual formatting and diagnostics, and correcting Java/Vue language-server topology.

**Architecture:** Preserve the existing Overseer, Services, JDTLS, Snacks, and Blink architecture. Add small testable custom modules for task command selection, formatting dispatch, and Java runtime discovery; keep long-running Services separate from finite Overseer tasks and keep formatting manual-only.

**Tech Stack:** Neovim 0.11, Lua, lazy.nvim, Overseer, Conform, Mason, nvim-jdtls, vue-language-server, vtsls, native headless Neovim tests.

---

### Task 1: Fix Configuration and Keymap Conflicts

**Files:**
- Create: `nvim/tests/config_correctness_spec.lua`
- Modify: `nvim/lua/key-map.lua`
- Modify: `nvim/lua/plugins/style/markdown.lua`
- Modify: `nvim/lua/plugins/complete/copilot.lua`
- Modify: `nvim/lua/plugins/lsp/lsp.lua`
- Modify: `nvim/lua/plugins/panel/snacks.lua`
- Modify: `nvim/base.vim`

**Steps:**
1. Write a failing headless source-level regression test for the invalid Autosession command, global Markdown Enter mapping, eager Avante require, Copilot suggestion conflict, buffer scope of LSP mappings, duplicate CodeLens autocmd, and conflicting Scratch/Wrap mappings.
2. Run `nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/config_correctness_spec.lua" "+qa!"` and verify failure.
3. Remove the stale Autosession mapping and let Resession own `<leader>sd`.
4. Move `<CR>` task toggling into a Markdown/Avante buffer-local mapping in the Marklive plugin configuration.
5. Require `avante.api` only inside the visual mapping callback.
6. Disable Copilot's independent inline suggestion and remove the unused NES dependency and native Copilot LSP registration; Blink remains the sole completion UI.
7. Give the generic LSP `<C-k>` mapping `buffer = bufnr` and use an augroup plus `clear = true` for per-buffer CodeLens refresh autocmds.
8. Move Scratch selection to `<leader>bS`, remove the obsolete Vimscript wrap mapping in favor of Snacks `<leader>uw`, and add the `<leader>x` Tasks group.
9. Run the focused test and then all existing specs.

### Task 2: Add Project-Aware Overseer Test Tasks

**Files:**
- Create: `nvim/lua/custom/task_runner.lua`
- Create: `nvim/tests/task_runner_spec.lua`
- Modify: `nvim/lua/plugins/panel/overseer.lua`
- Modify: `nvim/lua/key-map.lua`

**Steps:**
1. Write failing unit tests for root detection and Java Maven/Gradle, Vue Vitest/package-manager, Rust Cargo, and Lua headless/Busted command construction.
2. Run the focused test and verify failure because `custom.task_runner` does not exist.
3. Implement pure command selection functions returning Overseer-compatible task definitions.
4. Implement run-nearest, run-file/class, run-all, rerun, and open-output entry points.
5. Configure Overseer output/quickfix components and register `<leader>xn`, `<leader>xf`, `<leader>xa`, `<leader>xr`, and `<leader>xo`.
6. Run the focused test and all existing specs.

### Task 3: Add Manual Formatting and Unified Diagnostics

**Files:**
- Create: `nvim/lua/custom/format.lua`
- Create: `nvim/tests/format_spec.lua`
- Create: `nvim/lua/plugins/lsp/conform.lua`
- Modify: `nvim/lua/key-map.lua`
- Modify: `nvim/lua/plugins/lsp/lsp.lua`
- Modify: `nvim/lua/plugins/panel/snacks.lua`

**Steps:**
1. Query current Conform documentation before using its API.
2. Write failing tests for formatter selection and manual-only behavior.
3. Implement project-local Prettier for Vue/TypeScript/JavaScript/Markdown, rustfmt for Rust, Stylua for Lua, and LSP fallback for Java.
4. Move `<D-s>` and `<leader>ll` through the formatter module while preserving fenced Markdown block handling.
5. Enable WARN/ERROR signs, ERROR-only virtual text, underlines, severity sorting, and diagnostics pickers for the current buffer and workspace.
6. Add Stylua and Prettier to Mason tool installation without adding nvim-lint or format-on-save.
7. Run the focused test and all existing specs.

### Task 4: Correct Java and Vue Language Toolchains

**Files:**
- Create: `nvim/lua/custom/java_runtime.lua`
- Create: `nvim/tests/java_runtime_spec.lua`
- Create: `nvim/tests/lsp_topology_spec.lua`
- Modify: `nvim/lua/plugins/lsp/jdtls.lua`
- Modify: `nvim/lua/plugins/lsp/lsp.lua`
- Modify: `nvim/lua/plugins/lsp/treesitter.lua`

**Steps:**
1. Write failing tests for Java home validation, `JavaSE-1.8`, exactly one default runtime, launcher selection, portable Mason paths, and Vue hybrid-mode ownership.
2. Implement Java runtime discovery from `JAVA_HOME_8`, `JAVA_HOME_11`, `JAVA_HOME_17`, `JAVA_HOME_21`, and `JAVA_HOME`, validating each `bin/java` and preferring Java 21 for the JDTLS launcher.
3. Set JDTLS `cmd_env.JAVA_HOME`, correct runtime names, and ensure only the launcher runtime is default.
4. Add Spring Boot language-server tools to Mason installation.
5. Refactor ordinary servers onto shared capabilities/on_attach, use `stdpath("data")` for the Vue TypeScript plugin, keep `vue_ls` on Vue files in hybrid mode, and let vtsls provide TypeScript support including Vue.
6. Add Rust and TOML Treesitter parsers and re-enable rust-analyzer diagnostics.
7. Run focused tests, all specs, `git diff --check`, and a full config startup smoke test.

### Final Verification

Run every spec independently:

```bash
for test in /Users/yelog/.config/nvim/tests/*_spec.lua; do
  nvim --headless -u NONE "+luafile ${test}" "+qa!" || exit 1
done
```

Run startup smoke test:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua "+lua vim.defer_fn(function() vim.cmd('qa!') end, 1000)"
```

Expected: all specs print their success marker, startup exits successfully, and `git diff --check` reports no whitespace errors. Do not commit unless explicitly requested.
