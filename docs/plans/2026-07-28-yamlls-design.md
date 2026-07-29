# YAML Language Server Design

## Goal

Attach `yamlls` to YAML buffers so Neovim provides YAML diagnostics, formatting, and schema-backed completion where available.

## Approach

Add `yamlls` to the existing `mason-lspconfig` `ensure_installed` list and explicitly enable it alongside the other configured language servers. It inherits the shared capabilities and `on_attach` handler through the wildcard LSP configuration.

## Scope

No YAML schemas, Spring-specific language server, or `gd` mapping changes are included. Standard `yamlls` does not resolve Spring `${...}` property references.

## Verification

Start Neovim with the target `bootstrap.yml` after Mason installs the package and confirm that `yamlls` appears in `vim.lsp.get_clients({ bufnr = 0 })`.
