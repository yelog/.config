# Kitty Tab-Scoped Zoom Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 Kitty/Neovim Zoom 同步限制在当前活动 Kitty tab。

**Architecture:** 脚本基于 `kitty @ ls` 识别活动 tab 的布局、窗口数量和其前台 Neovim PID。只有多窗口活动 tab 会切换布局并向匹配 PID 的 Neovim server socket 发送命令。

**Tech Stack:** Kitty remote control、Bash、Python 3、Neovim remote server。

---

### Task 1: 限定 Zoom 同步目标

**Files:**
- Modify: `kitty/sync_zoom.sh`

**Step 1: 提取活动 tab 元数据**

通过 `kitty @ ls` 的 JSON 输出取得活动 tab 的布局、窗口数量及其前台 `nvim` 进程 PID。

**Step 2: 忽略单窗口 tab**

当窗口数小于 2 时直接退出，避免无视觉效果的布局切换和远程命令。

**Step 3: 仅发送到匹配服务**

在 `/tmp/nvim-*` 中仅选择 basename 等于活动 tab Neovim PID 的 socket；不再遍历并操作全部 Neovim 实例。

**Step 4: 验证**

运行：

```sh
bash -n kitty/sync_zoom.sh
```

预期：命令以退出码 0 完成。
