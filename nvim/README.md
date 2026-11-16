# Neovim Java and Spring Cloud debugging

This configuration supports Java launch debugging for Maven multi-module Spring Cloud projects through the Overseer Services panel.

## Chinese Java properties and project search

Java `.properties` files containing printable Unicode escapes open as readable text. For example,
`name=\u4e2d\u6587` appears as `name=中文`, and `/中文` uses Neovim's normal search.
Saving retains the escaped file format, original spellings on unchanged lines, and existing line endings.
Files that already contain UTF-8 Chinese retain their format.

Cmd+Shift+F (or `<leader>fs`) searches decoded `.properties` contents through a ripgrep preprocessor.
The result list, preview, match highlights, and file jumps use the same decoded text and byte positions.
Literal/regex, case, whole-word, and file-mask controls continue to work. Other file types use normal ripgrep
search. The preprocessor uses the installed Neovim 0.12 executable and adds one small process per properties file.

Project search reads saved disk contents, so save edits before searching across files. Standalone `rg`
commands and other applications still see the original escaped text. To inspect a properties file's raw bytes
in Neovim, use `:edit! ++enc=utf-8` after saving any changes; reopen it normally to restore decoded editing.

Gitsigns is disabled for decoded properties buffers because its index and staging operations expect the raw
file representation. Use Lazygit or ordinary Git commands for those files.

## Prerequisites

- JDK 21 or newer to run jdtls and the Spring language server. If the active `JAVA_HOME` is Java 17, the configuration automatically discovers a Java 21+ JDK installed by SDKMAN and uses it for both language servers. Project runtimes and Maven/Spring Boot processes keep using the active Java 17. Set `NVIM_JAVA_HOME` to override the language-server JDK.
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

## Maven dashboard

Open a `pom.xml` or a source file in the Maven project, then use:

- `<leader>om` or `:Maven` to toggle the right-side Maven project panel.
- `<leader>op` or `:MavenProfiles` to select Maven build profiles.
- `<leader>ox` or `:MavenExec` to open the upstream Maven command picker.
- `<leader>of` or `:MavenFavorites` to open favorite Maven commands.
- `:MavenProfilesClear` to remove the selected Maven build profiles.

The Maven mappings resolve the project root from the active buffer before opening the upstream UI. `<leader>op` runs
`mvn help:all-profiles` for the current Maven project and stores selections in
`stdpath("state")/maven/profiles.json`. The selection is independent from the Services panel's Spring profile and
does not modify `pom.xml` or Maven settings. It adds `-P=<profiles>` to Lifecycle, plugin-goal, and custom-command
actions launched from the Maven project tree. The upstream `:MavenExec` and dependency metadata loaders do not use
these default arguments, so include `-P=<profiles>` manually in those commands when needed.

## Java startup and persistent state

Each repository reuses two directories under `stdpath("cache")/jdtls/`:

- `workspace/<project>-<root-hash>-<toolchain-hash>` stores Eclipse projects, imported build models, and Java indexes.
- `config/<project>-<root-hash>-<toolchain-hash>` stores the OSGi extension registry and framework configuration.

The existing workspace names are preserved. The separate `-configuration` directory prevents projects from inheriting
stale extension registrations from Mason's shared installation directory. Updating jdtls, Spring extensions, or Java
Debug changes the toolchain fingerprint and selects new directories. Ordinary restarts reuse both directories.
The first startup after this configuration change initializes the new OSGi directory.

JDK discovery reads each installation's `release` file instead of starting a JVM for every version check. Java and
Spring share a process-local cache that is invalidated when candidate paths, overrides, symlink targets, or JDK metadata
change. Metadata-less installations use `java -version` with a three-second timeout. Launcher preference is
`NVIM_JAVA_HOME`, then `JAVA_HOME_21`, then SDKMAN, then other Java environment variables; only Java 21+ is eligible.
Within one source, discovery prefers the lowest supported major version and its newest patch.

The explicit runtime list disables jdtls's duplicate VM installation scan. The Maven project cache is increased to
128, and both language servers receive a ten-second graceful shutdown timeout so they can save state before being
terminated. Automatic builds, dependency source downloads, Lombok, Spring support, and application debugging remain
enabled.

This timeout does not repair an indexer deadlock. During testing with the installed jdtls 1.60.0, shutting down
immediately after first-import diagnostics could leave Eclipse waiting for its indexing thread, eventually causing
forced termination. The benchmark also waits for a successful indexed workspace-symbol search before testing
shutdown; a working definition response alone does not mean initial indexing has finished.

Fully exit and reopen Neovim to load these Lua changes. `:JdtRestart` alone in an already-running session reuses its
loaded configuration. Existing caches are retained; if a workspace already reports corruption, use `<leader>lc` to
select and confirm rebuilding that workspace. Rebuilding indexes makes the following startup slower.

To measure the real installed Java and Spring servers against a disposable Maven project:

```sh
cd ~/.config/nvim
bench_dir="$(mktemp -d "${TMPDIR:-/tmp}/nvim-java-startup.XXXXXX")"
for run in 1 2 3; do
  XDG_CACHE_HOME="$bench_dir/cache" XDG_STATE_HOME="$bench_dir/state" \
    nvim --headless -u NONE -i NONE -l tests/jdtls_startup_bench.lua "$bench_dir"
done
```

The first run creates the benchmark's project, workspace, and OSGi configuration; subsequent runs reuse them.
`JDTLS_BENCH` reports milliseconds from setup to client attachment, `ServiceReady`, a successful cross-file definition
response, and an indexed workspace-symbol search, plus shutdown duration and exit codes. It also checks that Spring
and Java Debug extensions are available. Dependencies already present in the local Maven repository are shared.
This small fixture does not predict startup time for a large Spring multi-module repository, and `ServiceReady`
alone does not prove navigation is responsive.

On November 16, 2026, two fresh fixtures and three subsequent restarts passed these checks. Cold definition responses
ranged from 3.42 to 11.97 seconds; restarts ranged from 2.73 to 3.80 seconds, with clean Java/Spring exits in
0.48–1.06 seconds after indexed symbol search. These measurements include language-server setup, not a full editor
startup, and vary with system load. In a separate comparison against the previous runtime-discovery implementation,
two successive discovery calls took 846/490 ms before this change and 47/0.61 ms afterward.

## Useful commands

- `:Mason` checks whether Java tools are installed.
- `:LspInfo` checks whether jdtls is attached to the main-class source file.
- `:JdtRestart` restarts jdtls after installing or changing bundles.
- `<leader>jd` refreshes jdtls-discovered Java launch configurations.
- `<leader>dr` opens the DAP REPL.
- `<leader>os` stops all normal and debugging services.

If the panel reports that Java Debug was not loaded, run `:MasonToolsInstall`, restart Neovim, reopen a Java file, and verify that jdtls exposes `JdtUpdateDebugConfig`.

`:JdtUpdateConfig` refreshes the imported Maven model after changing a `pom.xml` or profile. Use it for build-model
changes instead of routinely deleting the persistent workspace.

Java Test debugging through `<leader>jt` and `<leader>jT` is temporarily disabled because the current Mason `java-test` bundle requires ASM `[9.9,9.10)`, while the installed jdtls provides ASM `9.10.1`. Spring application debugging is unaffected.
