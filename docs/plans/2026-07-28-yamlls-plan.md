# YAML Language Server Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install and enable `yamlls` so YAML buffers receive standard YAML language-server features.

**Architecture:** The existing `mason-lspconfig` setup owns language-server installation, while `vim.lsp.enable` starts configured clients. `yamlls` will use the shared wildcard LSP capabilities and attachment handler already defined in the LSP plugin.

**Tech Stack:** Neovim 0.12, nvim-lspconfig, mason-lspconfig, yaml-language-server.

---

### Task 1: Register and enable yamlls

**Files:**
- Modify: `nvim/lua/plugins/lsp/lsp.lua:163-185`
- Modify: `nvim/lua/plugins/lsp/lsp.lua:324-331`
- Modify: `nvim/tests/config_correctness_spec.lua:56-58`

**Step 1: Add static configuration assertions**

Add assertions that the LSP configuration includes `"yamlls",` in Mason's installation list and `vim.lsp.enable('yamlls')` in the enabled clients.

**Step 2: Run the configuration test to verify it fails**

Run: `nvim --headless -u NONE -l nvim/tests/config_correctness_spec.lua`

Expected: FAIL because `yamlls` is not yet configured.

**Step 3: Add the minimal LSP configuration**

Add `"yamlls",` to `ensure_installed`, then call `vim.lsp.enable('yamlls')` next to the other explicitly enabled filetype servers.

**Step 4: Run the configuration test**

Run: `nvim --headless -u NONE -l nvim/tests/config_correctness_spec.lua`

Expected: `config-correctness-tests: ok`.

**Step 5: Install and verify the server**

Run: `nvim --headless "+MasonInstall yaml-language-server" "+qa"`, restart Neovim, then inspect the target buffer with `vim.lsp.get_clients({ bufnr = 0 })`.

Expected: the target `bootstrap.yml` has a `yamlls` client.
