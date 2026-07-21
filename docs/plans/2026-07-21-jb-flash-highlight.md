# JB Flash Highlight Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 JB 主题下为 Flash 标签、匹配和当前匹配恢复高对比颜色。

**Architecture:** 在 Flash 的 Lazy 插件规格中封装高亮应用函数，并以 `ColorScheme` 自动命令限定在 `jb` 配色方案生效。主题切换后会重新设置 Flash 专属高亮组，其他主题保持原样。

**Tech Stack:** Neovim 0.11、Lua、lazy.nvim、folke/flash.nvim、nickkadutskyi/jb.nvim。

---

### Task 1: 为 JB 注册 Flash 专属高亮

**Files:**
- Modify: `nvim/lua/plugins/goto/flash.lua`

**Step 1: 写入高亮应用函数**

新增局部函数，为 `FlashLabel`、`FlashMatch`、`FlashCurrent` 设置预期的 `fg`、`bg`（`FlashLabel` 还包括 `bold`）。

**Step 2: 注册主题切换自动命令**

在插件 `config` 中创建专用 augroup；仅匹配 `ColorScheme jb`，并调用该函数。

**Step 3: 覆盖当前已激活的 JB 主题**

若 `vim.g.colors_name == "jb"`，在 Flash 初始化后立即调用该函数。

**Step 4: 验证**

运行：

```sh
nvim --headless '+lua require("lazy").load({plugins={"flash.nvim"}}); vim.cmd("colorscheme jb"); assert(vim.api.nvim_get_hl(0,{name="FlashLabel",link=false}).bg == tonumber("ff007c", 16))' '+qa'
```

预期：命令以退出码 0 完成。
