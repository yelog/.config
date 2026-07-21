# MyBatis 调用点导航 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 让 Java Service 等调用点上的 Mapper 自定义方法执行 `gD` 时直达 MyBatis XML。

**Architecture:** 扩展 `custom.mybatis_navigation`：在现有 Mapper 上下文未命中时，从 jdtls 同步请求 definition，验证 definition 所在 Java 文件是 Mapper 后复用 namespace/id XML 定位逻辑。无法证明为 MyBatis XML 实现时返回 `false`，由 `key-map.lua` 保留既有回退。

**Tech Stack:** Neovim Lua、LSP `textDocument/definition`、jdtls、headless Neovim。

---

### Task 1: 实现 LSP definition 到 Mapper 目标的解析

**Files:**
- Modify: `nvim/lua/custom/mybatis_navigation.lua`
- Modify: `nvim/tests/mybatis_navigation_spec.lua`

**Step 1: 写失败测试**

覆盖 LSP definition location 转本地文件、读取 Mapper FQCN/方法名，以及非 Mapper location 返回 nil。

**Step 2: 运行测试确认失败**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: FAIL，因为 definition 解析器不存在。

**Step 3: 实现最小解析逻辑**

请求已附加 LSP 的 `textDocument/definition`，规范化 Location/LocationLink，验证 Java Mapper 后生成 XML statement target。

**Step 4: 运行测试确认通过**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: PASS。

### Task 2: 接入 gD 的调用点优先跳转

**Files:**
- Modify: `nvim/lua/custom/mybatis_navigation.lua`
- Modify: `nvim/tests/mybatis_navigation_spec.lua`

**Step 1: 写失败测试**

模拟 call-site definition 命中 `SysDeptMapper.queryAllChildrenId`，验证跳转到 `SysDeptMapper.xml`；非 Mapper、缺失 statement 和无 LSP 均返回 false。

**Step 2: 运行测试确认失败**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: FAIL，因为 `implementation()` 尚未解析调用点。

**Step 3: 实现最小接入**

仅当原有当前 Mapper/XML 上下文未命中时触发 LSP 解析；找到唯一 XML statement 时跳转，多结果保持选择器，其他情况不吞掉原有回退。

**Step 4: 完整验证**

Run: `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`

Expected: PASS。

手工验证：打开 `SysUserServiceImpl.java` 第 93 行与 `SysDeptServiceImpl.java` 第 32 行，在 `queryAllChildrenId` 上执行 `gD`，均打开 `SysDeptMapper.xml` 的 statement。
