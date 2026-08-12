# Java Nearest Test Design

## Goal

Run the Java test method under the cursor with `<leader>jt`, including Maven
multi-module projects whose parent POM skips tests by default.

## Design

- Reuse `custom.task_runner` for test discovery and register Java tests with the
  services runtime for process execution, streamed output, and rerunning.
- Resolve the nearest Java method from the current buffer and build a fully
  qualified Surefire target such as
  `com.lenovo.moss.service.message.server.EmailUtilTest#testNormalEmail`.
- For Maven projects, find the reactor root and the nearest module POM. Run from
  the reactor root with `-pl <relative-module> -am` when the file belongs to a
  submodule.
- Add `-Dmoss.skipTests=false` so projects using the MOSS parent POM execute
  tests, and `-Dsurefire.failIfNoSpecifiedTests=false` so upstream reactor
  modules without the selected test do not fail.
- Keep the current class-level fallback when no method can be identified.
- Define `<leader>jt` globally so it works before JDTLS attaches. It calls
  `custom.task_runner.run("nearest")`; Java test debugging remains disabled.
- Open the services panel automatically, register a transient `test` service
  named after the class and method, and focus its streamed Maven output.

## Error Handling

- Preserve the existing warning when no Maven or Gradle build is found.
- If no child module can be derived, execute from the discovered project root
  without `-pl` or `-am`.
- Keep arguments as an argv list so paths and Surefire targets do not require
  shell escaping.

## Verification

- Add headless Lua tests for Maven reactor root/module detection and generated
  command arguments.
- Verify the existing task runner behavior for single-module Maven and Gradle
  projects remains unchanged.
- Run the relevant Neovim headless specs and a Lua syntax/load check.
