# Copilot Duplicate Client Design

## Goal

Prevent the Copilot LSP client from being terminated when opening personal Markdown notes while retaining Copilot completion support.

## Root Cause

`mason-lspconfig.nvim` automatically enables every installed Mason LSP unless it is excluded. The local Mason registry contains `copilot-language-server`, so it starts a native `copilot` client alongside `zbirenbaum/copilot.lua`, which starts its own bundled client. copilot.lua stops existing clients named `copilot`; the terminated Mason process reports exit code 143 after SIGTERM. The duplicate servers also contend for Copilot's SQLite-backed TF-IDF database.

## Decision

Add `copilot` to the `automatic_enable.exclude` list in `nvim/lua/plugins/lsp/lsp.lua`. Keep `jdtls` excluded as before and leave the installed Mason package intact for other configurations.

## Verification

Add a topology regression assertion for the exclusion. Run the focused and full headless Neovim specs. After restarting Neovim, inspect the Copilot client command and confirm it uses copilot.lua's bundled `copilot/js/language-server.js`, not Mason's `copilot-language-server`.
