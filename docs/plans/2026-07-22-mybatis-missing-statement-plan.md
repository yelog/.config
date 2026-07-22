# MyBatis Missing Statement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Diagnose Mapper methods that lack a matching MyBatis XML statement and provide a code action that generates the appropriate XML tag and jumps to it.

**Architecture:** Keep the existing navigation module focused on locating Mapper/XML symbols. Add a MyBatis diagnostics module that scans the current Mapper, publishes buffer diagnostics, and generates XML statements. Use a custom code-action entry point that preserves JDTLS actions while adding the MyBatis generation action for the active diagnostic.

**Tech Stack:** Neovim Lua APIs, JDTLS/LSP, `vim.diagnostic`, XML/Java text parsing, existing MyBatis navigation helpers and headless Lua specs.

---

### Task 1: Extend MyBatis parsing helpers

**Files:**
- Modify: `nvim/lua/custom/mybatis_navigation.lua`
- Modify: `nvim/tests/mybatis_navigation_spec.lua`

**Steps:**
1. Add helpers for extracting all Mapper interface methods with method names and source ranges.
2. Add helpers for collecting XML statements as `{ id, tag, row }`, including single- and double-quoted attributes.
3. Add tests for method extraction, statement extraction, and multiline-safe boundary cases.
4. Run `nvim --headless -u NONE -l nvim/tests/mybatis_navigation_spec.lua`.

### Task 2: Add missing-statement diagnostics and generation

**Files:**
- Create: `nvim/lua/custom/mybatis_diagnostics.lua`
- Create: `nvim/tests/mybatis_diagnostics_spec.lua`

**Steps:**
1. Implement method-prefix classification for select/insert/update/delete, with explicit handling for `add`, `insert`, `del`, `delete`, `query`, `get`, and `select`.
2. Resolve the XML by exact Mapper namespace and report an actionable error when a Java method has no matching statement.
3. Insert a generated statement immediately before `</mapper>`, preserving indentation and writing a valid placeholder body.
4. Reopen/update the XML buffer and return the generated location for jumping.
5. Add tests for diagnostics, prefix classification, XML insertion, duplicate protection, and unknown prefixes.
6. Run `nvim --headless -u NONE -l nvim/tests/mybatis_diagnostics_spec.lua`.

### Task 3: Connect diagnostics to Java lifecycle

**Files:**
- Modify: `nvim/lua/plugins/lsp/jdtls.lua`
- Modify: `nvim/lua/custom/mybatis_diagnostics.lua`

**Steps:**
1. Refresh MyBatis diagnostics after a Java buffer is attached or written.
2. Refresh the matching Java Mapper after its XML file is written.
3. Clear stale diagnostics when a buffer stops being a Mapper or no matching Maven project/XML exists.
4. Keep JDTLS compiler diagnostics separate by using a dedicated diagnostic namespace and `source = "mybatis"`.

### Task 4: Add the code-action entry point

**Files:**
- Modify: `nvim/lua/plugins/lsp/jdtls.lua`
- Modify: `nvim/tests/mybatis_diagnostics_spec.lua`

**Steps:**
1. Add a buffer-local code-action wrapper that detects the active MyBatis missing-statement diagnostic.
2. Offer `Generate <tag> statement for <method>` and apply it with one selection.
3. Fall back to `vim.lsp.buf.code_action()` for normal JDTLS actions.
4. Verify the action is only available for the relevant diagnostic and that the generated XML location is opened.

### Task 5: Run focused verification

**Files:**
- Verify: `nvim/lua/custom/mybatis_navigation.lua`
- Verify: `nvim/lua/custom/mybatis_diagnostics.lua`
- Verify: `nvim/lua/plugins/lsp/jdtls.lua`
- Verify: `nvim/tests/mybatis_navigation_spec.lua`
- Verify: `nvim/tests/mybatis_diagnostics_spec.lua`

**Steps:**
1. Run both MyBatis specs with `nvim --headless -u NONE -l`.
2. Run the full test loop: `for test in nvim/tests/*_spec.lua; do nvim --headless -u NONE "+luafile $test" "+qa!" || exit 1; done`.
3. Run `stylua --check nvim/lua/custom/mybatis_navigation.lua nvim/lua/custom/mybatis_diagnostics.lua nvim/lua/plugins/lsp/jdtls.lua nvim/tests/mybatis_navigation_spec.lua nvim/tests/mybatis_diagnostics_spec.lua` when available.
