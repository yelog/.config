# JDTLS Workspace Compatibility Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix stale Maven classpath providers and make Services launch only the selected Spring Boot main class.

**Architecture:** Version jdtls workspaces by the installed Java toolchain and replace all-main-class discovery with one explicit DAP launch configuration. Temporarily exclude incompatible Java Test bundles while retaining application debugging.

**Tech Stack:** Neovim Lua, nvim-jdtls, nvim-dap, Mason, Overseer.nvim

---

### Task 1: Add compatibility tests

**Files:**
- Modify: `nvim/tests/java_debug_spec.lua`

**Steps:**
1. Assert bundle discovery returns Java Debug only.
2. Assert the toolchain fingerprint changes when plugin filenames change.
3. Assert launch configuration uses selected service metadata without discovered configs.
4. Run focused tests and verify they fail.

### Task 2: Version jdtls workspaces

**Files:**
- Modify: `nvim/lua/custom/java_debug.lua`
- Modify: `nvim/lua/plugins/lsp/jdtls.lua`

**Steps:**
1. Implement deterministic toolchain fingerprinting.
2. Add the fingerprint to the project workspace directory.
3. Keep previous caches untouched.

### Task 3: Launch the selected service directly

**Files:**
- Modify: `nvim/lua/custom/java_debug.lua`

**Steps:**
1. Construct a minimal Java launch configuration from task metadata.
2. Apply project/profile overrides.
3. Call `dap.run()` and let nvim-jdtls enrich only that config.
4. Remove full-workspace discovery and its timeout.

### Task 4: Disable incompatible test bundles and verify

**Files:**
- Modify: `nvim/lua/custom/java_debug.lua`
- Modify: `nvim/lua/plugins/lsp/jdtls.lua`
- Modify: `nvim/README.md`

**Steps:**
1. Return only the Java Debug bundle from bundle discovery.
2. Replace Java test mappings with a compatibility notice.
3. Run unit tests, StyLua, `git diff --check`, and headless startup.
4. Verify moss-cloud creates a new workspace and enriches `MossAuthApplication`.
