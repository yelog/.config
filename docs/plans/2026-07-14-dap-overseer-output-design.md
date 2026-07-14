# DAP and Overseer Output Reuse Design

## Goal

Display a service's Java DAP terminal in the existing Overseer Services output pane instead of opening a new split.

## Cause

jdtls emits Java launch configurations with `console = "integratedTerminal"`. nvim-dap handles the resulting `runInTerminal` request using its default `terminal_win_cmd = "belowright new"`, which always creates another window. Meanwhile, the Services output pane remains attached to the stopped Maven task, so it no longer receives output.

## Design

Register a Java-specific `terminal_win_cmd` callback from `custom.java_debug`. The callback creates a hidden scratch buffer for nvim-dap, replaces the active service task strategy's output buffer with it, and swaps any window currently showing the old task output to the new terminal buffer. It returns the existing output window to nvim-dap when available and never creates a split.

The DAP terminal remains the task output after the session ends so logs remain inspectable. Starting the service normally invokes the existing Overseer reset path, which deletes the debug buffer and creates a regular task output buffer.

## Verification

Unit-test buffer adoption with and without a visible output window. Run existing Java debug and Overseer tests, a full Neovim startup check, and an interactive Services-panel launch against `moss-cloud` where feasible.
