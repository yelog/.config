<div align="center">

# 🌳 万象拼音

**重塑 Rime 生态，带来极致的输入体验。**

[![快速上手](https://img.shields.io/badge/🚀_快速上手-探索文档-4CAF50?style=for-the-badge)](https://amzxyz.github.io/)
[![GitHub](https://img.shields.io/badge/⭐_GitHub_仓库-访问主页-2ea44f?style=for-the-badge)](https://github.com/amzxyz/rime-wanxiang)
<br>
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![GitHub Release](https://img.shields.io/github/v/release/amzxyz/rime-wanxiang?filter=!nightly)](https://github.com/amzxyz/rime-wanxiang/releases/)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/amzxyz/rime-wanxiang/release.yml)](https://github.com/amzxyz/rime-wanxiang/actions/workflows/release.yml)
[![GitHub Repo stars](https://img.shields.io/github/stars/amzxyz/rime-wanxiang?style=flat&color=success)](https://github.com/amzxyz/rime-wanxiang/stargazers)

</div>

---

## 🌌 万象拼音——基于深度优化的词库和语法模型

> **💎 核心基石：** [万象词库](https://github.com/amzxyz/RIME-LMDG) 经 AI 与海量语料深度优化(目前已进入手动维护期)，是一款专为“语句流”“类大厂”打造的全方案立体词库。它将**带调拼音标注、词组构成与精准词频**作为体验基石，以日常与专业词汇为主体，结合语法模型，为您带来精准、流畅的输入体验。

* **开放生态**：支持高度自定义，鼓励通过“词库 + 转写”打造您的专属输入方案。
* **持续打磨**：我们极度重视数据准确与时效，欢迎随时反馈。
* 📝 **[万象词库问题收集反馈表](https://docs.qq.com/smartsheet/DWHZsdnZZaGh5bWJI?viewId=vUQPXH&tab=BB08J2)**


---

## ✨ 效果预览
![](https://storage.deepin.org/thread/202502200358104987_%E6%95%88%E6%9E%9C.png)

---

## 🧭 探索万象

<table width="100%" align="center" border="0" cellspacing="15" cellpadding="0">
  <tr>
    <td width="50%" valign="top">
      <div style="border: 1px solid #546e7a4d; border-radius: 12px; padding: 20px;">
        <h3>🚀 快速上手</h3>
        <p>从零开始，为您在 Windows、macOS 以及 iOS/Android 移动端部署万象。</p>
        <a href="https://amzxyz.github.io/doc/intro"><strong>➡️ 立即安装</strong></a>
      </div>
    </td>
    <td width="50%" valign="top">
      <div style="border: 1px solid #546e7a4d; border-radius: 12px; padding: 20px;">
        <h3>⌨️ 核心输入体系</h3>
        <p>深入解析万象独特的“带调拼音标注”、强大的辅码系统（小鹤、自然码等）以及中英混输机制。</p>
        <a href="https://amzxyz.github.io/doc/aux_code"><strong>➡️ 了解核心</strong></a>
      </div>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <div style="border: 1px solid #546e7a4d; border-radius: 12px; padding: 20px;">
        <h3>🪄 Lua 魔法扩展</h3>
        <p>计算器、超级注释、符号包裹、动态时间戳... 探索让 Rime 拥有“超能力”的数十种微创新脚本。</p>
        <a href="https://amzxyz.github.io/doc/shijian"><strong>➡️ 探索魔法</strong></a>
      </div>
    </td>
    <td width="50%" valign="top">
      <div style="border: 1px solid #546e7a4d; border-radius: 12px; padding: 20px;">
        <h3>⚙️ 词库与模型</h3>
        <p>深度解析万象的现代数据工程。算一笔隐形的“时间账”，彻底告别低效的候选翻页，让输入如呼吸般自然。</p>
        <a href="https://amzxyz.github.io/doc/dict_gram"><strong>➡️ 揭秘底层逻辑</strong></a>
      </div>
    </td>
  </tr>
</table>

---

## 💎 标准版 vs 增强版

万象提供两个主要版本，请根据您的输入习惯选择。为了获得最佳体验，**请务必了解您所选版本的特性**：


| 特性对比 <img width="180" style="display:none;" /> | 🟢 标准版 (Base) <img width="340" style="display:none;" /> | 🔵 增强版 (Pro) <img width="340" style="display:none;" /> |
| :--- | :--- | :--- |
| **适用人群** | 新手、全拼用户、追求省心的双拼用户 | 硬核双拼用户、重度辅码与造词需求者 |
| **方案文件** | `wanxiang.schema.yaml` | `wanxiang_pro.schema.yaml` |
| **支持类型** | 全拼、任意双拼 | **仅支持双拼** |
| **自动调频** | 默认开启 | **默认关闭** (精准控制) |
| **用户词记录** | 自动记录，无差别积累 | 手动/无感造词，词库绝对可控 |
| **辅助码支持** | 仅基于声调的辅助 | **8 种辅助码可选** + 声调辅助 |
| **全场景辅筛** | 支持两分、多分、笔画、声调 | 全面支持 + 专属辅助码筛选 |

---

## 生态：

[薄荷拼音](https://github.com/Mintimate/oh-my-rime) :使用万象词库的综合性方案，特别是其修改的地球拼音能够继承万象的词库声调编码。

[鸢鸣万象](https://github.com/yuanz-12/wanxiang_yoemin) :一个基于万象拼音生态融合李氏三拼与辅助码能力的手机用方案。

[万象虎](https://github.com/zhhwux/wxzhh) : 一个基于万象生态的虎码整句方案。

---

<div align="center" style="margin-top: 3rem; margin-bottom: 2rem;">
    <img alt="pay" src="./custom/赞赏.jpg" width="300" style="width: 300px !important; max-width: 300px !important;">
    <p style="margin-top: 1.2rem; font-size: 1.1em;">
         <strong>如果觉得项目好用，欢迎在 GitHub 为我们点亮 Star！</strong>
    </p>
    <p style="margin-top: 0.5rem; color: #555;">
        <strong>☕ 感谢您的赞赏与支持</strong>
    </p>
    <p style="margin-top: 0.5rem; opacity: 0.8;">
        <i>用更现代的数据，接管你的候选词。</i>
    </p>
</div>

---

## 📱 macOS ↔ iPhone 同步配置

本方案使用 [Hamster（仓输入法）](https://github.com/imfuxiao/Hamster) 在 iPhone 端使用万象拼音，通过 iCloud 实现 Mac 与 iPhone 之间的配置和用户词典同步。

### 同步架构

```
  配置文件 (*.yaml, lua/, dicts/)         用户词典 (*.userdb)
  ┌──────────┐   rsync (自动)  ┌──────────┐   ┌──────────┐  Rime Sync  ┌──────────┐
  │  macOS    │ ─────────────→ │  iCloud   │   │  macOS    │ ──────────→ │  iCloud   │
  │ Squirrel  │                │  Drive    │   │ Squirrel  │             │  sync/    │
  └──────────┘                └─────┬────┘   └──────────┘             └─────┬────┘
                                    │                                        │
                              Hamster 重新部署                          Rime 同步
                                    │                                        │
                              ┌─────┴────┐                            ┌─────┴────┐
                              │  iPhone   │                            │  iPhone   │
                              │ Hamster   │                            │ Hamster   │
                              └──────────┘                            └──────────┘
```

### 文件说明

| 文件 | 用途 |
|---|---|
| `sync-rime.sh` | 同步脚本（手动执行或由 crontab 定时调用） |
| `sync.log` | 同步日志（自动保留最近 500 条） |

### 已配置的自动化

crontab 每 30 分钟自动执行 `sync-rime.sh`，将配置文件推送到 Hamster iCloud 目录。

```bash
# crontab 任务
*/30 * * * * /bin/bash /Users/yelog/.config/rime/sync-rime.sh
```

### 快捷命令

```bash
# 同步配置到 Hamster（会检查用户词典导出状态并提醒）
rime-sync

# 查看同步日志
cat ~/.config/rime/sync.log
```

### 同步流程

有两种同步内容，机制不同：

| 内容 | 同步方式 | 自动化 |
|---|---|---|
| 配置文件 (*.yaml, lua/, dicts/) | rsync 到 iCloud | ✅ crontab 每 30 分钟 |
| 用户词典 (自造词、调频) | Rime 内置同步机制 | ❌ 需手动触发 |

#### 用户词典同步（手动）

用户词典不会自动导出，需要手动触发：

1. **macOS 端**：菜单栏 → Squirrel → 同步用户数据（导出 userdb.txt 到 iCloud sync 目录）
2. **iPhone 端**：Hamster → Rime 功能 → Rime 同步（读取并合并 userdb.txt）

> 💡 `rime-sync` 会检查 userdb.txt 的导出时间，超过 1 小时未导出会提醒你先执行步骤 1。

#### 配置文件同步（自动 + 手动）

- **自动**：crontab 每 30 分钟执行 `sync-rime.sh`
- **手动**：终端执行 `rime-sync`
- **生效**：iPhone 端 Hamster → 重新部署

### installation.yaml 配置

两端需要配置相同的 `sync_dir`，不同的 `installation_id`：

**macOS 端** (`~/.config/rime/installation.yaml`)：
```yaml
installation_id: "squirrel_yelog"
sync_dir: "/Users/yelog/Library/Mobile Documents/iCloud~dev~fuxiao~app~hamsterapp/Documents/sync"
```

**iPhone 端** (Hamster → 文件管理 → `Rime/installation.yaml`)：
```yaml
installation_id: "hamster_yelog"
sync_dir: "/private/var/mobile/Library/Mobile Documents/iCloud~dev~fuxiao~app~hamsterapp/Documents/sync"
```

### 排除的文件

以下文件不会同步到 iPhone（由 `sync-to-hamster.sh` 和 `sync-rime.sh` 排除）：

| 文件 | 原因 |
|---|---|
| `*.userdb` / `*.userdb.*` | 二进制用户词典，由 Rime Sync 单独处理 |
| `build/` | 编译产物，各端自行生成 |
| `*.gram` | 语言模型（~421MB），体积过大 |
| `*.bin` | 编译后的二进制索引 |
| `sync/` | Rime Sync 目录，已有独立的 iCloud 路径 |
| `installation.yaml` / `user.yaml` | 设备特定配置，两端不同 |

### 注意事项

- iPhone 端需要在 iOS 设置中为 Hamster 开启「完全访问权限」
- iPhone 端 Hamster 需关闭「部署时覆盖键盘词库文件」
- 修改配置后需在 iPhone 端手动点击「重新部署」生效
- 用户词典同步需两端分别触发（macOS 菜单栏 / iPhone Hamster）