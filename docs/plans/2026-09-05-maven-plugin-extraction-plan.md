# Maven Plugin Extraction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. If unavailable, follow the explicit test-first checkpoints below. Do not commit or push without user authorization.

**Goal:** Consolidate the current Maven dashboard, project settings, reactor execution, and dependency analyzer into an enhanced fork at `/Users/yelog/workspace/vi/maven.nvim`, without depending on the user's Neovim configuration.

**Architecture:** Retain upstream Maven/NUI infrastructure and integrate local enhancements directly instead of installing runtime monkey patches. Carry an explicit project context through views, command construction, execution, and caches. Keep Services, Spring runtime policies, JDTLS, and personal key bindings in the consumer configuration.

**Tech Stack:** Lua, Neovim (proposed minimum 0.11, verify in CI), nui.nvim, Maven/Maven Wrapper, existing depgraph Maven plugin 4.0.2, headless Neovim tests.

---

## 1. Decision And Baseline

Suitable for extraction as an enhanced fork, not as a standalone copy of the five custom modules.

- Installed upstream: `oclay1st/maven.nvim`, commit `fc1ff4e36fe6b82886c8231e1d42060aa281419a`.
- Installed source: `/Users/yelog/.local/share/nvim/lazy/maven.nvim`; working tree was clean during inspection.
- Target directory exists, is empty, and is not a Git repository.
- Consumer configuration `/Users/yelog/.config` was clean before this planning document.
- Five custom modules total 1,463 lines; six focused Maven specs already exist.
- Upstream uses MIT licensing. Preserve its LICENSE, copyright notices, and vendored XML parser attribution. Review vendor headers before redistribution.
- This document does not clone, implement, change plugin loading, migrate user state, or publish anything.

### Alternatives

| Approach | Benefit | Cost / decision |
| --- | --- | --- |
| Enhanced upstream fork | Retains the full dashboard and execution infrastructure; removes private-method patches | Recommended; requires consciously maintaining an upstream delta |
| Extension depending on upstream | Smaller repository and automatic upstream fixes | Private UI/command interfaces remain brittle; use a distinct Lua namespace if chosen |
| Fresh implementation | Complete API control | Rebuilds scanner, XML, UI, console, queue, favorites and parsers unnecessarily |
| Upstream contributions only | Lowest long-term fork maintenance if accepted | Acceptance/timing unknown; submit generic fixes later, not a prerequisite |

Do not load the fork and upstream together: both provide `maven.*` and the same Ex commands. Directory naming does not isolate Lua modules.

## 2. Current Implementation And Evidence

Paths in this section are relative to `/Users/yelog/.config` unless marked upstream.

| Area | Existing source | Extraction treatment |
| --- | --- | --- |
| Lazy configuration | `nvim/lua/plugins/panel/maven.lua:1-22` | Replace upstream spec with local fork after standalone acceptance |
| Module hierarchy | `nvim/lua/custom/maven_project_tree.lua:73-151` | Keep rebuilding algorithm; integrate scanner and analysis mapping directly |
| Reactor lifecycle | `nvim/lua/custom/maven_reactor_execution.lua:9-51` | Replace implicit removal of `-N` with explicit recursion intent |
| Profiles, arguments, presets | `nvim/lua/custom/maven_profiles.lua:1-626` | Separate persistent state and root discovery from UI; remove Lazy loading logic |
| Dependency graph model | `nvim/lua/custom/maven_dependency_model.lua:1-133` | Move to `maven.dependencies.model`; retain occurrence-based paths |
| Analyzer UI | `nvim/lua/custom/maven_dependency_analyzer.lua:1-398` | Move to `maven.ui.dependency_analyzer`; preserve interaction and styling |
| Startup and keys | `nvim/init.lua:57-58`, `nvim/lua/key-map.lua:422-429` | Register commands inside plugin; keep leader mappings consumer-owned |
| Services integration | `nvim/lua/services/state.lua:92-103`, `nvim/lua/services/panel.lua:712-741` | Consume public profile API; do not move Services into plugin |
| Java task root lookup | `nvim/lua/custom/task_runner.lua:63-75` | Consume public project API; retain test execution policy locally |

