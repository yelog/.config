# Kitty Tab-Scoped Zoom Design

## Goal

避免在非 Neovim 的 Kitty tab 触发 `⌘⌃F` 时缩放后台 tab 中的 Neovim 分屏。

## Design

`sync_zoom.sh` 从 `kitty @ ls` 中读取唯一的活动 tab，并取得其布局、窗口数量和前台 Neovim 进程 PID。活动 tab 少于两个 Kitty 窗口时脚本立即返回；否则切换 Kitty 布局，并只将 `SmartZoom` 远程命令发送到与这些 PID 对应的 Neovim server socket。

这取代原本扫描 `/tmp/nvim-*/*` 并向全部实例广播的策略。后台 tab 不再接收任何 Zoom/Unzoom 命令；活动 tab 不含 Neovim 时仅切换 Kitty 布局。

## Verification

使用 `bash -n kitty/sync_zoom.sh` 检查脚本语法；以含活动 tab、单窗口 tab、无 Neovim tab 的模拟 `kitty @ ls` JSON 验证 Python 提取逻辑的输出。
