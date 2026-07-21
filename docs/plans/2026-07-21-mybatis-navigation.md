# MyBatis 导航 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为 Neovim 增加 Mapper Java 与 MyBatis XML 的双向导航，并在 `gd`、`gD`、`gu` 中按需回退到现有 LSP 导航。

**Architecture:** 新建无 UI 耦合的 `custom.mybatis_navigation`，负责识别当前 Java/XML 上下文、在 Maven Reactor 范围内解析 namespace 与 statement id，并返回“已处理”状态。`key-map.lua` 仅编排 MyBatis 优先与既有 Snacks/FZF 的回退，选择交由 `vim.ui.select`。

**Tech Stack:** Neovim Lua、`vim.fs`、`vim.fn.systemlist`/`rg`、`vim.ui.select`、headless Neovim 测试。

---

### Task 1: 建立可测试的 MyBatis 语义解析器

**Files:**
- Create: `nvim/lua/custom/mybatis_navigation.lua`
- Create: `nvim/tests/mybatis_navigation_spec.lua`

**Step 1: 写失败测试**

覆盖 Java package/interface/method 提取、XML namespace/statement 提取，以及 Java/XML 是否属于 MyBatis Mapper 上下文。

**Step 2: 运行测试确认失败**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: FAIL，因为模块尚不存在。

**Step 3: 实现最小解析逻辑**

导出纯函数，解析 FQCN、XML namespace 和 statement id；避免依赖当前窗口，便于单元测试。

**Step 4: 运行测试确认通过**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: PASS。

**Step 5: 提交**

```bash
git add nvim/lua/custom/mybatis_navigation.lua nvim/tests/mybatis_navigation_spec.lua
git commit -m "feat(nvim): parse MyBatis mapper navigation targets"
```

### Task 2: 实现 Reactor 范围检索与导航结果选择

**Files:**
- Modify: `nvim/lua/custom/mybatis_navigation.lua`
- Modify: `nvim/tests/mybatis_navigation_spec.lua`

**Step 1: 写失败测试**

用临时 fixture 验证通过 FQCN 查找 XML namespace、通过 namespace 查找 Java Mapper、唯一结果直跳及多个结果调用选择器。

**Step 2: 运行测试确认失败**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: FAIL，因为尚未建立项目索引和结果分发。

**Step 3: 实现最小导航逻辑**

从当前文件向上寻找最外层 Maven Reactor 根目录；使用 `rg` 定位候选 XML/Java，精确验证 `namespace` 与 `id`；以 `vim.cmd.edit` 跳转唯一项，以 `vim.ui.select` 选择多项。

**Step 4: 运行测试确认通过**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: PASS。

**Step 5: 提交**

```bash
git add nvim/lua/custom/mybatis_navigation.lua nvim/tests/mybatis_navigation_spec.lua
git commit -m "feat(nvim): navigate MyBatis mapper XML targets"
```

### Task 3: 实现 definition、implementation 和 usages 入口

**Files:**
- Modify: `nvim/lua/custom/mybatis_navigation.lua`
- Modify: `nvim/tests/mybatis_navigation_spec.lua`

**Step 1: 写失败测试**

验证 Java → XML、XML → Java、statement `<include refid>` 用法，以及“Mapper 上下文映射缺失视为已处理”和“非 MyBatis 上下文返回 false”。

**Step 2: 运行测试确认失败**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: FAIL，因为公开导航入口尚不存在。

**Step 3: 实现最小公开 API**

实现 `definition()`、`implementation()`、`usages()` 并始终返回处理状态；忽略 `BaseMapper` 继承 CRUD 和注解 SQL 的伪 XML 跳转。

**Step 4: 运行测试确认通过**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: PASS。

**Step 5: 提交**

```bash
git add nvim/lua/custom/mybatis_navigation.lua nvim/tests/mybatis_navigation_spec.lua
git commit -m "feat(nvim): add MyBatis navigation commands"
```

### Task 4: 接入既有快捷键并验证回退

**Files:**
- Modify: `nvim/lua/key-map.lua:309-329`
- Modify: `nvim/tests/mybatis_navigation_spec.lua`

**Step 1: 写失败测试**

验证 `gd`、`gD`、`gu` 在 MyBatis 方法返回 false 时分别仍调用当前 Snacks/FZF/i18n 回退逻辑。

**Step 2: 运行测试确认失败**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: FAIL，因为快捷键尚未接入。

**Step 3: 最小改动接入**

在现有映射中先调用相应 MyBatis 方法；只在返回 false 时执行原回调，保留既有快捷键描述与 i18n 优先级。

**Step 4: 完整验证**

Run: `nvim --headless '+lua print(vim.fn.maparg("gd", "n") ~= "" and vim.fn.maparg("gD", "n") ~= "" and vim.fn.maparg("gu", "n") ~= "")' '+q'`

Expected: 输出 `true`，并且 `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua` 通过。

**Step 5: 提交**

```bash
git add nvim/lua/key-map.lua nvim/lua/custom/mybatis_navigation.lua nvim/tests/mybatis_navigation_spec.lua
git commit -m "feat(nvim): prioritize MyBatis navigation shortcuts"
```
