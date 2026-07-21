# Kitty JB 主题设计

## 目标

让 Kitty 固定使用与当前 `jb.nvim` 深色主题相同的终端配色，消除其与 Neovim 之间的 Tokyo Night 色调差异。

## 方案

- 新增 `kitty/jb-theme.conf`，以当前安装的 `jb.nvim` 提供的官方 Kitty 深色主题为唯一色值来源。
- 将 `kitty/kitty.conf` 的主题引用从 `current-theme.conf` 切换为 `jb-theme.conf`。
- 删除背景图片、模糊和 tint 设置，使 Kitty 的实际背景保持为 JB 的 `#1e1f22`；否则视觉背景会偏离 Neovim，即使 ANSI 色板相同。

## 验证

- 用 `kitty --config ... --debug-config` 解析配置，确认没有无效项或引用错误。
- 比对主题中的前景、背景、选择区、光标、标签栏及 ANSI 16 色是否与 `jb.nvim` 官方 Kitty 文件一致。
