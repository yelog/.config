# Services Statusline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Display managed service lifecycle and shutdown progress in Heirline instead of Noice's transient UI.

**Architecture:** A small `services.status` module maps runtime and lifecycle data to one prioritized statusline model. Runtime and lifecycle publish a shared User event; Heirline redraws the component from current state.

**Tech Stack:** Lua, Neovim User autocmds, Heirline, headless Neovim tests.

---

### Task 1: Test Status Aggregation

**Files:**
- Create: `nvim/tests/services_status_spec.lua`
- Create: `nvim/lua/services/status.lua`

**Step 1: Write failing summary tests**

Test empty, idle, starting, running, failed, closing, and force-close inputs. Verify higher-priority shutdown states replace normal runtime summaries.

**Step 2: Run the specification**

```bash
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_status_spec.lua" "+qa!"
```

Expected: FAIL because `services.status` does not exist.

**Step 3: Implement the pure status model**

Return `{ text, kind }` or `nil` for an empty runtime. Use the design's state priority and compact Chinese labels.

### Task 2: Publish And Render State

**Files:**
- Modify: `nvim/lua/services/lifecycle.lua:1-75`
- Modify: `nvim/lua/services/runtime.lua:82-90`
- Modify: `nvim/lua/plugins/panel/status-line.lua:458-474`
- Modify: `nvim/tests/services_lifecycle_spec.lua:55-113`

**Step 1: Publish shutdown state**

Replace command-area rendering with a structured lifecycle state and `ServicesStatusChanged` event. Preserve injected test renderer and clear state after shutdown.

**Step 2: Publish runtime state changes**

Emit the same User event after runtime service events so Heirline redraws after start, stop, failure, and disposal.

**Step 3: Add the Heirline component**

Place a `ServiceStatus` component after `%=`. Read `services.status.summary(runtime:list(), lifecycle.shutdown_status())`, map its kind to current palette colors, and redraw on the User event.

**Step 4: Run focused tests**

Run the status and lifecycle specifications. Expected: both report `ok`.

### Task 3: Regression Verification

**Files:**
- Verify: `nvim/tests/services_*_spec.lua`

**Step 1: Run service specifications**

```bash
for spec in nvim/tests/services_*_spec.lua; do nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/$spec" "+qa!" || exit 1; done
```

Expected: every specification reports `ok`.

**Step 2: Validate diff**

```bash
git diff --check
```

Expected: no output.
