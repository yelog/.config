# DAP Breakpoint Persistence Design

## Goal

Persist nvim-dap breakpoints independently of editor sessions and restore them
lazily when their source buffers are read.

## Storage

Each normalized project root owns one JSON file under
`stdpath("data")/dap-breakpoints/`. The filename is the SHA256 hash of the root,
so projects with identical directory names cannot collide.

The versioned document stores the normalized root and a map keyed by
project-relative source paths. Each breakpoint stores its line, condition, hit
condition, and log message. Adapter response state such as verification and
adapter IDs is intentionally excluded.

## Runtime Model

`custom.dap_breakpoints` maintains an in-memory catalog for every root it has
read. Updating one loaded buffer replaces only that file's entry in the
catalog, preserving persisted breakpoints for unopened files.

The `<leader>db` mapping toggles the nvim-dap breakpoint first and schedules an
atomic catalog write. `VimLeavePre` synchronizes all loaded buffers before a
final write.

On `BufReadPost`, the module loads the current project's catalog and restores
only the current file through `dap.breakpoints.set(opts, bufnr, line)`. Existing
breakpoints are compared before restoration to make the operation idempotent.
No window is switched and unrelated source files are not loaded.

## Project Roots

Roots are detected from `.git`, Maven, Gradle, and npm project markers. Paths
are normalized through `uv.fs_realpath` when possible. A source file outside a
recognized project uses its parent directory as the root.

## Failure Handling

Writes use a temporary file followed by rename. A missing persistence file is
normal. Invalid JSON, unsupported schema versions, or failed writes produce a
warning without preventing Neovim startup or breakpoint use.

## Tests

Headless tests use temporary projects and a stubbed `dap.breakpoints` module.
They cover project isolation, advanced breakpoint fields, lazy idempotent
restore, preservation of unopened files, deletion of a file's last breakpoint,
malformed JSON, and setup autocmd registration.

## Non-goals

- Relocating breakpoints based on source text after lines move.
- Persisting adapter verification state.
- Coupling breakpoint lifetime to Resession sessions.
- Loading all breakpoint files during startup.
