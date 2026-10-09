# Neovim Plugin Optimization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce duplicate Neovim UI/textobject behavior and add optional, discoverable diagnostics and DAP views without replacing the user's existing workflow.

**Architecture:** Keep Snacks as the shared notifier and indent-guide provider, Noice for command-line/popupmenu/LSP UI, and Mini.ai as the single owner of function/class textobject mappings. Preserve the existing custom search, picker, file tree, Java debug orchestration, and AI providers; add Trouble and nvim-dap-view as lazy, explicitly invoked panels.

**Tech Stack:** Neovim 0.12, lazy.nvim, Snacks.nvim, Noice.nvim, mini.nvim, nvim-treesitter-textobjects, Trouble.nvim, nvim-dap, nvim-dap-view.

---

### Task 1: Add config regression checks

**Files:**
- Modify: `tests/config_correctness_spec.lua`
- Test: `tests/config_correctness_spec.lua`

**Step 1: Add assertions for desired ownership and mappings**

Check that Snacks owns notifications/indent guides, Noice does not override notifications, hlchunk retains chunk but not indent guides, cursorword has one configured owner, Mini.ai owns function/class mappings, and Trouble/DAP View have non-conflicting keymaps.

**Step 2: Run the test before implementation**

Run: `nvim --headless -u NONE -i NONE -n -l tests/config_correctness_spec.lua`
Expected: FAIL on the first new assertion because the current config still has overlapping integrations.

### Task 2: Consolidate UI and textobject ownership

**Files:**
- Modify: `lua/plugins/panel/snacks.lua`
- Modify: `lua/plugins/style/noice.lua`
- Modify: `lua/plugins/style/indent-blankline.lua`
- Delete: `lua/plugins/style/cursorword.lua`
- Modify: `lua/plugins/panel/mini.lua`
- Modify: `lua/plugins/lsp/treesitter.lua`

**Step 1: Set UI ownership**

Keep Snacks as the `vim.notify` owner and route Noice messages, LSP messages, and LSP progress through Noice's transient mini view. Retain Noice's command-line, popupmenu, and LSP documentation UI. Keep hlchunk's chunk visualization but disable its duplicate indent guides.

**Step 2: Unify textobject mappings**

Configure Mini.ai Tree-sitter objects for `aF/iF` (function definitions) and `aC/iC` (classes), preserving Mini.ai's built-in `af/if` function-call objects. Keep the Markdown code fence object on `c` as a Markdown-only buffer-local object, and remove Tree-sitter's competing function/class mappings while retaining `as` local-scope selection.

**Step 3: Run the regression test**

Run: `nvim --headless -u NONE -i NONE -n -l tests/config_correctness_spec.lua`
Expected: PASS for all ownership and keymap assertions.

### Task 3: Add optional diagnostics and debugger panels

**Files:**
- Create: `lua/plugins/panel/trouble.lua`
- Create: `lua/plugins/panel/dap-view.lua`
- Modify: `tests/config_correctness_spec.lua`

**Step 1: Add lazy-loaded Trouble mappings**

Use `<leader>xx` for workspace diagnostics and `<leader>xX` for current-buffer diagnostics. Keep the existing task mappings unchanged.

**Step 2: Add lazy-loaded nvim-dap-view**

Depend on the existing nvim-dap instance and map `<leader>du` to `DapViewToggle`. Do not auto-open the panel, preserving the existing Java debug lifecycle.

**Step 3: Run focused and full config tests**

Run: `nvim --headless -u NONE -i NONE -n -l tests/config_correctness_spec.lua`
Run: `for test in tests/*_spec.lua; do nvim --headless -u NONE -i NONE -n -l "$test" || exit 1; done`
Expected: all specs pass.

### Task 4: Verify plugin specs and review changes

**Files:**
- Verify: `lua/plugins/**/*.lua`
- Verify: `lazy-lock.json`

**Step 1: Check lazy.nvim specs**

Run Neovim headlessly with the config and inspect `:Lazy`/plugin loading errors; confirm the new plugins are resolvable and lazily loaded.

**Step 2: Review the diff**

Run: `git diff --check` and `git diff -- nvim`
Expected: no whitespace errors, unrelated files untouched, and no modifications to custom Java debugging behavior.
