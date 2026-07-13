# Neovim Java JDTLS and Lombok Design

## Goal

Make Java and Spring Cloud projects use one stable JDT LS client with Lombok-aware diagnostics and project-isolated index data.

## Design

- Keep Mason responsible for installing `jdtls`, but exclude it from `mason-lspconfig` automatic LSP enablement.
- Let `nvim-jdtls` be the only component that starts or attaches JDT LS.
- Build the JDT LS configuration for every Java `FileType` event so project roots do not leak between buffers or projects.
- Load Java tooling before Java buffers are read and handle command-line files whose type was detected during startup.
- Prefer multi-module markers such as wrappers, Gradle settings, and `.git`, then fall back to the nearest Maven, Gradle, or Ant build file.
- Pass Mason's bundled Lombok jar through the wrapper's `--jvm-arg=-javaagent:` option.
- Derive the JDT LS data directory from the project basename and a hash of the absolute root path to isolate same-named clones.
- Use `nvim-jdtls`' current extended capabilities instead of maintaining a copied capability table.
- Initialize `spring-boot.nvim` and add its Java extension jars to JDT LS bundles.
- Remove global `autochdir` so project-aware tools keep a stable working directory.

## Verification

- Load the Neovim configuration headlessly and confirm there are no Lua errors.
- Open a project Java file in a temporary JDT LS data directory and confirm exactly one client attaches.
- Inspect the launched command for the Lombok javaagent and explicit data directory.
- Confirm Lombok-generated methods no longer produce undefined-method diagnostics.
