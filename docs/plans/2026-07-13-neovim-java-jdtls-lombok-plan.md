# Neovim Java JDTLS and Lombok Implementation Plan

**Goal:** Run one Lombok-enabled JDT LS client per Java project with isolated index data.

**Architecture:** Mason installs the server while `nvim-jdtls` exclusively controls its lifecycle. Each Java buffer computes its own project root and deterministic workspace before starting or attaching the client.

**Tech Stack:** Neovim 0.11, lazy.nvim, mason.nvim, mason-lspconfig.nvim, nvim-jdtls, Eclipse JDT LS, Lombok, spring-boot.nvim

---

### Task 1: Disable automatic JDT LS enablement

**Files:**
- Modify: `nvim/lua/plugins/lsp/lsp.lua`

1. Add `automatic_enable.exclude = { "jdtls" }` to Mason LSP setup.
2. Keep `jdtls` in `ensure_installed`.
3. Load the configuration headlessly and verify Mason setup succeeds.

### Task 2: Build a project-scoped JDT LS configuration

**Files:**
- Modify: `nvim/lua/plugins/lsp/jdtls.lua`

1. Move root and workspace calculation into the Java `FileType` callback.
2. Prefer multi-module root markers and fall back to single-module build files.
3. Hash the absolute root path in the workspace identifier.
4. Pass `--jvm-arg=-javaagent:<mason-jdtls>/lombok.jar` and an explicit `-data` directory.
5. Use `jdtls.extendedClientCapabilities`.
6. Load on Java buffer-read events and start immediately for command-line Java files.

### Task 3: Enable Spring Boot extensions

**Files:**
- Modify: `nvim/lua/plugins/lsp/jdtls.lua`

1. Initialize `spring-boot.nvim` through lazy.nvim options.
2. Add `require("spring_boot").java_extensions()` to JDT LS bundles.
3. Preserve the existing Java keymaps and language settings.

### Task 4: Stabilize the working directory

**Files:**
- Modify: `nvim/base.vim`

1. Remove redundant filetype commands already enabled by Neovim 0.11.
2. Remove global `autochdir` so LSP, DAP, terminals, and task runners keep project scope.

### Task 5: Verify runtime behavior

**Files:**
- Test only; no project source changes.

1. Run a headless Neovim startup check.
2. Launch a Java file with an isolated temporary data directory.
3. Verify one JDT LS client attaches.
4. Verify the process command contains the Lombok agent.
5. Inspect diagnostics for a Lombok-generated getter call.
