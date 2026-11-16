# Java Highlighting Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore JDTLS with Java 25, preserve project compilation JDKs, distinguish Java symbol roles, and recover Tree-sitter highlighting after startup failures.

**Architecture:** Keep language-server JVM selection separate from project runtime defaults. Extend the existing JB ColorScheme callback with Java-specific groups, and make Tree-sitter activation idempotent and observable across startup, buffer entry, and parser installation.

**Tech Stack:** Neovim 0.12, Lua, nvim-jdtls, Eclipse JDT LS 1.63, SDKMAN, jb.nvim, nvim-treesitter main.

---

## 1. Runtime selection and project JDK preservation

- Update `lua/custom/java_runtime.lua`, `lua/plugins/lsp/jdtls.lua`, and their existing regression tests.
- Require Java 25 or newer for language servers; consider `JAVA_HOME_25` and preserve validated explicit overrides.
- Keep `JAVA_HOME` as the default project runtime independently of the language-server JVM. Continue exposing older project JDKs.
- Test incompatible overrides, SDKMAN patch selection, cache invalidation, symlink deduplication, absent metadata, retries, and unchanged parent environment.
- Run `nvim --headless -u NONE -i NONE -l tests/java_runtime_spec.lua` and `tests/jdtls_startup_spec.lua`.

## 2. Java color roles

- Update `lua/plugins/style/jb.lua` and add a focused Java highlight regression.
- Distinguish parameters, fields, types, method declarations, and method calls through Java-specific Tree-sitter and semantic groups.
- Preserve modifier styling, support JB light/dark backgrounds, and reapply after ColorScheme reloads without changing other languages.
- Run the focused regression with the installed theme, then verify the existing CodeLens regression.

## 3. Tree-sitter activation recovery

- Update `lua/plugins/lsp/treesitter.lua`, adding a small custom module only if it simplifies activation state and testing.
- Handle already-loaded buffers, FileType, buffer entry, and asynchronous parser installation.
- Skip unsupported/special buffers, avoid duplicate successful starts and autocmds, retry failures, and rate-limit useful warnings.
- Test startup event ordering, missing parser recovery, failed query recovery, and repeated setup.
- Run the new regression and `tests/mybatis_treesitter_spec.lua`.

## 4. Integrated verification and documentation

- Extend `tests/jdtls_startup_bench.lua` to check semantic token roles and Java 17 compilation settings while JDTLS runs on Java 25.
- Run cold and warm real-server tests in an isolated disposable Maven project; check Java/Spring exits and retained debug extensions.
- Check the complete configuration and relevant Java/Spring regressions; inspect the patch for whitespace and unrelated changes.
- Update `README.md` with launcher/project JDK separation, colors, recovery behavior, and activation instructions.

Execution continues in the current checkout. No branches, commits, cache deletion, or changes to project build files are required.

## Completed verification

- All four stages are complete. Fourteen focused Java/Spring, highlighting, Tree-sitter, theme, and configuration regression scripts passed.
- Scoped StyLua checks passed for the new modules, updated runtime/configuration, and regression scripts. `git diff --check` passed.
- Real JDTLS 1.63.0 cold/warm runs selected SDKMAN Corretto 25.0.2 automatically, resolved cross-file definitions in 4.71/2.49 seconds, and exited cleanly with Spring in 0.39/0.90 seconds.
- Both runs returned 17 semantic tokens covering variables, parameters, properties, classes, and methods. Spring and Java Debug commands remained available.
- The imported Maven fixture retained JDK 17.0.15 and Java 17 compliance/source/target. A separate Maven build using JDK 17 succeeded; all three compiled fixture classes have class-file major version 61.
- A complete Neovim startup opening a Java file on its command line passed with JDK 17 in the parent environment, JDTLS on JDK 25, Tree-sitter active, automatic semantic highlighting, and 19 correctly classified tokens.
- Java colors passed dark/light/reload tests, retained modifier attributes, and met 4.5:1 contrast for the configured roles.
- Tree-sitter regressions exercised real parsers/highlighters plus transient missing parsers, missing/invalid cached queries, asynchronous completion, stale callbacks, repeated setup, filetype changes, and special-buffer preservation.
- The existing `tests/jb_codelens_spec.lua` underline assertion fails against both the original HEAD configuration and this patch because the installed theme no longer supplies that underline. The new color regression verifies that current CodeLens attributes are preserved.
- Parser downloads/compilation and full import timing for the large existing `moss-cloud` repository were not exercised. The complete configuration must be loaded in a new Neovim process; `:JdtRestart` alone reuses already-loaded Lua settings.
