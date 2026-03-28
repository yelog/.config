# Caps Lock Hyper 键：打造高效的 macOS 键盘工作流

## 前言

嘿，大家好！

我像很多人一样，每天都长时间在电脑上进行工作和学习。那就需要有一套高效的键盘工作流。

原因其实很简单：如果我们的手需要经常从键盘移到鼠标上操作，然后再回到键盘，必然会损耗非常多的时间效率，并且会打断自己的思路。

所以今天分享的是一套我使用了两三年的键盘工作流方式。

它通过将 Caps Lock 键改造成 Hyper 键，结合 Karabiner 和 Hammerspoon 这两个工具，实现以下功能：
1. 全局的光标移动
2. 窗口管理
3. 应用切换等

## 为什么改造 Caps Lock？

Caps Lock 键位于键盘黄金位置，但日常使用频率极低。将其改造为功能键，可以让双手无需离开主键区，就能完成大量操作。

## 工具介绍

- **Karabiner-Elements**：macOS 键盘改键工具，负责底层按键映射
- **Hammerspoon**：macOS 自动化工具，使用 Lua 脚本实现窗口管理和应用切换

## 核心设计：Hyper 键

Caps Lock 被映射为 **Command + Option + Shift** 组合键。这个组合在日常使用中很少单独触发，非常适合作为功能修饰键。

> 按下 Caps Lock + 其他键 = 按下 Cmd+Opt+Shift + 其他键

单独按下 Caps Lock 时，就还是 Caps Lock，用于切换输入法。

---

## 功能一：全局 Vim 风格方向键

Karabiner-Elements 配置：

| 快捷键     | 功能   |
| ---------- | ------ |
| `Caps + H` | 左箭头 |
| `Caps + J` | 下箭头 |
| `Caps + K` | 上箭头 |
| `Caps + L` | 右箭头 |

这套映射借鉴了 Vim 的方向键设计。无论在哪个应用中，都可以用右手在主键区完成光标移动，无需移到方向键区。

### 其他实用映射

| 快捷键               | 功能            |
| -------------------- | --------------- |
| `Ctrl + H`           | 退格键（删除）  |
| `Ctrl + ;`           | Esc 键          |
| `Left Shift + Caps`  | Page Down       |
| `Right Shift + Caps` | Mission Control |

---

## 功能二：窗口管理（Hammerspoon）

通过 Hammerspoon 实现了丰富的窗口管理功能，所有快捷键使用 **Hyper 键**（Shift + Option + Command）。

### 半屏与四角定位

| 快捷键      | 功能             |
| ----------- | ---------------- |
| `Hyper + A` | 左半屏           |
| `Hyper + D` | 右半屏           |
| `Hyper + W` | 上半屏           |
| `Hyper + X` | 下半屏           |
| `Hyper + Q` | 左上角（1/4 屏） |
| `Hyper + E` | 右上角（1/4 屏） |
| `Hyper + Z` | 左下角（1/4 屏） |
| `Hyper + C` | 右下角（1/4 屏） |

### 九宫格布局

数字键 1-9 对应屏幕的九宫格位置，方便快速定位窗口到任意区域：

```
┌───┬───┬───┐
│ 1 │ 2 │ 3 │
├───┼───┼───┤
│ 4 │ 5 │ 6 │
├───┼───┼───┤
│ 7 │ 8 │ 9 │
└───┴───┴───┘
```

### 其他窗口操作

| 快捷键 | 功能 |
|--------|------|
| `Hyper + S` | 居中 50% / 全屏切换 |
| `Hyper + =` | 等比例放大窗口 |
| `Hyper + -` | 等比例缩小窗口 |
| `Hyper + Return` | 移动窗口到下一屏幕 |
| `Hyper + 0` | 与上一个应用左右分屏 |

---

## 功能三：应用快速切换

不再需要 Cmd + Tab 穿越一堆应用，直接用快捷键激活目标应用：

| 快捷键 | 应用 |
|--------|------|
| `Hyper + V` | 微信 |
| `Hyper + F` | Finder |
| `Hyper + B` | Browser |
| `Hyper + I` | IntelliJ IDEA |
| `Hyper + T` | Terminal |
| `Hyper + Y` | Discord |
| `Hyper + O` | Apifox |
| `Hyper + U` | Teams |
| `Hyper + M` | Mail |
| `Hyper + ;` | ChatGPT |

特点：
- 如果应用未启动，会自动启动
- 如果应用有多个窗口，会循环切换
- 切换后自动将鼠标移到窗口内

---

## 配置结构

```
~/.config/
├── karabiner/
│   └── karabiner.json          # 主配置文件
│   └── assets/complex_modifications/
│       └── yelog.json          # 自定义规则
└── hammerspoon/
    └── init.lua                # 入口文件
    └── modules/
        ├── key-map.lua         # 快捷键配置
        ├── window.lua          # 窗口管理
        └── app.lua             # 应用切换
```

---

## 总结

这套方案的核心思想是：

1. **利用黄金键位**：改造闲置的 Caps Lock
2. **Vim 风格导航**：H/J/K/L 全局方向键
3. **一站式窗口管理**：位置、大小、多屏幕
4. **秒切应用**：无需 Cmd+Tab 翻找

双手基本不需要离开主键区，就能完成大部分日常操作。如果你也是键盘党，希望这个方案能给你一些启发。

---

## 附录：常用快捷键速查表

### 光标移动（Caps Lock 作为修饰键）

| 按键 | 功能 |
|------|------|
| `Caps + H` | 左 |
| `Caps + J` | 下 |
| `Caps + K` | 上 |
| `Caps + L` | 右 |
| `Ctrl + H` | 删除 |
| `Ctrl + ;` | Esc |

### 窗口管理（Hyper = Shift + Opt + Cmd）

| 按键 | 功能 |
|------|------|
| `Hyper + A/D/W/X` | 左/右/上/下半屏 |
| `Hyper + Q/E/Z/C` | 四角 |
| `Hyper + 1-9` | 九宫格 |
| `Hyper + S` | 居中/全屏 |
| `Hyper + =/-` | 放大/缩小 |
| `Hyper + Return` | 下一屏幕 |

### 应用切换（Hyper）

| 按键 | 应用 |
|------|------|
| `Hyper + V` | 微信 |
| `Hyper + B` | 浏览器 |
| `Hyper + T` | 终端 |
| `Hyper + F` | Finder |
| `Hyper + I` | IDEA |
