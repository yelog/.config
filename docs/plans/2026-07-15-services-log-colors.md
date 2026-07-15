# Services Log Color Fidelity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Correct and stabilize ANSI colors in Neovim Services logs, including Spring Boot output over non-TTY pipes.

**Architecture:** Retain the streaming ANSI-to-extmark renderer and fix style lifecycle inside it. Make dynamic highlight definitions theme-aware and force Spring Boot application ANSI at the provider boundary.

**Tech Stack:** Neovim Lua API, `vim.system`, buffer extmarks, Lua headless tests

---

### Task 1: Correct ANSI reset boundaries

**Files:**
- Modify: `nvim/tests/services_output_spec.lua`
- Modify: `nvim/lua/services/output.lua:93-97`

**Steps:**

1. Add failing tests that inspect extmark details after SGR `0`, `39`, and `49`.
2. Run `nvim --headless -u NONE -l tests/services_output_spec.lua` and verify the reset-range assertion fails.
3. Replace table iteration in `reset_style` with explicit assignments for nullable colors and boolean attributes.
4. Run the output test and verify it passes.

### Task 2: Render faint text and survive colorscheme changes

**Files:**
- Modify: `nvim/tests/services_output_spec.lua`
- Modify: `nvim/lua/services/output.lua:35-91`

**Steps:**

1. Add failing tests for a distinct faint highlight foreground and highlight recreation after `ColorScheme`.
2. Add helpers to read `Normal` colors, blend RGB values, and resolve the effective faint foreground.
3. Store generated style definitions, invalidate/recreate highlight groups on `ColorScheme`, and assign ANSI extmarks explicit priority.
4. Run the output test and verify it passes.

### Task 3: Force Spring Boot application ANSI

**Files:**
- Modify: `nvim/tests/services_providers_spec.lua`
- Modify: `nvim/lua/services/providers/springboot.lua:203-228`

**Steps:**

1. Add a failing provider assertion for `SPRING_OUTPUT_ANSI_ENABLED=ALWAYS`.
2. Run `nvim --headless -u NONE -l tests/services_providers_spec.lua` and verify it fails.
3. Add the environment variable to each discovered Spring Boot definition.
4. Run the provider test and verify it passes.

### Task 4: Regression verification

**Files:**
- Verify only; no planned modifications

**Steps:**

1. Run every `nvim/tests/services_*_spec.lua` test individually through headless Neovim.
2. Run `nvim/tests/java_debug_spec.lua` because debug output shares the Services log buffer.
3. Inspect `git diff --` for the two implementation files, two tests, and plan documents.
4. Confirm unrelated staged lifecycle changes remain untouched.
