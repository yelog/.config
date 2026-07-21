# Kitty JB 主题实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 让 Kitty 固定使用与 `jb.nvim` 深色主题一致的官方终端色板。

**Architecture:** 独立主题文件负责所有 Kitty 色彩项，主配置只负责引用它。移除会覆盖纯色背景的图片与模糊参数，确保实际窗口底色与 Neovim 的 `Normal` 背景一致。

**Tech Stack:** Kitty 配置；`jb.nvim` 内置 Kitty 主题。

---

### Task 1: 新增 JB Kitty 主题

**Files:**
- Create: `kitty/jb-theme.conf`
- Reference: `/Users/yelog/.local/share/nvim/lazy/jb.nvim/extras/kitty/jb-dark.conf`

**Step 1: 写入官方色值**

将官方文件的前景、背景、选择区、光标、边框、标签栏和 ANSI 16 色复制到新主题文件。

**Step 2: 检查关键色值**

Run: `rg -n '^(foreground|background|selection_background|cursor|color[0-9]+) ' kitty/jb-theme.conf`

Expected: 背景为 `#1e1f22`，前景为 `#bcbec3`，且定义完整的 `color0` 至 `color15`。

### Task 2: 接入主题并消除背景漂移

**Files:**
- Modify: `kitty/kitty.conf`

**Step 1: 切换主题引用**

将主题块中的 `include current-theme.conf` 替换为 `include jb-theme.conf`。

**Step 2: 移除图片渲染配置**

删除 `background_blur`、`background_image`、`background_image_layout`、`background_tint` 与 `background_image_linear`，避免覆盖 JB 纯色背景。

### Task 3: 验证 Kitty 配置

**Files:**
- Test: `kitty/kitty.conf`

**Step 1: 解析配置**

Run: `kitty --config /Users/yelog/.config/kitty/kitty.conf --debug-config`

Expected: 配置可成功加载，且输出不含 `ERROR`。

**Step 2: 与官方主题比对**

Run: `diff -u /Users/yelog/.local/share/nvim/lazy/jb.nvim/extras/kitty/jb-dark.conf /Users/yelog/.config/kitty/jb-theme.conf`

Expected: 仅允许本地说明注释或无功能差异；所有有效色值一致。
