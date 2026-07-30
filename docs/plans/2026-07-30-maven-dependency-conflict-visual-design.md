# Maven Dependency Conflict Visual Design

## Goal

Make Maven version mediation immediately visible in every dependency view and
replace the flat white artifact treatment with a theme-adaptive semantic color
system.

## Current State

The analyzer already receives `conflict_version` from Maven, counts it in the
summary, supports a conflict-only view, and renders a warning for non-root
nodes. A direct root with a conflict instead renders only `D`, so its warning
is obscured. Normal artifact names all use `Identifier`, which is near-white in
the active theme and does not distinguish direct, transitive, or duplicate
dependencies.

## Visual System

- Direct artifact names use `String`; transitive artifacts use `Function`; and
  duplicate artifacts use `Special`. Versions use `Constant`, while groupId and
  size remain subdued.
- Every conflict begins with a narrow warning rail (`┃`) and an explicit
  `[! CONFLICT]` badge. This is additive to the direct `D` marker.
- The version comparison reads `active <resolved> <- omitted <evicted>` in
  warning colors. It replaces the ambiguous selected/omitted prose.
- Search matches retain `Search` as the strongest emphasis so filtering remains
  predictable. Conflict metadata still remains visible beside the match.
- Custom Maven highlight names link to diagnostic groups, preserving each
  colorscheme's palette instead of hard-coding terminal colors.

## Testing

Analyzer fixtures include direct and transitive conflicts. Tests assert the
conflict badge and both versions render for direct roots, while model tests
continue to validate conflict counts and conflict-only selection.