Upstream references below are relative to `/Users/yelog/.local/share/nvim/lazy/maven.nvim`.

### Correctness Gates

1. **Profile changes destroy sibling settings.** `custom/maven_profiles.lua:219-232` replaces the entire project record, or deletes it when clearing. This loses arguments and command presets saved by other setters. Fix before migrating state.
2. **Dependency resolution ignores selected build settings.** Upstream `lua/maven/utils/cmd_builder.lua:50-67` constructs graph arguments separately and does not include `default_arguments_view.arguments`. Effective-POM loading at lines 73-84 has the same separation. Direct builder inspection confirmed lifecycle arguments include `-P=dev` and `-Drevision=1.2.3`, while dependency arguments include neither.
3. **Caches lack build-context invalidation.** Upstream `lua/maven/sources/init.lua:156-180` and `lua/maven/parsers/projects_cache_parser.lua:24-42` use POM-path registration without comparing profiles, properties, settings, or POM contents. Cached results can survive changes that alter dependency resolution.
4. **Global mutable project context.** `custom/maven_profiles.lua:350-372` updates shared configuration and invokes global `:cd`. Upstream `lua/maven/init.lua:24-42` retains a singleton projects view. Multiple roots/tabs and delayed argument persistence can use the wrong project context.
5. **Shell quoting inside argv.** Upstream `lua/maven/utils/cmd_builder.lua:13-25` emits literal quote characters around POM paths; `lua/maven/utils/queue.lua:79` invokes `vim.system` directly. Shell-free argv must not contain shell quoting. Confirm with a fake executable and a real Maven fixture before release.
6. **Incomplete profile discovery.** `custom/maven_profiles.lua:415-427` returns immediately if profiles exist in the root POM, so it does not discover additional parent/settings profiles. Keep local parsing as a labeled fast result, not as authoritative effective discovery.
7. **Dependency statistics are occurrence counts.** `custom/maven_dependency_model.lua:90-97` includes duplicate/omitted occurrences in resolved count and total bytes. Coordinate grouping currently uses only groupId/artifactId. Distinguish occurrences, unique selected artifacts, conflicts, and known bytes; do not imply exact package footprint.
8. **Asynchronous UI lifetime is implicit.** `custom/maven_dependency_analyzer.lua:362-388` allows older requests to replace a newer view; input callbacks may render after close. Add request identity and mounted-window checks.
9. **Module cycle protection runs too late.** The local rebuild handles cycles in an already collected graph, but upstream `sources/init.lua:63-78` recursively visits a child before recording it as scanned. Protect discovery before recursion, not only tree reconstruction. Static POM parsing also omits profile-activated modules.
10. **Runtime patches are not a plugin API.** Patches replace scan callbacks, `_setup_win_maps`, `_load_lifecycle_node`, arguments-view mount, and temporarily the dependency command builder. At the inspected revision the dependency builder runs synchronously before queueing, so remote refresh is not proven broken today; the contract is nevertheless fragile.

### Boundaries To Preserve

- Maven profiles and Spring runtime profiles are different concepts. Existing Services intentionally maps its chosen value to a Maven profile for tests, and also uses it for service startup. Keep that explicit application policy outside the plugin.
- Preserve the current consumer's primary-profile behavior during extraction; do not silently choose a new Spring profile policy or change multi-profile test behavior.
- No automatic edits to POM dependencies, exclusions, BOMs, or versions in v0.1. The current feature is analysis/navigation, not dependency rewriting.
- No JDTLS restart/reimport, DAP, MyBatis, Overseer, fzf-lua, Kitty, or personal test flags in core.
- Keep existing NUI look and buffer-local interactions; this is not a UI redesign.

## 3. Target Structure And Contracts

All plugin-relative paths below use `/Users/yelog/workspace/vi/maven.nvim`.

