# Independent Services Runtime Design

## Goal

Replace the Services panel's use of Overseer task execution with a service-specific runtime. Keep Overseer installed for possible future generic tasks, but do not create Overseer tasks for long-running Spring Boot, npm, or custom services.

The new runtime must provide responsive, searchable logs that retain ANSI colors for normal services, project-scoped service selection and Spring profiles, lifecycle controls, readiness detection, and Java Debug integration.

## Scope

- Managed services are long-running Spring Boot, npm, and user-defined commands.
- The existing `<leader>oo` entry point remains the Services toggle.
- The current persisted project profile and selected-service JSON schema remain valid. The state file stays at `stdpath("state")/overseer/spring-services.json` to preserve existing user data.
- Overseer remains available for non-service tasks but has no ownership of service processes, service buffers, or the Services UI.
- Java Debug uses a terminal while the DAP session is live. On completion, its output is archived as plain, reflowable text; its terminal colors cannot be reliably extracted from Neovim's terminal grid.

## Architecture

### Providers, Catalog, and State

Move the reusable logic from the current `overseer.*` namespace to `services.*`:

- `services.providers.springboot`, `services.providers.npm`, and `services.providers.custom` discover services and produce a common service definition.
- `services.catalog` owns type labels, icons, stable keys, discovery, filtering, and category replacement.
- `services.state` owns project-scoped Maven profiles and selected service keys, retaining the current lock and atomic-write behavior.
- Spring and npm readiness parsing becomes provider-owned parsing rather than Overseer components.

A service definition contains the stable key, display name, service type, command, working directory, environment, metadata, parser, restart policy, optional health check, and color policy. It does not expose an Overseer template, component, or task object.

### Runtime

`services.runtime` owns a registry of explicit service records. Each record includes:

- immutable definition data and project identity;
- current status and metadata such as readiness, URL, port, profile, and debugging state;
- a process handle, generation token, restart timer, and optional health-check timer;
- an output buffer and output renderer state;
- event subscribers.

The public runtime API is limited to service-oriented operations: discovery/reconciliation, `start`, `stop`, `restart`, `dispose`, `subscribe`, `get`, `list`, and `replace_output`.

Normal services are spawned through `vim.system()` without a PTY. Stdout and stderr callbacks feed the output renderer and the provider parser. Process completion, parser updates, and lifecycle transitions emit runtime events. A generation token prevents stale output or exit callbacks from a previous process instance from changing a restarted service.

Manual stop disables auto-restart. Failure-driven auto-restart uses the existing per-service delay and maximum-restart policy. Stop sends TERM first and escalates only after a bounded wait; Spring Boot and npm descendant-process shutdown is included in integration verification.

### Output Renderer

`services.output` creates a normal unlisted `nofile` buffer for each service. Its windows use `wrap=true` and `linebreak=true`, so Snacks zoom and ordinary window resizing automatically reflow all retained log lines.

The renderer:

- buffers partial stdout and stderr chunks into complete logical lines;
- maintains independent ANSI SGR state per stream;
- writes clean text to the buffer and style spans as extmarks;
- supports basic styles, 16-color, 256-color, and RGB SGR sequences with cached highlight groups;
- ignores unsupported control sequences safely;
- passes ANSI-free lines to readiness parsers;
- batches scheduled buffer writes and retains the latest 10,000 lines;
- relies on extmark tracking when old lines are removed from the FIFO buffer.

Known providers have an explicit color policy. Provider-specific force-color flags are added only after validating their non-TTY behavior. Custom services preserve whatever ANSI output they emit.

### Panel

`services.panel` replaces the Overseer list/sidebar internals with a bottom layout containing a service-list buffer and the focused service's log buffer. It subscribes to runtime events and renders task state, type icon, status detail, profile controls, and selection controls directly.

The existing interactions remain service-oriented:

- `a` manages category and multi-selection;
- `p` selects a Spring profile;
- `u` opens a detected service URL;
- `s`, `r`, `S`, and `dd` control the service under the cursor;
- global start-all and stop-all mappings call the runtime.

The panel has no dependency on `overseer.task_list.sidebar`, `OverseerListUpdate`, or task strategy internals.

### Java Debug

`custom.java_debug` receives a service key or service record instead of an Overseer task. It reads project/profile/launch metadata from the service record and updates debugging state through the runtime.

During a DAP `runInTerminal` session, the adapter terminal is placed in the focused service output position through `services.runtime.replace_output`. This remains a terminal buffer while debugging. When the session ends, its visible text is copied to a normal plain-text archive buffer and rebound to the service record. Neovim terminal rendering does not expose original ANSI SGR spans as buffer extmarks, so debug archives deliberately prioritize reflow and search over color preservation.

## Data Flow

1. Opening Services resolves the project root, discovers provider definitions, loads selected keys, reconciles service records, and opens the panel without starting processes.
2. Starting a record creates or clears its normal output buffer, applies the selected profile, spawns the process, and marks the record as starting.
3. Output callbacks append rendered log lines, invoke readiness parsing, update record metadata, and publish events for the panel.
4. A successful readiness parser update marks the service ready and enables URL actions.
5. Exit transitions to stopped, failed, or restart-pending according to whether the stop was manual and the restart policy.
6. Debug replaces only the focused service output binding; DAP lifecycle events update the same service record.

## Error Handling

- Provider discovery failures leave existing records intact and notify with the provider name.
- Spawn failures mark the record failed with the command error.
- Parser and ANSI decoding failures never terminate a process; affected output falls back to clean unstyled text.
- Persisting a changed selection must succeed before reconciliation mutates records.
- Stale selected keys remain persisted but hidden until discovery finds them again.
- Stop, restart, and dispose are idempotent and guarded by record generation.
- A DAP failure clears the debugging state and restores a normal output binding.

## Verification

- State and catalog tests preserve existing profile, selection, stable-key, and stale-key behavior.
- Provider tests cover discovery and Spring/npm readiness parsing.
- Runtime tests cover stdout/stderr chunk boundaries, ANSI styles split across chunks, 10,000-line trimming, generation guards, manual stop, failure restart, and disposal.
- Panel tests cover event-driven row refresh, focused-log replacement, and `wrap`/`linebreak` window options.
- Java Debug tests replace task strategy mutation with runtime output binding and verify terminal-to-plain archive behavior.
- Integration tests launch representative Spring Boot and npm processes, verify termination of their descendants, zoom logs with Snacks, and confirm that retained normal logs reflow at the new width.
