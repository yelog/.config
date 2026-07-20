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

### Task 5: 文件名最佳匹配优先排序

**Files:**
- Modify: `nvim/lua/custom/file_picker.lua`
- Modify: `nvim/lua/key-map.lua`
- Modify: `nvim/tests/file_picker_spec.lua`
- Modify: `nvim/tests/config_correctness_spec.lua`

**Step 1:** 增加评分测试，覆盖完全匹配、边界连续匹配、普通连续匹配、文件名模糊匹配和仅目录匹配。

**Step 2:** 实现纯函数 `filename_match_bonus(query, path)`，只使用查询的最后一个路径片段评价文件名质量。

**Step 3:** 通过 Snacks `matcher.on_match` 动态增加文件名质量分，同时保留原始路径相关度作为次级排序。

**Step 4:** 运行专项测试、配置测试、格式检查和全量 Neovim 测试。

### Task 6: 查询分段最佳区域高亮

**Files:**
- Modify: `nvim/lua/custom/file_picker.lua`
- Modify: `nvim/tests/file_picker_spec.lua`

**Step 1:** 增加 `gateway/appli` 测试，要求 `gateway` 和 `appli` 都优先高亮在文件名中。

**Step 2:** 将查询按路径分隔符拆段；每段依次尝试文件名连续、文件名模糊、末级目录到上级目录的连续和模糊匹配。

**Step 3:** formatter 使用分段计算的显示坐标，不再直接映射整条原始路径 matcher 坐标。

**Step 4:** 回归 `gateway/pom.xml`，确认 `pom.xml` 高亮文件名、`gateway` 回退高亮目录。

### Task 7: 保留路径分隔符的作用域语义

**Files:**
- Modify: `nvim/lua/custom/file_picker.lua`
- Modify: `nvim/tests/file_picker_spec.lua`

**Step 1:** 将 `gateway/appli` 预期改为 `gateway` 只高亮目录、`appli` 优先高亮文件名，确认旧算法失败。

**Step 2:** 解析查询时保留 `/`：最后一个分隔符之前的片段只搜索目录，最后片段才执行文件名优先和目录回退。

**Step 3:** 验证无分隔符查询仍然文件名优先，并覆盖多级目录查询。