```text
plugin/maven.lua                    existing command entry points, extended
lua/maven/init.lua                 setup and user-facing operations
lua/maven/config/init.lua          defaults and option validation
lua/maven/project.lua              root/module context and normalization
lua/maven/state.lua                project settings persistence
lua/maven/profiles.lua             discovery, selection, public profile API
lua/maven/project_tree.lua         tested hierarchy rebuild
lua/maven/dependencies/model.lua   occurrence graph and summaries
lua/maven/ui/dependency_analyzer.lua
lua/maven/ui/profiles_view.lua     default NUI multi-select picker
lua/maven/health.lua
lua/maven/sources/                 retain and adapt upstream sources
lua/maven/parsers/                 retain and harden upstream parsers
lua/maven/utils/                   retain command builder, console and queue
doc/maven.txt
tests/minimal_init.lua
tests/run.lua
tests/fixtures/
.github/workflows/test.yml
```

Avoid new generic provider frameworks, event buses, or task runtimes. Add small modules only for the boundaries above; keep command building in the existing builder and process scheduling in the existing queue.

Proposed public surface, finalized by tests before consumer migration:

```lua
require("maven").setup(opts)
require("maven").open({ root = root })
require("maven").dependencies({ pom = pom_path, refresh = false, update_snapshots = false })
require("maven.project").find_root(path)
require("maven.project").find_nearest_pom(path)
require("maven.profiles").get(root)
require("maven.profiles").set(root, profiles)
require("maven.profiles").list_available(root, callback)
```

- Context is a per-request snapshot containing root, exact POM, executable, cwd, selected profiles, and effective argument list. Do not store current-project settings in process-global defaults.
- Configuration defaults are immutable templates; project overrides and one-off operation options are merged with documented precedence.
- `refresh=true` bypasses graph cache only. `update_snapshots=true` implies refresh and adds `-U` only for that request.
- Retain current Ex commands: Maven, MavenExec, MavenInit, MavenFavorites, MavenProfiles, MavenProfilesClear, MavenPresetAdd, MavenPresetRemove, MavenDependencies. Audit other upstream commands before modifying registration.
- Expose profile data without requiring NUI or opening the dashboard. Lazy-loading is configured by the consumer, never by core calling `require("lazy")`.
- fzf-lua is optional via a picker callback/adapter. NUI provides a real multi-select fallback; a single `vim.ui.select` is not an equivalent replacement.
- Proposed minimum is Neovim 0.11 because the custom implementation uses modern `vim.fs` APIs; current local verification is on 0.12.4 only. Declare minimum after CI proves it.

## 4. Ordered Implementation Tasks

For every task: first add the stated regression, run the targeted spec and observe the expected failure, implement the smallest complete change, then rerun it and the established suite. Do not batch all tests until the end. Commit checkpoints are suggestions only; no automatic commits or pushes.

### Task 1: Establish A Reproducible Fork And Test Harness

**Files:** Preserve upstream sources, LICENSE, vendor notices; create `tests/minimal_init.lua`, `tests/run.lua`, `tests/fixtures/`, and provenance notes in README.

1. Recheck the target directory is empty and inspect upstream status before cloning. If files appeared, do not overwrite them.
2. Clone the upstream repository into the target after implementation is authorized; create the implementation branch from the inspected commit. Do not silently upgrade to upstream HEAD. Preserve history and record the baseline SHA.
3. Audit the vendor XML files' attribution and license headers; retain required notices.
4. Port the six Maven specs first, changing only module paths and test bootstrap where possible. Remove the hard-coded personal NUI path from analyzer tests; use `MAVEN_NUI_PATH` in the isolated harness.
5. Implement a runner that executes specs in separate Neovim processes, propagates nonzero failures, and isolates XDG state/cache/data. Do not let stubs leak between tests.
6. Establish `nvim --headless -u NONE -l tests/run.lua` as the full-suite command. Expected: all ported baseline specs pass without loading the user's init.lua.

**Gate:** Provenance is recorded, only one maven implementation is on runtimepath, and no tests read or modify real Maven state.

### Task 2: Extract And Fix Persistent Project State

**Files:** Create `lua/maven/state.lua`, `tests/state_spec.lua`; extract persistence from `custom/maven_profiles.lua:18-123,206-271`.

