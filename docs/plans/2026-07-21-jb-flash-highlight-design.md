# JB Flash Highlight Design

## Goal

在 `jb` 配色方案下为 `flash.nvim` 使用固定的高对比标签、匹配和当前匹配颜色，同时不改变其他主题的 Flash 外观。

## Design

在 Flash 插件规格中定义一个只设置 Flash 专属高亮组的函数。该函数通过 `ColorScheme` 自动命令仅在 `jb` 被激活时调用。由于主题切换会重置高亮，自动命令负责每次切换回 `jb` 后恢复这些颜色。

使用 Flash 的 VS Code 集成默认配色：`FlashLabel` 为 `#ff007c`，`FlashMatch` 为 `#3e68d7`，`FlashCurrent` 为 `#ff966c`。不改动 `jb.nvim`、`flash.nvim` 或 `Search`、`Substitute` 等通用主题组。

## Verification

以无界面 Neovim 加载 Flash，切换到 `jb`，并断言三个 Flash 专属高亮组的前景色和背景色均为期望值。
