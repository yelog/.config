# Neovim Java and Spring Cloud debugging

This configuration supports Java launch debugging for Maven multi-module Spring Cloud projects through the Overseer Services panel.

## Chinese Java properties and project search

Java `.properties` files containing printable Unicode escapes open as readable text. For example,
`name=\u4e2d\u6587` appears as `name=中文`, and `/中文` uses Neovim's normal search.
Saving retains the escaped file format, original spellings on unchanged lines, and existing line endings.
Decoded buffers use the detected encoding and line endings even in a project with EditorConfig defaults.
Files that already contain UTF-8 Chinese retain their format.

Cmd+Shift+F (or `<leader>fs`) searches decoded `.properties` contents through a ripgrep preprocessor.
The result list, preview, match highlights, and file jumps use the same decoded text and byte positions.
Literal/regex, case, whole-word, and file-mask controls continue to work. Other file types use normal ripgrep
search. The preprocessor uses the installed Neovim 0.12 executable and adds one small process per properties file.

Project search reads saved disk contents, so save edits before searching across files. Standalone `rg`
commands and other applications still see the original escaped text. To inspect a properties file's raw bytes
in Neovim, use `:edit! ++enc=utf-8` after saving any changes; reopen it normally to restore decoded editing.

IGit uses the same escaping as the properties writer for hunk signs, change counts and blame.
Unsaved Chinese edits appear on the affected lines. To stage or restore a decoded file, use Git
on its saved contents.

## Prerequisites

- JDK 25 or newer to run jdtls and the Spring language server. Discovery uses an installed SDKMAN JDK automatically, including `25.0.2-amzn` on this machine. Set `NVIM_JAVA_HOME` or `JAVA_HOME_25` to select another compatible language-server JDK. An incompatible `NVIM_JAVA_HOME` produces an explicit error and prevents either server from launching on the project's JVM.
- Keep `JAVA_HOME` on the project's existing JDK. It remains the default project runtime in `java.configuration.runtimes`; Maven and Spring Boot service processes inherit the original environment. Maven/Gradle compiler settings and version-specific project runtimes remain independent of the language-server JVM.
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

The service whose log is displayed has a persistent highlighted row and a `▸` marker, including when
keyboard focus moves into the log. The log header repeats its name and status/ready port, with
`[FOLLOW]`, `[PAUSED - … new - G tail]`, or `[TERMINAL]` at the right. Narrow panes prioritize the service
name over secondary details. Reopening the panel restores the previous service; the first opening
displays the first available service.

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
`NVIM_JAVA_HOME`, then `JAVA_HOME_25`, then SDKMAN, then other Java environment variables; only Java 25+ is eligible.
Within one source, discovery prefers the lowest supported major version and its newest patch.

The validated `JAVA_HOME` is the default project runtime, including its exact installation when the language server
uses another patch of the same major version. When no valid `JAVA_HOME` is available, the launcher is the fallback
default for projects without build-tool settings. Discovery never changes the editor's global `JAVA_HOME` or `PATH`.
Java 8/11/17/21 installations remain available for version-specific project settings.

Project settings are sent during JDTLS initialization so the server configures project VMs before importing projects
and loading Java Debug/Spring extensions. The explicit runtime list disables jdtls's duplicate VM installation scan.
The Maven project cache is increased to 128, and both language servers receive a ten-second graceful shutdown timeout so they can save state before being
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

Install JDK 17 and JDK 25+ before running this Java 17 fixture. The first run creates the benchmark's project, workspace,
and OSGi configuration; subsequent runs reuse them.
`JDTLS_BENCH` reports milliseconds from setup to client attachment, `ServiceReady`, a successful cross-file definition
response, and an indexed workspace-symbol search, plus shutdown duration and exit codes. It also checks that Spring
and Java Debug extensions are available, semantic tokens distinguish variables/parameters/fields/classes/methods,
and the imported project retains Java 17 source/target/compliance and its JDK while the server runs on Java 25+.
Dependencies already present in the local Maven repository are shared.
This small fixture does not predict startup time for a large Spring multi-module repository, and `ServiceReady`
alone does not prove navigation is responsive.

On November 16, 2026, two fresh fixtures and three subsequent restarts passed these checks. Cold definition responses
ranged from 3.42 to 11.97 seconds; restarts ranged from 2.73 to 3.80 seconds, with clean Java/Spring exits in
0.48–1.06 seconds after indexed symbol search. These measurements include language-server setup, not a full editor
startup, and vary with system load. In a separate comparison against the previous runtime-discovery implementation,
two successive discovery calls took 846/490 ms before this change and 47/0.61 ms afterward.

After the Java 25 launcher update on the same date, JDTLS 1.63.0 completed cold/warm definition checks in 4.71/2.49
seconds, with clean Java/Spring shutdowns in 0.39/0.90 seconds. Both runs returned 17 semantic tokens, retained the
Java 17 project JDK and compiler settings, and exposed Spring and Java Debug commands. The warm run also used
Java 17 as the parent process's `JAVA_HOME`.

## Java highlighting

The JB theme distinguishes Java symbol roles in both dark and light backgrounds:

| Role | Color |
| --- | --- |
| Local variables | Existing theme gray |
| Parameters | Muted warm yellow |
| Instance/static fields and constants | Existing theme purple |
| Classes, interfaces, enums, type parameters | Teal |
| Method declarations | Blue |
| Method calls | Lighter blue |

Java-specific Tree-sitter and semantic groups share these roles. Static/final modifier styling is retained, and
switching back to JB reapplies the overrides. Global groups and other languages keep their theme colors.

JDTLS reference counts render at the end of the declaration line instead of above it. The counts refresh after
leaving Insert mode, saving, switching buffers, and when the language server requests a CodeLens refresh. The
built-in Neovim virtual-line renderer remains in use for other file types.

Tree-sitter supplies the initial syntax colors. JDTLS semantic tokens distinguish bare field references from local
variables and apply parameter colors to usages after the language server attaches. A gray field usage together
with a purple declaration can therefore indicate a missing JDTLS client rather than a terminal color issue.
Use `:LspInfo` to check attachment and `:Inspect` on the symbol to inspect its captures and semantic groups.

Tree-sitter checks already-loaded buffers, filetype detection, and buffer entry. Startup parser installation runs
asynchronously and retries failed buffers when its task finishes. Missing parsers or invalid highlight/injection
queries remain retryable; persistent failures report the language, original error, and `:TSUpdate <language>` /
`:TSLog` commands once per distinct error. Re-entering a buffer retries activation without restarting a working
highlighter. Terminal, prompt, and other special buffers are skipped. SCSS and mapped filetypes use the installed
language list, and repeated setup replaces its autocmds.

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