1. Add a regression that saves arguments and presets, selects profiles, clears profiles, and verifies arguments/presets still exist. It must fail against current setter semantics.
2. Update only the `profiles` field; delete a project record only if all meaningful fields are empty.
3. Retain atomic sibling-temp-file replacement. Add schema validation, actionable errors, and a schema version for new writes.
4. Read the existing `stdpath("state")/maven/profiles.json` format. Do not silently treat corrupt state as writable empty state; preserve the original and report the failure.
5. Define missing override versus explicitly empty override, so saved empty arguments can intentionally override defaults.
6. Serialize read-modify-write operations using a short-lived lock with bounded timeout; test two independent writers. Atomic rename alone does not prevent lost updates.
7. Run `nvim --headless -u NONE -l tests/state_spec.lua` and the full suite.

**Gate:** Existing selections, presets, and arguments survive upgrade and rollback. No sensitive values are printed by tests or diagnostics.

### Task 3: Make Project Context Explicit

**Files:** Create `lua/maven/project.lua`, `tests/project_spec.lua`; modify `lua/maven/init.lua`, `lua/maven/ui/arguments_view.lua`, `lua/maven/ui/execution_view.lua`, `lua/maven/ui/favorites_view.lua`.

1. Add fixtures for a single POM, nested reactor, repository with several Maven roots, no Git, wrapper in an ancestor, and paths with spaces.
2. Distinguish nearest module POM, reactor root, and scan workspace. Git is a hint, not proof of a Maven reactor relationship. Permit an explicit root override.
3. Capture context when opening a view and submitting a task. Pass its root to argument/preset persistence even if the user changes buffer/tab/cwd before completion.
4. Remove global `:cd` and DirChanged-based mutable-default synchronization. Preserve editor cwd, window-local cwd, and tab-local cwd.
5. Use one active Maven workspace view that is recreated when its requested root changes; do not introduce a many-workspace view registry unless tests demonstrate a need.
6. Verify an A-root command queued before switching to B still executes with A's cwd and settings.
7. Run `nvim --headless -u NONE -l tests/project_spec.lua` and targeted view tests.

**Gate:** Root selection and delayed work are deterministic without changing unrelated editor state.

### Task 4: Unify Command Construction And Execution

**Files:** Modify `lua/maven/utils/cmd_builder.lua`, `lua/maven/utils/console.lua`, `lua/maven/utils/queue.lua`, command callers in `sources/init.lua` and `ui/`; create `tests/command_spec.lua`, `tests/queue_spec.lua`, fake executable fixtures.

1. Add failing argv-capture tests for spaces, quotes, multiple profiles, property values containing spaces, settings files, custom repositories, and Wrapper selection.
2. Emit argv elements such as `{ "--file", pom_path }` without embedded shell quotes. Use the existing shell-free process runner consistently.
3. Share profile, settings, and property context between lifecycle, graph, effective-POM, and profile discovery commands; do not blindly append unrelated lifecycle goals to metadata queries.
4. Define executable precedence: explicit configured executable, otherwise project Wrapper when usable, otherwise system Maven. Bind relative Wrapper execution to its root cwd. Test Windows command-file handling before claiming Windows support.
5. Pass explicit cwd to all scheduled jobs. Separate default arguments, project overrides, and per-call flags with documented precedence; never concatenate shell commands for argument presets.
6. Audit every builder caller after removing quoting. Preserve upstream create/init/favorites functionality, not just the new analyzer.
7. Add process-spawn failure, nonzero exit, cancellation, queued cancellation, and callback-exactly-once tests. Correct queue handle ownership if cancellation cannot reach its process. Schedule UI updates on the main loop and redact sensitive command arguments in logs.
8. Run `nvim --headless -u NONE -l tests/command_spec.lua` and `nvim --headless -u NONE -l tests/queue_spec.lua`.

**Gate:** Actual captured argv, not only mocked builders, proves correct token boundaries and project isolation.

### Task 5: Integrate Module Hierarchy And Reactor Execution

**Files:** Create `lua/maven/project_tree.lua`; modify `lua/maven/sources/init.lua`, `lua/maven/parsers/pom_xml_parser.lua`, `lua/maven/ui/projects_view.lua`; migrate tree/reactor specs.

