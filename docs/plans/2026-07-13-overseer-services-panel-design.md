# Overseer Spring Boot Services Panel Design

## Goal

Turn the existing Overseer Spring Boot task list into a compact Services panel with clear runtime states, one-step profile switching, project-scoped persistence, failure-first ordering, and browser access to running applications.

## Product Decisions

- The selected Maven profile is shared by Spring Boot services in the active project.
- Selecting a profile persists it immediately and automatically restarts currently running Spring Boot services without another confirmation.
- Profiles are stored per absolute project root so different repositories do not affect one another.
- Failed services remain at the top of the list until restarted or disposed.
- A service URL defaults to the protocol, application port, and context path detected from Spring Boot output.
- The `u` key opens the URL for the service under the cursor.

## Information Architecture

The task-list winbar displays project-level state once:

```text
 SPRING SERVICES  ◆ profile: dev  [p switch]
```

Each task row only displays service-level state:

```text
 ×  OrdersApplication                         failed
 ●  GatewayApplication                       :8080
 ◐  UserApplication                          starting
 ○  ReportApplication                        stopped
```

Visual states:

- `●` with `DiagnosticOk`: running and application-ready.
- `◐` with `DiagnosticWarn`: process running but startup is not complete.
- `○` with `Comment`: never started or reset.
- `×` with `DiagnosticError`: failed.
- `■` with `DiagnosticHint`: canceled or stopped.
- `✓` with `DiagnosticInfo`: completed successfully.

Sort order is failure, running-ready, running-starting, pending, canceled, success, then name. This keeps actionable failures and live services visible.

## Architecture

### Project State

Add `overseer.service_state` as the single owner of project-level profile state. It stores JSON at:

```text
stdpath("state")/overseer/spring-services.json
```

The state shape is:

```json
{
  "projects": {
    "/absolute/project/root": {
      "profile": "dev"
    }
  }
}
```

Reads tolerate missing or invalid files. Writes acquire a short-lived cross-process lock, reload the latest disk state, create the parent directory, and atomically replace the state file. This prevents concurrent Neovim instances from dropping updates for other projects.

### Spring Boot Component

Add `service.springboot` as an Overseer task component.

Responsibilities:

- On initialization, mark the task as Spring Boot and initialize readiness metadata.
- On pre-start, remove stale Maven `-P` arguments and inject the persisted profile for the task's project root.
- On start, clear stale port, URL, context path, and readiness metadata.
- On output lines, parse common Tomcat, Netty, Jetty, and Undertow startup messages.
- Mark the service ready when Spring Boot emits its final `Started ... in ... seconds` message.
- On exit, clear readiness while preserving failure status from Overseer.

Task metadata contains `project_root`, `module`, `class`, `port`, `protocol`, `context_path`, `url`, and `ready`.

### Panel Controller

The Overseer configuration captures the project root per tab before opening the task-list buffer. It uses that tab-scoped root for profile selection, state restoration, template discovery, and the winbar.

Profile selection uses `vim.ui.select`. The selected value is persisted before running Spring Boot tasks are restarted. Non-running tasks pick up the new profile from `on_pre_start` on their next launch.

The panel maps `p` to profile selection, moves preview to `gp`, and maps `u` to the open-URL task action. URL opening uses `vim.ui.open`.

### Task Discovery

Spring Boot templates are created with `autostart = false`; discovery must never launch application processes. Template and task identities include module or fully qualified class information so same-named application classes remain distinct.

## Error Handling

- Missing profiles produce a warning and leave the current profile unchanged.
- Corrupt persistence files are ignored and replaced on the next successful selection.
- URL opening warns when the task is not ready or no port was detected.
- Unknown Spring server log formats leave the service in the running/starting state without fabricating a port.
- Profile changes restart only running tasks with `metadata.springboot == true`.

## Verification

- Headless tests cover profile parsing, project-scoped persistence, Maven profile argument replacement, and server-log URL extraction.
- A fake Overseer task verifies metadata transitions through init, pre-start, output, and exit hooks.
- Configuration loading verifies render, sort, keymaps, and actions without Lua errors.
- Manual verification confirms winbar presentation and browser opening from a running service row.
