# Mini.ai XML Tag Textobject Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `cit` select only the contents of XML tags whose names contain punctuation, such as Maven property tags with `.`.

**Architecture:** Keep `mini.ai` enabled globally. Set a buffer-local XML override for its `t` text object that accepts alphanumeric and punctuation characters in tag names, using the pattern recommended by the plugin maintainer.

**Tech Stack:** Neovim Lua, mini.ai.

---

### Task 1: Configure the XML tag text object

**Files:**
- Modify: `nvim/lua/plugins/panel/mini.lua:4-19`

**Step 1: Add the XML buffer override**

Add a `FileType` autocmd after `ai.setup` which sets `vim.b[args.buf].miniai_config.custom_textobjects.t` to:

```lua
{
  "<([%p%w]-)%f[^<%w][^<>]->.-</%1>",
  "^<.->().*()</[^/]->$",
}
```

**Step 2: Verify the exact key sequence**

Run a headless Neovim buffer containing nested XML and execute `cit` on `<fastjson.version>2.0.26</fastjson.version>`.

Expected: only `2.0.26` is removed; surrounding tags and sibling properties remain unchanged.