1. Move `rebuild` without runtime wrapping. Call it from the real scanner completion path.
2. Mark normalized POM paths as visiting before recursive discovery; warn on cycles, missing files, invalid XML, and ambiguous aggregator ownership.
3. Test actual scanner + parser with `../module`, explicit `module/pom.xml`, nested aggregation, duplicate references, and cyclic references. Existing mocked rebuild tests alone are insufficient.
4. Model lifecycle recursion as an explicit command option. Aggregator lifecycle invokes Maven recursively; metadata queries stay nonrecursive. Do not infer Maven semantics solely from a display tree emptied by scanning limits.
5. Add selected-project analysis directly to the projects-view mapping, preserving `a` and the exact selected module POM.
6. For v0.1 distinguish declared modules from effective profile-enabled modules. Use Maven-derived metadata where required; do not silently present a static tree as the full active reactor. Full effective-tree expansion can follow later if the limitation is visible and documented.
7. Run migrated project-tree/reactor specs plus a real multi-module lifecycle fixture.

**Gate:** No monkey patches remain for scanner, project mappings, or lifecycle execution; Maven handles reactor ordering.

### Task 6: Extract Profile Discovery And UI

**Files:** Create `lua/maven/profiles.lua`, `lua/maven/ui/profiles_view.lua`, `tests/profiles_spec.lua`; modify command registration and configuration defaults.

1. Keep profile get/set/list operations independent of UI imports and plugin managers.
2. Present local POM profiles immediately if desired, but label that set incomplete until `help:all-profiles` resolves under the same settings/executable context. Include inherited and settings profiles in authoritative results.
3. Add fixtures for local, parent, settings-only, activeByDefault, offline failure, malformed XML, and nonzero Maven exit.
4. Provide NUI multi-selection plus clear/cancel; support an optional picker callback so the consumer can retain fzf-lua without a hard dependency.
5. Register commands idempotently. Preserve enabled flags, preset ordering, and explicit empty overrides; use proper Ex argument handling for quoted preset values rather than raw whitespace splitting.
6. Keep profile selection separate from Maven's effective automatic activation; no selection means no explicit `-P`, not 'all profiles disabled'.
7. Run `nvim --headless -u NONE -l tests/profiles_spec.lua` and picker UI tests without fzf-lua installed.

**Gate:** A clean Neovim + NUI installation can manage profiles and presets; no Lazy or Services require is needed.

### Task 7: Make Dependency Data And Cache Trustworthy

**Files:** Create `lua/maven/dependencies/model.lua`, `tests/dependency_model_spec.lua`, `tests/dependency_source_spec.lua`, `tests/dependency_cache_spec.lua`; modify existing dependency parser, cache parsers, sources and artifact-path utilities.

1. Move the model and retain occurrence IDs, parent links, all-path search, ancestor visibility, and stable sibling sorting.
2. Validate malformed/dangling/cyclic data at the parser/model boundary; return structured errors instead of uncontrolled recursion or assertions in UI callbacks.
3. Separate occurrence count from unique selected-artifact count and unique known bytes. Preserve omitted/requested versus selected version information; use stronger artifact identity where the backend supplies type/classifier. Label unsupported distinctions rather than inventing metadata.
4. Resolve the local repository from effective Maven configuration/explicit override, not only `~/.m2/repository`. Missing sizes remain unknown, not falsely zero-byte artifacts.
5. Add a dedicated versioned dependency cache fingerprint: POM identity/content, selected profiles, relevant ordered args, settings identity/content, parent inputs known to affect the build, `.mvn/maven.config`, executable/backend identity. Do not change the favorites key space merely to fix dependency caches.
6. Invalidate conservatively when effective inputs cannot be determined. Use a bounded TTL for external/SNAPSHOT/environment changes; do not claim that local hashes model all repository changes. Explicit refresh must always bypass cache.
7. Add per-context in-flight request identity. Cache empty successful graphs; do not cache failures as success. Clean temporary graph files on every terminal outcome.
8. Replace temporary builder mutation with an explicit update-snapshots option. Test normal refresh without `-U`, remote refresh with `-U`, and no flag leakage to another request.
9. Use real captured depgraph 4.0.2 fixtures for duplicate/conflict semantics. Do not swap to another Maven graph backend in this extraction.
10. Run the three targeted specs and a gated real Maven integration fixture.

**Gate:** Changing a profile or relevant property cannot reuse another context's graph. The displayed version/conflict and size semantics match documented backend evidence.

