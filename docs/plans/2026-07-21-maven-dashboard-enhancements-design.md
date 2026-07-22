# Maven Dashboard Enhancements Design

## Goal

Make Maven Profile selection, project command presets, and Maven arguments
project-scoped and persistent, while keeping the existing upstream
`oclay1st/maven.nvim` interface.

## Decisions

- `custom.maven_profiles` remains the Maven-specific state owner. It already
  persists selected profiles atomically per normalized project root.
- Its state adds optional `arguments` and `commands` fields. Existing profile
  selections remain compatible because each field is independently optional.
- Maven may select multiple profiles. Maven commands receive every selected
  profile as `-Pprofile-a,profile-b`; the Spring service panel receives the
  first sorted selected profile because Spring services have a single-profile
  launch contract.
- User-managed default arguments are restored whenever the current project
  changes. The generated Maven Profile argument remains marked internally and
  is never persisted as a user argument.
- Project command presets are injected into the upstream project's `Commands`
  tree through its supported `projects_view.custom_commands` option. They use
  the same argument format and Console execution path as upstream commands.

## Data Model

`stdpath("state")/maven/profiles.json` stores one record per normalized root:

```json
{
  "projects": {
    "/workspace/example": {
      "profiles": ["dev", "uat"],
      "arguments": [{ "arg": "-DskipTests", "enabled": true }],
      "commands": [{ "name": "verify-fast", "description": "Verify without tests", "cmd_args": ["verify", "-DskipTests"] }]
    }
  }
}
```

Empty optional fields are removed rather than represented by empty arrays.

## Integration

- `services.state.get_profile` delegates Maven projects to
  `custom.maven_profiles.get_primary_profile`; service launch behavior remains
  single-profile and existing non-Maven behavior is unchanged.
- `custom.maven_profiles.apply_current` restores arguments and commands before
  adding the generated Profile argument.
- A `DirChanged` autocmd reapplies all three project-scoped settings.
- The upstream dependency explorer remains lazy: it loads only after selecting
  a project node and pressing `a` in the project dashboard.

## Error Handling

- Invalid stored command or argument values are ignored rather than injected
  into upstream configuration.
- State writes retain the existing temporary-file-and-rename behavior.
- No profile selection still resolves to `nil` for Spring services.

## Tests

- Extend Maven Profile specs for primary-profile selection, argument and preset
  persistence, upstream option injection, and restoration when switching roots.
- Extend service-state specs to prove Maven Profile delegation preserves the
  first selected profile rule.
- Extend plugin and keymap specs to cover new commands and documented entry
  points.
