# Neovim Java and Spring Cloud debugging

This configuration supports Java launch debugging for Maven multi-module Spring Cloud projects through the Overseer Services panel.

## Prerequisites

- JDK 21 to run jdtls. Project runtimes may still use Java 8, 11, 17, or 21 through the configured `JAVA_HOME*` variables.
- Maven available as `mvn`.
- A repository containing one or more classes annotated with `@SpringBootApplication`.
- Mason packages `jdtls`, `vscode-spring-boot-tools`, `java-debug-adapter`, and `java-test`.

`mason-tool-installer.nvim` installs the debug and test packages automatically. To install them immediately, run:

```vim
:MasonToolsInstall
```

After the first installation, restart Neovim before opening the project so jdtls receives the new bundles during initialization.

## Debug a service

1. Start Neovim from the repository root: `nvim .`.
2. Open any Java source file and wait until jdtls finishes importing the Maven project. Check `:LspInfo` if needed.
3. Set a breakpoint with `<leader>db`.
4. Open the Services panel with `<leader>oo`.
5. Optional: press `p` in the panel and select the active Spring profile.
6. Move to the required service and press `<leader>d`.
7. The row changes to `◆ debugging` when DAP owns the service process.
   The service's DAP terminal replaces its existing output in the right-hand Services pane; no extra split is opened.
8. Use `<leader>dc` to continue, `<leader>do` to step over, `<leader>di` to step into, and `<leader>dO` to step out.
9. Press `S` on the service or `<leader>dt` anywhere to terminate debugging.

If the service is already running through Overseer, the debug action stops it and waits for process completion before launching DAP. Pressing `s` on a debugging service terminates DAP first and then starts the normal Maven service task.

## Project-specific options

Create `.nvim/java-debug.json` in the repository root when a service needs custom JVM arguments, application arguments, environment variables, or a working directory:

```json
{
  "defaults": {
    "vmArgs": "-Xms512m -Xmx2g",
    "env": {
      "NACOS_ADDR": "127.0.0.1:8848"
    }
  },
  "services": {
    "com.example.order.OrderApplication": {
      "args": "--server.port=8082",
      "env": {
        "LOG_LEVEL": "debug"
      }
    }
  }
}
```

`defaults` applies to every service. `services` is keyed by the fully qualified Spring Boot main class and overrides defaults. The profile selected in the panel is appended as `-Dspring.profiles.active=<profile>`.

## Useful commands

- `:Mason` checks whether Java tools are installed.
- `:LspInfo` checks whether jdtls is attached to the main-class source file.
- `:JdtRestart` restarts jdtls after installing or changing bundles.
- `<leader>jd` refreshes jdtls-discovered Java launch configurations.
- `<leader>dr` opens the DAP REPL.
- `<leader>os` stops all normal and debugging services.

If the panel reports that Java Debug was not loaded, run `:MasonToolsInstall`, restart Neovim, reopen a Java file, and verify that jdtls exposes `JdtUpdateDebugConfig`.

The jdtls workspace includes a Java-toolchain fingerprint. Updating jdtls or Java Debug automatically creates a fresh workspace so stale Eclipse extension registries cannot break Maven classpath resolution. `:JdtUpdateConfig` refreshes the imported Maven model after changing a `pom.xml` or profile.

Java Test debugging through `<leader>jt` and `<leader>jT` is temporarily disabled because the current Mason `java-test` bundle requires ASM `[9.9,9.10)`, while the installed jdtls provides ASM `9.10.1`. Spring application debugging is unaffected.
