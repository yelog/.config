# JDTLS Workspace Cleaner Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a searchable, confirmed JDTLS workspace-cache cleaner at `<leader>lc` that safely restarts an active JDTLS client before removing its data directory.

**Architecture:** A dedicated Lua module owns cache discovery, picker presentation, confirmation, path validation, and active-client restart logic. The global keymap delegates to that module, preserving the existing `<leader>l` LSP command group.

**Tech Stack:** Neovim Lua, `vim.fs`, Neovim LSP client API, Snacks picker, nvim-jdtls.

---

### Task 1: Add focused workspace-cleaner tests

**Files:**
- Create: `nvim/tests/jdtls_workspace_cleaner_spec.lua`
- Create: `nvim/lua/custom/jdtls_workspace_cleaner.lua`

**Step 1: Write the failing tests**

Cover these pure helpers with a temporary cache root:

```lua
assert.same({ "/tmp/cache/alpha", "/tmp/cache/beta" }, cleaner.list_workspaces("/tmp/cache"))
assert.is_true(cleaner.is_workspace_path("/tmp/cache", "/tmp/cache/alpha"))
assert.is_false(cleaner.is_workspace_path("/tmp/cache", "/tmp/other"))
```

Also assert non-directories and the cache root itself are excluded.

**Step 2: Run the test to verify it fails**

Run: `nvim --headless -l nvim/tests/jdtls_workspace_cleaner_spec.lua`

Expected: FAIL because the module does not exist.

**Step 3: Implement the pure helpers**

Use `vim.fs.dir` to list only direct child directories, sort paths deterministically, and use normalized absolute paths plus a trailing separator for containment checks. Expose only the helpers required by the tests.

**Step 4: Run the focused test**

Run: `nvim --headless -l nvim/tests/jdtls_workspace_cleaner_spec.lua`

Expected: `jdtls-workspace-cleaner-spec-tests: ok`.

### Task 2: Implement active JDTLS cleanup

**Files:**
- Modify: `nvim/lua/custom/jdtls_workspace_cleaner.lua`
- Modify: `nvim/tests/jdtls_workspace_cleaner_spec.lua`

**Step 1: Write failing tests for client-data detection**

Stub `vim.lsp.get_clients` with `jdtls` and non-JDTLS clients. Verify only a JDTLS client whose `cmd` contains `-data <workspace>` is identified as active.

**Step 2: Run the test to verify it fails**

Run: `nvim --headless -l nvim/tests/jdtls_workspace_cleaner_spec.lua`

Expected: FAIL because active-client discovery is absent.

**Step 3: Implement cleanup flow**

When an active client owns the selected directory:

```lua
local attached_buffers = vim.tbl_keys(client.attached_buffers)
client:stop()
vim.wait(30000, function() return vim.lsp.get_client_by_id(client.id) == nil end)
assert(vim.fn.delete(workspace, "rf") == 0)
local client_id = vim.lsp.start(client.config)
for _, buffer in ipairs(attached_buffers) do
  vim.lsp.buf_attach_client(buffer, client_id)
end
```

Treat a stop timeout, failed deletion, or failed restart as an error notification. Delete inactive directories only after containment validation succeeds.

**Step 4: Run the focused test**

Run: `nvim --headless -l nvim/tests/jdtls_workspace_cleaner_spec.lua`

Expected: PASS.

### Task 3: Add the searchable picker and mapping

**Files:**
- Modify: `nvim/lua/custom/jdtls_workspace_cleaner.lua`
- Modify: `nvim/lua/key-map.lua:190-194`
- Modify: `nvim/tests/lsp_topology_spec.lua`

**Step 1: Write failing topology assertion**

Add an assertion that `key-map.lua` maps `<leader>lc` to `custom.jdtls_workspace_cleaner`.

**Step 2: Run the test to verify it fails**

Run: `nvim --headless -l nvim/tests/lsp_topology_spec.lua`

Expected: FAIL because the mapping is absent.

**Step 3: Implement picker and mapping**

Implement `M.pick()` with `Snacks.picker.pick` and one item per discovered workspace. On `<CR>`, call `vim.ui.select({ "Delete", "Cancel" }, ...)`; only `Delete` invokes cleanup. Use the directory basename as display text and its full path as secondary text. Notify when no directories exist.

Add:

```lua
map("n", "<leader>lc", function()
  require("custom.jdtls_workspace_cleaner").pick()
end, { desc = "Clean JDTLS workspace cache" })
```

**Step 4: Run focused tests**

Run: `nvim --headless -l nvim/tests/jdtls_workspace_cleaner_spec.lua && nvim --headless -l nvim/tests/lsp_topology_spec.lua`

Expected: both scripts print their success messages.

### Task 4: Validate the complete configuration

**Files:**
- Verify: `nvim/lua/custom/jdtls_workspace_cleaner.lua`
- Verify: `nvim/lua/key-map.lua`

**Step 1: Format Lua**

Run: `stylua nvim/lua/custom/jdtls_workspace_cleaner.lua nvim/lua/key-map.lua nvim/tests/jdtls_workspace_cleaner_spec.lua`

Expected: successful formatting.

**Step 2: Run all relevant tests and startup check**

Run: `nvim --headless -l nvim/tests/jdtls_workspace_cleaner_spec.lua && nvim --headless -l nvim/tests/lsp_topology_spec.lua && nvim --headless "+qa"`

Expected: tests pass and Neovim starts without configuration errors.

**Step 3: Manual verification**

Open a Java file, invoke `<leader>lc`, fuzzy-search a JDTLS workspace, press Enter, choose `Delete`, and verify the selected cache disappears. Repeat for the active workspace and verify its JDTLS client reconnects after deletion.
