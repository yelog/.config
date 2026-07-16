# Neo-tree Restoration Design

## Goal

Restore the last active Neo-tree configuration from repository history and return `<leader>te` to a left-sidebar Neo-tree toggle.

## Historical Source

The final active configuration is `7957d97^:nvim/lua/plugins/panel/neo-tree.lua`. Commit `7957d97` disabled it on 2025-06-03, and `73f27ed` deleted the disabled file on 2026-07-14. The historical keymap used `:Neotree left toggle` for `<leader>te` before Yazi claimed that mapping.

## Design

Restore the complete historical Neo-tree setup: a left sidebar with width 40, Git and diagnostics state, custom icons and status symbols, file-following, hidden/gitignored filtering, buffer and Git-status sources, and the existing image-preview and Avante file-selection commands.

Use the current valid NUI dependency name, `MunifTanjim/nui.nvim`, in place of the misspelled historical dependency. Keep `<C-e>` assigned to Yazi. Change only `<leader>te` to the historical `:Neotree left toggle` command, preserving the existing Smart Quit handling for Neo-tree buffers.

## Verification

- A focused headless spec captures `require("neo-tree").setup` and verifies the restored plugin dependencies, left sidebar, width, file-following, and filtering configuration.
- A full configuration load confirms the `:Neotree` command is available.
- The normal-mode `<leader>te` mapping resolves to `:Neotree left toggle`.
