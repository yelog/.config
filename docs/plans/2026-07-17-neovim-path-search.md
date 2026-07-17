# Neovim Path Search Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 让 `cmd+shift+o` 的文件搜索支持 `gateway/pom.xml` 这类路径查询，并在可见结果中正确高亮关键字。

**Architecture:** 使用 Snacks Picker 在原始路径上匹配，并通过 `filename_first` formatter 将匹配位置映射到左侧文件名和右侧目录。保留可视选区初始查询，不改动其他 fzf-lua picker。

**Tech Stack:** Neovim Lua、fzf-lua、fzf、Lua 配置测试

---

### Task 1: 增加 formatter 版本回归测试

**Files:**
- Modify: `nvim/tests/config_correctness_spec.lua`
- Test: `nvim/tests/config_correctness_spec.lua`

**Step 1:** 添加断言，要求文件快捷键使用 Snacks Picker、启用 filename-first 并传递初始 pattern。

**Step 2:** 运行 `nvim --headless -u NONE -l tests/config_correctness_spec.lua`，确认修改配置前测试失败。

### Task 2: 启用 Snacks filename-first 文件搜索

**Files:**
- Modify: `nvim/lua/plugins/panel/fzf-lua.lua`

**Step 1:** 将文件搜索函数迁移到 `Snacks.picker.files`，并使用自定义 filename-first formatter 映射匹配位置。

**Step 2:** 重新运行配置测试，确认通过。

### Task 3: 验证真实搜索语义和完整测试

**Files:**
- Test: `nvim/tests/config_correctness_spec.lua`

**Step 1:** 用 Snacks matcher 验证查询 `gateway/pom.xml` 能返回 `moss-gateway/pom.xml`，且文件名和目录高亮位置正确。

**Step 2:** 运行 Neovim 测试套件并检查启动错误。

### Task 4: 修正图标导致的高亮列偏移

**Files:**
- Modify: `nvim/lua/custom/file_picker.lua`
- Modify: `nvim/tests/file_picker_spec.lua`

**Step 1:** 增加图标开启且占两列的渲染测试，确认匹配 extmark 相对内容向左偏移。

**Step 2:** 在添加图标后通过 `Snacks.picker.highlight.offset(ret)` 获取动态内容偏移，并传给 `matches`。

**Step 3:** 分别验证图标开启和关闭时，`gateway/pom.xml` 都准确高亮左侧 `pom.xml` 与右侧 `gateway`。

**Step 4:** 运行配置测试、格式检查和全量 Neovim 测试。
