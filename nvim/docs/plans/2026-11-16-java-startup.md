# Java Startup Implementation Plan

**Goal:** Reuse healthy Java project state and reduce repeated startup work without removing Java, Spring, Lombok, or debugging features.

**Architecture:** Keep existing project workspace identities. Give each workspace its own toolchain-specific OSGi configuration directory, share validated JDK discovery between the Java and Spring clients, and allow time for graceful server shutdown.

**Tech Stack:** Neovim 0.12, Lua, nvim-jdtls, Eclipse JDT LS 1.60, spring-boot.nvim, SDKMAN JDKs.

## 1. Validate runtime discovery

- Extend `tests/java_runtime_spec.lua` with release-file parsing, patch-version selection, symlink deduplication, environment changes, and cache isolation.
- Read JDK release metadata before falling back to a bounded `java -version` subprocess.
- Cache discovery against canonical candidate paths and executable/release metadata.
- Preserve explicit launcher overrides and project Java runtimes.
- Run `nvim --headless -u NONE -i NONE -l tests/java_runtime_spec.lua`.

## 2. Isolate server configuration

- Update `lua/plugins/lsp/jdtls.lua` to pass `-configuration` under `stdpath("cache")/jdtls/config/`.
- Keep existing `-data` paths and toolchain fingerprints unchanged.
- Set `exit_timeout = 10000`, disable duplicate server-side JVM detection, and increase the Maven model cache to 128.
- Add a behavioral configuration regression test covering repeated Java buffers, separate projects, launcher selection, and preserved bundles/settings.

## 3. Verify and document

- Run Java runtime, configuration, workspace cleaner, topology, debug, and Spring navigation tests.
- Measure first and repeated JDK discovery in the real installation.
- Start the real Java/Spring servers against a disposable Java project, check semantic navigation, and measure repeated startup and shutdown.
- Document configuration locations, launcher selection, activation, and measurement limits in `README.md`.
- Leave experimental shared indexes, AppCDS, persistent processes, and automatic cache deletion for separate measured changes.

Execution stays in the current checkout. Existing unrelated changes are preserved. No commits or branches are created.

## Completed verification

- All three implementation stages are complete.
- Seven Java/Spring regression scripts passed, including runtime discovery, startup configuration, workspace cleanup,
  LSP topology, debugging, property navigation, and properties handling.
- Runtime discovery used the original implementation from Git for comparison: first/repeated calls were
  846.52/489.54 ms before and 47.16/0.61 ms after the change. The selected launcher is Corretto 21.0.10;
  the Java 17 project runtime remains available.
- Two isolated real-server fixtures completed five successful runs. Warm definition responses were
  3.80, 3.22, and 2.73 seconds; cold responses were 11.97 and 3.42 seconds.
- Both real language servers exited with code/signal 0 in 0.48–1.06 seconds after diagnostics and indexed symbol search.
  Spring and Java Debug extension commands were available, and the new workspaces had no disabled Java Test bundles
  or `ObjectNotFoundException`.
- Earlier immediate-exit cold runs exposed a JDT indexing-thread shutdown block. The benchmark now explicitly checks
  indexed symbol search before shutdown; the ten-second production timeout is a bound, not a fix for upstream deadlocks.
- Large existing Spring repositories were not opened by the benchmark. Their actual restart latency still needs to be
  observed during normal use; existing workspaces and shared Mason configuration were retained.
