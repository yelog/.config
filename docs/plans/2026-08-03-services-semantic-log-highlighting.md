# Services Semantic Log Highlighting Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Highlight structured Spring Boot log fields in Services output even when applications emit no ANSI escape codes.

**Architecture:** The generic output buffer accepts an optional line tokenizer and renders its semantic spans below existing ANSI spans. Spring Boot registers a tokenizer from its provider definition, keeping service-specific parsing out of the streaming renderer.

**Tech Stack:** Neovim Lua API, buffer extmarks, headless Neovim tests.

---

### Task 1: Add a semantic-span output extension

**Files:**
- Modify: `nvim/lua/services/output.lua`
- Modify: `nvim/lua/services/runtime.lua`

1. Add an optional `highlight_line` callback to `Output.new`.
2. Invoke it only after ANSI decoding has produced a complete line.
3. Render returned spans at lower priority than ANSI spans.
4. Pass the service definition callback through the runtime.

### Task 2: Add Spring Boot semantic parsing

**Files:**
- Create: `nvim/lua/services/log_highlighters/springboot.lua`
- Modify: `nvim/lua/services/providers/springboot.lua`

1. Match the timestamp, level, logger/class, and source line number in standard Spring Boot output.
2. Highlight stack traces and `Caused by:` lines.
3. Link semantic highlight groups to theme-provided groups and recreate links on color scheme changes.
4. Register the tokenizer only for Spring Boot services.

### Task 3: Regression coverage

**Files:**
- Modify: `nvim/tests/services_output_spec.lua`

1. Verify pure-text Spring Boot output receives level, logger, and line-number extmarks.
2. Retain existing ANSI streaming and reset coverage.
3. Run `nvim --headless -u NONE -l tests/services_output_spec.lua` and the Services provider tests.
