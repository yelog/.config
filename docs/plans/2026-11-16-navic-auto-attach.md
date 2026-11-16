# Navic Automatic Attachment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove duplicate navic attachment warnings while consistently preferring `vue_ls` for Vue buffers.

**Architecture:** Let nvim-navic own symbol-provider selection through its `LspAttach` handler. Preserve the existing Vue and TypeScript server collaboration, remove manual attachments from shared and Java callbacks, and load navic before either LSP setup runs.

**Tech Stack:** Neovim 0.12, Lua, lazy.nvim, nvim-navic, nvim-lspconfig, nvim-jdtls.

---

### Task 1: Configure one attachment owner

**Files:**
- Modify: `/Users/yelog/.config/nvim/lua/plugins/lsp/lsp.lua`
- Modify: `/Users/yelog/.config/nvim/lua/plugins/lsp/jdtls.lua`

1. Configure navic with:

   ```lua
   lsp = {
     auto_attach = true,
     preference = { "vue_ls", "vtsls" },
   },
   ```

2. Add `"SmiteshP/nvim-navic"` to the existing dependencies of `mason-lspconfig.nvim` and `nvim-jdtls`.
3. Remove `navic.attach(client, bufnr)` blocks and their unused `require("nvim-navic")` locals from shared and Java `on_attach` configurations.
4. Preserve the Vue TypeScript plugin, server filetypes, existing Java startup changes, and all unrelated configuration.

### Task 2: Verify attachment behavior

**Files:**
- Exercise: `/Users/yelog/.config/nvim/lua/plugins/lsp/lsp.lua`
- Exercise: `/Users/yelog/.config/nvim/lua/plugins/lsp/jdtls.lua`

1. Run an isolated headless smoke test using the installed navic implementation and the actual configuration callbacks.
2. Check both Vue attachment orders, TypeScript-only buffers, Java buffers, and clients without document-symbol support.
3. Require zero navic warnings, final selection of `vue_ls` for Vue, and normal selection of `vtsls` and `jdtls` for their own buffers.
4. Start the installed Vue and TypeScript servers against a disposable Vue example and verify symbol retrieval.

### Task 3: Run existing regression checks

Run each script in its own headless Neovim process:

```sh
nvim --headless -u NONE -i NONE -l /Users/yelog/.config/nvim/tests/lsp_topology_spec.lua
nvim --headless -u NONE -i NONE -l /Users/yelog/.config/nvim/tests/config_correctness_spec.lua
nvim --headless -u NONE -i NONE -l /Users/yelog/.config/nvim/tests/jdtls_startup_spec.lua
```

Expected: all three scripts exit successfully. Review the scoped diff and run `git diff --check` on the modified configuration files.

Execution stays in the current checkout without commits or branches. Use temporary behavioral probes rather than adding permanent tests that merely restate these small configuration edits.

## Completed verification

- The three existing regression scripts passed before and after the configuration change.
- Six behavioral probes passed with the installed navic implementation and actual shared/Java callbacks: both Vue attachment orders, TypeScript, Java, an unsupported provider alongside Vue, and a buffer without a symbol provider.
- Symbol-request counts confirmed that neither shared nor Java callbacks attach navic a second time.
- Real installed servers selected `vtsls` first, then automatically promoted the Vue buffer to `vue_ls` while retaining both clients.
- Real Vue symbol requests returned template, script setup, scoped style, variables, and functions. A TypeScript buffer retained `vtsls` and returned its exported function symbol.
- The behavioral and real-server probes emitted no warnings. Temporary fixtures were removed and test language servers were stopped.
