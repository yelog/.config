# Markdown Code Block Formatting Design

## Goal

When editing Markdown, pressing `<D-s>` should format the fenced code block under the cursor.
If the cursor is not inside a fenced code block, keep the current Markdown behavior and align tables
with `Marklive.table_align()`.

## Approach

Use the current Markdown buffer to find the surrounding fenced code block. Read the fence language,
copy only the code body into a temporary buffer, set the matching filetype, run the same formatter
path used for normal source files, then replace the original code block body with the formatted text.

## Behavior

- In Markdown, `<D-s>` first checks whether the cursor is inside a fenced code block.
- Outside a code block, `<D-s>` runs `Marklive.table_align()` as it does today.
- Inside a code block, `<D-s>` formats only that code block body.
- Fence aliases such as `ts` and `js` map to `typescript` and `javascript`.
- If no language or formatter is available, the original Markdown content is left unchanged.

## Trade-Offs

This keeps the implementation local to the existing keymap and avoids adding new dependencies.
It also reuses existing LSP and formatter behavior for source filetypes. The temporary-buffer approach
is slightly more code than range formatting, but it matches normal `.ts` file behavior more closely
because TypeScript formatting runs against a TypeScript buffer instead of the Markdown buffer.

## Verification

Manual verification is appropriate for this dotfiles repo:

- Open a Markdown file with a TypeScript fenced code block.
- Put the cursor inside the block and press `<D-s>`.
- Confirm only that block is formatted.
- Put the cursor outside code blocks and press `<D-s>`.
- Confirm Markdown table alignment still runs.