### Task 8: Migrate Analyzer And Harden UI Lifetime

**Files:** Create `lua/maven/ui/dependency_analyzer.lua`, `tests/dependency_analyzer_spec.lua`; extend `lua/maven/config/init.lua` and highlights.

1. Move the existing view preserving tree/list/conflict modes, search ancestor expansion, scope toggle, group/size toggles, sorting, details, path popup, and selected-module refresh.
2. Route toolbar/keymaps through explicit source options. Ignore stale asynchronous results and callbacks after close. Refresh without resetting user filters/focus/expansion unnecessarily.
3. Represent loading, empty success, filtered-empty, failure, and cancellation separately. Preserve the previous valid graph on refresh failure and label it stale.
4. Make window size and buffer-local keys configurable; clamp on small terminals and handle resize. Reapply default highlights on ColorScheme without overriding user-defined groups.
5. Harden POM navigation using groupId/artifactId and dependency context; distinguish direct declaration, dependencyManagement, profile, inherited declaration, and transitive occurrence. Notify when precise origin is not available rather than jumping to an unrelated artifactId.
6. Run the migrated real-NUI UI test plus races: open A then B, refresh twice in reversed completion order, close before callback, cancel input, wipe popup buffer, resize, switch colorscheme.

**Gate:** The view has the current useful interaction without lifecycle errors or misleading navigation.

### Task 9: Documentation, Health And Standalone Acceptance

**Files:** Update README; create `doc/maven.txt`, `lua/maven/health.lua`, `.github/workflows/test.yml`, standalone smoke fixtures.

1. Document fork provenance, public API, settings precedence, graph backend, profile semantics, cache limitations, refresh semantics, migration and known platform limits.
2. Add `:checkhealth maven` for Neovim version, NUI, Java, Maven/Wrapper, writable state/cache, optional unzip, and conflicting runtimepath providers. Do not access remote repositories or expose settings credentials in health checks.
3. Run fast mocked/fake-process tests offline on the declared minimum and current stable Neovim; use pinned NUI in CI.
4. Add a separate gated real-Maven lane for multi-module, profile-dependent dependency graphs and conflict fixtures. Record Maven/Java/backend versions. Network-dependent tests must be explicit, not a surprise in unit tests.
5. Smoke test with `nvim --clean --cmd 'set rtp+=/Users/yelog/workspace/vi/maven.nvim' --cmd 'set rtp+=/Users/yelog/.local/share/nvim/lazy/nui.nvim' -c 'lua require("maven").setup({})' -c 'checkhealth maven'` from a disposable fixture workspace.
6. Manually verify legacy Maven/MavenExec/MavenInit/MavenFavorites flows, not just analyzer commands. No global leader mappings should be installed.

**Gate:** Standalone operation is demonstrated without `/Users/yelog/.config/nvim/lua` on runtimepath. macOS/Linux support is claimed only after validation; Windows remains unverified unless its lane passes.

### Task 10: Switch Consumer Configuration And Retire Adapters

**Files:** Modify `/Users/yelog/.config/nvim/lua/plugins/panel/maven.lua`, `nvim/init.lua`, `nvim/lua/key-map.lua`, `nvim/lua/services/state.lua`, `nvim/lua/services/panel.lua`, `nvim/lua/custom/task_runner.lua`, related specs, and `nvim/lazy-lock.json` only if changed by the intended manager operation.

1. Back up the old state file before the first new-format write and record the previous clean config revision/upstream SHA. Never print state contents.
2. Replace, rather than add alongside, the existing plugin spec with local `dir = "/Users/yelog/workspace/vi/maven.nvim"`, `name = "maven.nvim"`, NUI dependency, existing visual opts, and all old/new lazy command triggers.
3. Remove the two eager custom setup calls from init.lua. Ensure profile API calls by Services before a dashboard command still load correctly under Lazy; add a first-use Services test.
4. Switch leader mappings to documented public operations, retaining the user's keys and fzf adapter if desired.
5. Switch Services profile reads/writes and task-runner root lookup to public APIs. Keep primary-profile selection and runtime restart policy locally; remove obsolete `apply_current` calls rather than recreating global state injection.
6. Test Services profile selection, start/restart, current/nearest Java tests, and rerun behavior. Do not move `-Dmoss.skipTests=false` or Spring-specific behavior into Maven core.
7. Only after reference checks and both suites pass, delete the five local custom Maven modules. Keep configuration integration tests; retire duplicate core tests only once their plugin replacements exist.
8. Run `nvim --headless -u NONE -l tests/maven_plugin_spec.lua`, `nvim --headless -u NONE -l tests/services_state_catalog_spec.lua`, and `nvim --headless -u NONE -l tests/task_runner_spec.lua` from `/Users/yelog/.config/nvim`. Account explicitly for the pre-existing task-runner baseline failure below.

