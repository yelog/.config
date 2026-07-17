# Copilot Duplicate Client Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure each Neovim instance uses only copilot.lua's Copilot client, including when opening personal Markdown notes.

**Architecture:** Keep Mason automatic enablement for normal installed LSP servers, but exclude `copilot` alongside the existing `jdtls` exception. copilot.lua remains the sole owner of Copilot's LSP lifecycle and continues to provide the Blink completion source.

**Tech Stack:** Neovim Lua, mason-lspconfig.nvim, copilot.lua, headless Neovim specs.

---

### Task 1: Add a regression assertion for the Copilot lifecycle boundary

**Files:**
- Modify: `nvim/tests/lsp_topology_spec.lua:8-36`

**Step 1: Write the failing test**

Add an assertion after the existing LSP topology checks:

```lua
assert(lsp:find('exclude = { "jdtls", "copilot" }', 1, true),
  "Mason must not auto-enable a second Copilot LSP client")
```

**Step 2: Run the test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/lsp_topology_spec.lua" "+qa!"
```

Expected: FAIL because only `jdtls` is currently excluded.

### Task 2: Exclude the native Mason Copilot server

**Files:**
- Modify: `nvim/lua/plugins/lsp/lsp.lua:179-183`

**Step 1: Write the minimal implementation**

Update the existing `automatic_enable` exclusion list:

```lua
automatic_enable = {
  exclude = { "jdtls", "copilot" },
},
```

This prevents Mason from running its installed `copilot-language-server`. `zbirenbaum/copilot.lua` continues to launch its own bundled server, avoiding duplicate lifecycle ownership and SQLite contention.

**Step 2: Run the focused regression test**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/lsp_topology_spec.lua" "+qa!"
```

Expected: `lsp-topology-tests: ok`.

**Step 3: Run the full Neovim spec suite**

Run:

```bash
for test in /Users/yelog/.config/nvim/tests/*_spec.lua; do nvim --headless -u NONE "+luafile ${test}" "+qa!" || exit 1; done
```

Expected: every spec exits successfully.

**Step 4: Verify after restarting Neovim**

Restart existing Neovim instances to remove already-running duplicate clients, then run:

```vim
:lua for _, client in ipairs(vim.lsp.get_clients({ name = "copilot" })) do print(vim.inspect(client.config.cmd)) end
```

Expected: the command references `lazy/copilot.lua/copilot/js/language-server.js` and does not reference `mason/bin/copilot-language-server`.

**Step 5: Commit only if requested**

Do not create a commit unless the user explicitly requests one. If requested, stage only the LSP configuration, topology spec, and related design/plan documents.
