# .config — yelog 的 dotfiles

macOS 开发环境配置仓库，通过 git + 子模块管理 `~/.config` 下 40+ 个工具的配置。

## 快速开始

```bash
git clone --recursive https://github.com/yelog/.config.git ~/.config
~/.config/init.sh
```

`init.sh` 在 macOS 上建立符号链接并安装依赖：

- `~/.ideavimrc` → `~/.config/ideavimrc`
- `~/.hammerspoon` → `~/.config/hammerspoon`
- `~/.zshrc` → `~/.config/zsh/zshrc`
- `~/mcpservers.json` → `~/.config/mcp/mcpservers.json`
- `brew install zsh` 并设为默认 shell

## 模块总览

### 编辑器

| 模块 | 说明 |
|---|---|
| `nvim/` | Neovim 配置，主力开发环境。重点：Java/Spring Cloud 调试（Overseer 服务面板 + DAP）、Maven dashboard、JDTLS、MyBatis 符号导航。见 [nvim/README.md](nvim/README.md) |
| `ideavimrc` | IntelliJ IDEA 的 Vim 模拟配置（已回退到 nvim 工作流，Hyper 快捷键已停用） |

### 终端

| 模块 | 说明 |
|---|---|
| `kitty/` | 日常终端，含自定义布局脚本与主题切换（jb-theme/snazzy） |
| `ghostty/` | 备用终端，含 shader 与 [CLAUDE.md](ghostty/CLAUDE.md) |
| `wezterm/` | 备用终端 |
| `alacritty/` | 备用终端（toml 与 yml 双版本并存） |
| `tmux/` | tmux.conf + powerline/tpm/sensible，子模块管理 |
| `zsh/` | zshrc + fzf 增强（fzf.sh、fzf-preview.sh） |
| `starship.toml` / `neofetch/` | prompt 与系统信息 |

### 窗口管理与快捷键

| 模块 | 说明 |
|---|---|
| `yabai/` + `spacebar/` + `skhd/` | 平铺窗口管理 + 快捷键（含输入法状态脚本） |
| `aerospace/` | 另一套平铺 WM 配置 |
| `hammerspoon/` | 窗口布局（九宫格/分屏）与应用切换（Hyper 键）。见 [hammerspoon/README.md](hammerspoon/README.md) |
| `karabiner/` | Caps 长按 → Hyper（`cmd+shift+alt`）复杂修改 |

### 文件管理

| 模块 | 说明 |
|---|---|
| `ranger/` | 主力文件管理器（rc.conf + rifle + scope.sh） |
| `yazi/` | 备用（toml 全套配置 + 插件） |
| `lf/` / `joshuto/` | 备用 |

### 输入法

| 模块 | 说明 |
|---|---|
| `rime/` | 万象拼音方案 + macOS ↔ iPhone（Hamster/iCloud）同步。见 [rime/README.md](rime/README.md) |

### AI 编码

| 模块 | 说明 |
|---|---|
| `opencode/` | opencode CLI 配置（xrouter/omlx 等 provider）与 skills |
| `.claude/` | Claude Code 本地设置 |
| `codexbar/` | CodexBar 菜单栏工具的 provider 配置 |
| `github-copilot/` | Copilot 认证与 JetBrains 配置 |
| `*.avanterules` | avante.nvim 的规则体系（agentic/base/editing 等） |

### 数据库

| 模块 | 说明 |
|---|---|
| `vi-sql/` | 终端 SQL 客户端（PostgreSQL，Vim 键位，keyring 凭据） |

### 其他

| 模块 | 说明 |
|---|---|
| `git/` / `gh/` | git 与 GitHub CLI 配置 |
| `zellij/` | 终端多路复用器（[CLAUDE.md](zellij/CLAUDE.md)） |
| `herdr/` | 会话持久化配置 |
| `neovide/` `ueberzugpp/` `warpd/` `docs/` | 图形化 nvim、终端预览、鼠标导航、功能设计文档（[docs/plans/](docs/plans/)） |

## 子模块

| 路径 | 上游 |
|---|---|
| `tmux/plugins/tpm` | tmux-plugins/tpm |
| `tmux/plugins/tmux-powerline` | erikw/tmux-powerline |
| `tmux/plugins/tmux-sensible` | tmux-plugins/tmux-sensible |
| `tmux/vendor/tmux-mem-cpu-load` | thewtex/tmux-mem-cpu-load |
| `ranger/plugins/ranger_devicons` | alexanderjeurissen/ranger_devicons |

## 文档导航

- [nvim/README.md](nvim/README.md) — Java/Spring Cloud 调试手册（服务面板、DAP、Maven、MyBatis）
- [hammerspoon/README.md](hammerspoon/README.md) — 全局快捷键总表
- [rime/README.md](rime/README.md) — 万象拼音与双端同步
- [docs/plans/](docs/plans/) — nvim 功能的设计/计划文档（Maven 依赖分析、服务面板、Spring 导航等）