**Gate:** All known callers use supported APIs, user settings survive, only the fork is loaded, and configuration contains no Maven domain implementation.

## 5. Rollout And Rollback

1. Keep current upstream configuration active during Tasks 1-9. Test the fork in clean, separate Neovim processes; never hot-swap Lua providers in one running editor.
2. Mark the standalone candidate ready only after state/context/command/cache gates pass. A mechanical extraction with known data-loss behavior is not release-ready.
3. During Task 10 keep a reviewed migration patch and state backup. A rollback means reapplying the previous plugin spec and adapter files through a scoped reviewed change, not a destructive repository reset.
4. Restart Neovim on provider switch. Restore only the affected state backup if new state is incompatible; preserve changes made after backup for manual reconciliation.
5. Dependency caches are disposable; legacy favorites and project settings are not. Do not remove all of `stdpath("data")/maven` as a cache reset.
6. Observe ordinary usage across several projects before publishing. Publishing, upstream PRs, and Git remotes/pushes require a separate explicit request.

## 6. Validation Performed During Planning

Environment: Neovim 0.12.4, macOS. The following commands were actually run from `/Users/yelog/.config/nvim`:

| Command | Result |
| --- | --- |
| `nvim --headless -u NONE -l tests/maven_profiles_spec.lua` | PASS |
| `nvim --headless -u NONE -l tests/maven_dependency_model_spec.lua` | PASS |
| `nvim --headless -u NONE -l tests/maven_dependency_analyzer_spec.lua` | PASS, installed NUI with mocked Maven source |
| `nvim --headless -u NONE -l tests/maven_project_tree_spec.lua` | PASS |
| `nvim --headless -u NONE -l tests/maven_reactor_execution_spec.lua` | PASS |
| `nvim --headless -u NONE -l tests/maven_plugin_spec.lua` | PASS |
| `nvim --headless -u NONE -l tests/services_state_catalog_spec.lua` | PASS |
| `nvim --headless -u NONE -l tests/task_runner_spec.lua` | FAIL at line 213: expected `zsh`, actual `busted`, for all-config-spec task selection |

The task-runner failure predates any implementation in this plan and is outside the Maven extraction scope; do not claim a green full consumer suite until it is resolved or explicitly tracked as an accepted baseline.

Direct headless inspection of the installed upstream command builder also confirmed missing profile/property arguments on dependency resolution and literal quote characters in the generated POM argv element. No real Maven build, network dependency resolution, Windows/Linux run, or minimum-version Neovim run was performed during planning.

Neovim documentation was checked for shell-free `vim.system` argv semantics, scheduling asynchronous UI callbacks, and plugin `health.lua` discovery. Documentation reference: https://neovim.io/doc/user/lua.html and https://neovim.io/doc/user/health.html.

## 7. Effort And Scope Control

Indicative focused engineering time, not a delivery guarantee:

- Baseline fork, test harness, direct migration: 1-2 days.
- State/context/commands/profiles/scanner correctness: 2-4 days.
- Cache/data semantics, UI lifetime, real-Maven fixtures: 2-4 days.
- Docs/health/CI and consumer migration: 1-2 days.
- Total: approximately 6-12 focused days for a maintainable first release; full Windows support, effective-reactor modeling, dependency editing and broader backend support are additional scope.

The critical path is state -> context -> commands -> trustworthy dependency source/cache -> standalone acceptance -> consumer switch. Do not parallelize edits to those shared interfaces before their contracts settle. Documentation and independent fixture preparation can proceed separately once boundaries are fixed.
