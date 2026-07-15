# Overseer Service Selection and Log Retention Design

## Goal

Make the Services panel start empty, let users choose project launch entries by category, restore those choices on later visits, identify service types visually, tighten task rows, and bound long-running service output.

## Product Decisions

- A project with no saved selection opens with an empty service list.
- The panel-local `a` key opens a category picker followed by a multi-select launch-entry picker.
- Applying a selection replaces entries only in the chosen category and preserves selections in other categories.
- Selections are persisted per absolute project root and restored on later visits.
- Deselecting a running task does not stop it. It remains visible for the current session and the user is told to stop and dispose it manually.
- Missing saved entries remain persisted but hidden so they can return after a branch or dependency change.
- Each service output buffer retains the newest 10,000 lines using terminal scrollback FIFO behavior.

## Information Architecture

The task-list winbar communicates the empty state and the primary action:

```text
 SERVICES  0 selected  [a add]
```

After entries are selected, it summarizes present service types and exposes the same management action:

```text
 SPRING + NPM SERVICES  3 selected  [a manage]  ◆ profile: dev  [p switch]
```

Task rows separate runtime state from launch-entry type:

```text
 ●  OrdersApplication  :8080
 ◐  web:dev  starting
 ○ 󰒓 redis  stopped
```

The row uses one space between status, type icon, and name. Runtime detail remains separated from the name by two spaces.

## Architecture

### Service Catalog

Add `overseer.service_catalog` as the shared description and discovery layer. It owns:

- service type definitions for `springboot`, `npm`, and `service`;
- display labels, icons, highlight groups, and the generic fallback;
- stable keys derived from template or task metadata;
- discovery of templates from the three local providers;
- filtering discovered templates by persisted keys.

Every service template writes `metadata.service_type`. Adding a future service type requires a catalog entry and provider, without changing row rendering.

### Project State

Extend the existing atomic JSON state without discarding Spring profile data:

```json
{
  "projects": {
    "/absolute/project/root": {
      "profile": "dev",
      "selected_services": [
        "springboot::/absolute/project/root/orders::com.example.OrdersApplication",
        "npm::/absolute/project/root/web::dev"
      ]
    }
  }
}
```

Expose getters and setters for selected keys. Reads tolerate old state, invalid fields, and missing files. Writes continue to lock, reload, merge, and atomically replace the file.

### Selection Flow

When the user presses `a`:

1. Discover all available templates without building tasks.
2. Show categories with selected and available counts.
3. Open an fzf-lua picker where selected rows toggle multiple launch entries; a dedicated row clears the category.
4. Replace that category's saved keys and persist the merged selection.
5. Build newly selected templates.
6. Dispose deselected non-running tasks.
7. Keep deselected running tasks and notify the user to stop and dispose them manually.

Canceling either picker is a no-op. Persistence must succeed before task-list mutation.

### Panel Opening

Opening the panel discovers templates, loads project selection, and builds only matching entries. It never starts processes. Saved keys that are not currently discoverable are retained in state and ignored for this visit.

### Output Retention

Overseer's current terminal strategy explicitly sets `scrollback=100000`. Neovim terminal scrollback removes the oldest lines when the limit is exceeded, so current behavior is bounded FIFO rather than unbounded append.

The generic `service.lifecycle` component will expose `output_limit`, defaulting to 10,000, and apply it to the task terminal buffer on start. This gives every current and future service type the same policy. Existing `preserve_output=false` behavior continues to clear output when a task is reset or restarted.

## Error Handling

- Empty categories show a warning and leave state unchanged.
- Picker cancellation leaves state and tasks unchanged.
- Failed persistence prevents task mutation and reports an error.
- Unknown service types use the generic service icon and label.
- Deselecting a running task never terminates a process implicitly.
- Stale saved keys are retained and restored if discovery finds them later.

## Verification

- Headless tests cover project-scoped selection persistence, old-state compatibility, empty selections, and profile preservation.
- Catalog tests cover stable keys, type fallback, discovery normalization, and selected-template filtering.
- Template tests verify `service_type` metadata for Spring Boot, npm, and custom services.
- Lifecycle tests verify the 10,000-line terminal scrollback policy.
- Configuration loading verifies render, sort, actions, and keymaps without Lua errors.
- Manual verification checks Nerd Font glyph width, compact spacing, empty-state guidance, two-stage selection, selection restoration, and running-task deselection behavior.
