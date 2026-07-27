# JDTLS Workspace Cleaner Design

## Goal

Provide a searchable JDTLS workspace-cache cleanup action at `<leader>lc`.

## Behavior

1. Discover directories beneath `stdpath("cache") .. "/jdtls/workspace"`.
2. Open the existing Snacks picker with one entry per workspace directory.
3. On selection, ask for explicit confirmation before deleting anything.
4. If the selected directory is the active JDTLS client's `-data` directory, stop that client, wait for it to exit, delete the directory, restart the client, and reattach its buffers.
5. Delete inactive workspace directories directly after confirmation.
6. Show a clear notification for empty caches, cancellation, deletion failures, and successful cleanup.

## Structure

Place cache discovery, JDTLS client detection, stop/restart handling, and picker setup in `lua/custom/jdtls_workspace_cleaner.lua`. Keep `lua/key-map.lua` limited to the `<leader>lc` mapping.

## Safety

Only direct child directories of the JDTLS workspace cache root are eligible. The selected path must remain inside that root before deletion. Active clients are stopped before their data directories are removed.
