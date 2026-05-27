# Markdown Code Block Formatting Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `<D-s>` format the fenced Markdown code block under the cursor while keeping table alignment outside code blocks.

**Architecture:** Add a small Markdown-code-block formatter helper in `nvim/lua/key-map.lua`. It finds the surrounding fenced block, formats the block body in a temporary buffer with the fence language as filetype, then replaces only the block body in the original Markdown buffer.

**Tech Stack:** Neovim Lua, `vim.api`, existing LSP formatting, existing `LspEslintFixAll` command, existing `Marklive.table_align()`.

---

### Task 1: Add Markdown Fence Detection

**Files:**

- Modify: `nvim/lua/key-map.lua:66-76`

**Step 1: Add a local language alias table near the current format keymap**

Add this before the `<D-s>` mapping:

```lua
local markdown_code_block_filetypes = {
  js = "javascript",
  javascript = "javascript",
  ts = "typescript",
  typescript = "typescript",
  lua = "lua",
  python = "python",
  py = "python",
  json = "json",
  bash = "sh",
  sh = "sh",
}
```

**Step 2: Add `find_markdown_code_block()`**

Add a function that scans upward from the cursor for a line matching `^%s*```%s*([%w_-]+)` and scans downward for the closing fence `^%s*```%s*$`. Return `nil` unless the cursor is between the open and close fence.

Expected return shape:

```lua
return {
  lang = markdown_code_block_filetypes[lang] or lang,
  start_line = start_line,
  end_line = end_line,
}
```

Use 1-based line numbers from `vim.fn.line()` because the surrounding keymap already uses Vim APIs.

**Step 3: Quick syntax check**

Run: `nvim --headless -u nvim/init.lua +qa`

Expected: Neovim exits without Lua syntax errors.

### Task 2: Format Code Block in a Temporary Buffer

**Files:**

- Modify: `nvim/lua/key-map.lua:66-76`

**Step 1: Add `format_temp_buffer_sync()`**

Create a helper that:

- Creates a scratch buffer with `vim.api.nvim_create_buf(false, true)`.
- Copies code-block lines into it.
- Sets `vim.bo[temp_buf].filetype` to the detected language.
- Opens it in the current window long enough for buffer-local formatting commands to run.
- For `javascript`, `typescript`, and `vue`, tries `LspEslintFixAll` first if available.
- Calls `vim.lsp.buf.format({ async = false, timeout_ms = 3000 })`.
- Reads the formatted lines back.
- Restores the original window buffer.
- Deletes the scratch buffer.

**Step 2: Add `format_markdown_code_block()`**

Create a helper that:

- Calls `find_markdown_code_block()`.
- Returns `false` if the cursor is not inside a code block.
- Reads body lines from `start_line + 1` through `end_line - 1`.
- Calls `format_temp_buffer_sync()`.
- Replaces original body lines using `vim.api.nvim_buf_set_lines(0, start_line, end_line - 1, false, formatted_lines)`.
- Returns `true` when it handles a code block.

**Step 3: Keep fallback safe**

If the body is empty, language is empty, or formatting errors, show `vim.notify()` and return `true` so the Markdown table formatter does not run inside a code block.

**Step 4: Quick syntax check**

Run: `nvim --headless -u nvim/init.lua +qa`

Expected: Neovim exits without Lua syntax errors.

### Task 3: Wire `<D-s>` Behavior

**Files:**

- Modify: `nvim/lua/key-map.lua:66-76`

**Step 1: Update Markdown branch**

Change the existing branch from:

```lua
if vim.bo.filetype == "markdown" then
  Marklive.table_align()
```

to:

```lua
if vim.bo.filetype == "markdown" then
  if not format_markdown_code_block() then
    Marklive.table_align()
  end
```

**Step 2: Preserve non-Markdown behavior**

Keep the current logic for normal `javascript`, `typescript`, and `vue` files:

```lua
elseif my.is_include(vim.bo.filetype, eslintFileType) then
  vim.cmd("LspEslintFixAll")
else
  vim.lsp.buf.format({ async = true })
end
```

**Step 3: Quick syntax check**

Run: `nvim --headless -u nvim/init.lua +qa`

Expected: Neovim exits without Lua syntax errors.

### Task 4: Manual Verification

**Files:**

- Create temporarily if needed: `/tmp/markdown-code-block-format.md`

**Step 1: Test TypeScript block**

Open a Markdown file with this block:

```markdown
```ts
const user="Yelog";
const test=()=>{console.log("Hello "+user)}
```
```

Put the cursor inside the code block and press `<D-s>`.

Expected: Only the TypeScript code block body changes, and Markdown prose remains unchanged.

**Step 2: Test fallback outside code blocks**

Put the cursor outside any code block and press `<D-s>`.

Expected: `Marklive.table_align()` still runs.

**Step 3: Inspect final diff**

Run: `git diff -- nvim/lua/key-map.lua`

Expected: Only the keymap helper and `<D-s>` branch changed.

### Task 5: Commit Implementation

**Files:**

- Modify: `nvim/lua/key-map.lua`
- Existing unowned changes: do not stage `nvim/lua/plugins/lsp/i18n.lua` unless explicitly requested.

**Step 1: Check status and diff**

Run: `git status --porcelain`

Expected: `nvim/lua/key-map.lua` is modified. `nvim/lua/plugins/lsp/i18n.lua` may also be modified by another change and must remain unstaged.

**Step 2: Stage only implementation file**

Run: `git add nvim/lua/key-map.lua`

**Step 3: Commit**

Run: `git commit -m "feat(nvim): format markdown code blocks"`

Expected: Commit succeeds without staging unrelated files.
