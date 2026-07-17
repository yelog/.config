# Services Panel Focus Restore Implementation Plan

**Goal:** Restore Services panel window focus and the previously focused service after a toggle cycle.

**Architecture:** Store transient focused service keys in the panel controller by tab and normalized project root. Restore the key only after rendering so the current status-based row ordering is authoritative.

**Tech Stack:** Lua, Neovim API, headless Lua specifications

---

### Task 1: Add regression coverage

**Files:**
- Modify: `nvim/tests/services_panel_spec.lua`

Assert that opening focuses the list window and that closing/reopening restores the focused service row and output buffer.

### Task 2: Preserve and restore focus

**Files:**
- Modify: `nvim/lua/services/panel.lua`

Add controller-owned focus memory, save it from `focus` and `close`, restore it after render by service key, and make the list window current after open.

### Task 3: Verify

Run the Services panel spec, all Services specs, and StyLua checks for the modified Lua files.
