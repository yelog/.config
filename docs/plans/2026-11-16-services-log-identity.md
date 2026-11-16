# Services Log Identity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the displayed service log immediately identifiable from both the Services list and the log header.

**Architecture:** Keep the existing list/log split and runtime. Derive a persistent selected-row highlight from the current theme, add a non-color selection marker through an extmark, and render the displayed service's identity and output mode in the existing log winbar.

**Tech Stack:** Lua, Neovim extmarks and winbars, existing Services runtime and headless specifications.

---

## Design

The screenshot has two related problems: the selected row depends on a subtle cursor-line background, and the adjacent log header only says `LOG [FOLLOW]`. Moving focus into logs weakens the only local indication of their source.

- Give the displayed service a full-row theme-derived selection background, bold text, and a `▸` marker. Keep the selection visible when the list loses keyboard focus.
- Repeat the same accent and selected surface in the log header. Show the service name first, followed by its semantic status/port and the right-aligned follow or terminal mode.
- Keep readiness colors independent from selection; running green must continue to mean running.
- Fit the header by display cells, escape literal `%` characters, and progressively simplify secondary details before truncating the service identity.
- Keep the existing split ratio, controls, log scrolling, and process lifecycle.
- On initial opening, show the first available service if no previous selection can be restored. When no service is displayed, show an explicit empty header and clear stale selection.

## Task 1: Cover selection and identity

**Files:** Create `nvim/tests/services_panel_identity_spec.lua`.

Exercise real buffers and windows with synthetic runtime records. Check persistent selection, cursor movement without list rewrites, source/status/follow headers, terminal output, switching and restoring selection, removal, root changes, literal percent signs, Unicode names, narrow output widths, and theme changes.

Run:

```sh
nvim --headless -u NONE -i NONE -l nvim/tests/services_panel_identity_spec.lua
```

Expected before implementation: failure on the persistent selection or named log header.

## Task 2: Implement focused presentation changes

**Files:** Modify `nvim/lua/services/panel.lua`.

Add theme-aware selection highlights, an independent selection namespace, and width-aware source headers. Update selection directly when focus changes, without rewriting list lines for log batches. Preserve the selected log through resizing and focus changes. Add concise user documentation to the existing Services section of `nvim/README.md`, preserving its unrelated pending edits.

Run the identity, style, and panel specifications after implementation.

## Task 3: Verify behavior and visual hierarchy

Run all `nvim/tests/services_*_spec.lua` suites in isolated headless processes. Capture actual Neovim screen cells with JB dark/light and narrow panels, including list focus, log focus, paused mode, and terminal output. Review the final diff and whitespace.

Do not restart running services, commit changes, or modify unrelated pending work.

## Verification Results

- All 12 `services_*_spec.lua` suites pass, including the new identity specification. The Java debug specification also passes.
- The new specification covers persistent selection, cursor-driven switching without list rewrites, follow/paused headers, unread counts, debug terminal replacement and archival, reopening, disposal, project switching, Unicode and literal percent signs, narrow panes, and theme changes.
- StyLua validation of the new specification and `git diff --check` pass.
- Actual Neovim TUI screen-cell captures pass for the original layout and the updated dark, light, paused, terminal, and narrow layouts, with keyboard focus in the log pane.
- Visual checks caught the foreground precedence of whole-line highlights. The selected row now sets only background and bold, retaining semantic status/icon/port colors; the log title has a separate foreground highlight.
- Preview artifacts are `services-identity-comparison.png` and `services-identity-validation.png` in `/Users/yelog/.codex/visualizations/2026/11/16/01a1e45d-7685-7c63-9182-e7c8b0bdcb36/`.
