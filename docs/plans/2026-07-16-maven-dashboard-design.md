# Maven Dashboard Design

## Goal

Add an independent Maven dashboard to the Neovim configuration without changing the existing Services runtime or its Spring Profile state.

The dashboard must provide the upstream Maven project tree for lifecycle phases, plugins, dependencies, modules, command output, and favorites. It must also provide a lightweight, project-scoped Maven Profile selector.

## Scope

- Install and configure `oclay1st/maven.nvim` through lazy.nvim.
- Open the Maven project tree on the right with `<leader>om`.
- Add `<leader>op` for Maven Profile selection, `<leader>ox` for the upstream execution UI, and `<leader>of` for favorite commands.
- Persist selected Maven Profiles separately from the existing Spring Profile service state.
- Resolve available profiles with `mvn help:all-profiles` asynchronously. Do not modify `pom.xml` or Maven settings.
- Apply selected profiles as `-P=<profile-list>` to upstream tree actions that use its default-arguments command builder.

## Non-Goals

- Do not fork or monkey-patch `maven.nvim`.
- Do not make the upstream dependency tree or `:MavenExec` inherit selected Profiles; those upstream paths bypass default arguments.
- Do not replace the existing Services panel, Spring Profile selection, Java LSP, or debug workflow.
- Do not implement Maven repository browsing in this iteration.

## Architecture

### Upstream Dashboard

`nvim/lua/plugins/panel/maven.lua` registers `oclay1st/maven.nvim` as a lazy plugin. The existing NUI dependency is reused. The configuration uses the installed `mvn` executable, a right-side project tree, project scanning, cached dependency/plugin data, and command-output windows.

`custom.maven_profiles` resolves the Maven root from the active buffer before opening the upstream dashboard, command picker, or favorites. It changes Neovim's working directory to that root because the upstream plugin does not expose an explicit working-directory option for all of its UI actions. Existing Services use explicit per-service working directories and are unaffected.

The configuration also limits `vim-rooter` to normal file buffers. Its default `nofile` handling would otherwise reset the working directory whenever an NUI Maven buffer mounts.

### Maven Profile Helper

`nvim/lua/custom/maven_profiles.lua` owns the Maven Profile state and UI:

- It finds the current Maven root from `mvnw`, `pom.xml`, or the current working directory.
- It runs `mvn --batch-mode --non-recursive --file <pom> help:all-profiles` through `vim.system()` and parses profile identifiers from Maven output.
- It presents a multi-select picker using the existing `fzf-lua` dependency.
- It writes one selected profile list per normalized project root to `stdpath("state")/maven/profiles.json` using atomic replacement.
- It updates the upstream plugin's enabled default arguments to one `-P=<comma-separated-profile-list>` argument. Clearing the selection removes that argument.

The state is intentionally separate from `services.state`, whose value represents `spring.profiles.active` for long-running Spring Boot services. Maven Profiles and Spring Profiles can have different names and semantics.

### User Interface

- `<leader>om`: toggle the Maven project tree.
- `<leader>op`: select one or more Maven Profiles for the current project.
- `<leader>ox`: open the upstream Maven command execution picker.
- `<leader>of`: open upstream Maven favorites.
- `:MavenProfiles` and `:MavenProfilesClear`: command-line equivalents for profile selection and reset.

The existing `<leader>oo`, `<leader>oa`, and `<leader>os` Service-panel mappings remain unchanged.

## Error Handling

- If the current project has no `pom.xml`, profile actions report a warning and make no state changes.
- If Maven cannot execute or `help:all-profiles` fails, the helper preserves the last selected state and displays stderr in the notification.
- If Maven returns no profiles, the picker reports that result rather than treating it as a failure.
- Profile selection changes only future Maven tree actions; it never rewrites Maven project files or globally changes Maven settings.

## Verification

- A focused headless spec tests Maven output parsing, project-scoped state persistence, profile argument injection, and missing-POM behavior without invoking Maven.
- A plugin-spec test verifies lazy triggers, NUI dependency reuse, configured right-side panel, and key-map definitions.
- Lazy synchronizes the plugin and updates `lazy-lock.json`.
- A headless full-config check validates that Maven commands and mappings load successfully.
