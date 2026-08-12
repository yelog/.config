# Java Test Maven Profile Design

## Goal

Make Java tests started with `<leader>jt` use the Maven profile currently
selected in the services panel so filtered Nacos connection properties are
available during Spring tests.

## Design

- Keep the test's Spring profile independent. `@ActiveProfiles("test")` remains
  responsible for the Spring Test environment.
- Treat the services panel profile as a Maven profile and pass it to test
  execution as `-P<profile>`.
- Add a `prepare` function to Java Maven test service definitions. It inserts
  the profile immediately after `mvn` or `mvnw` each time the service starts.
- Read the current profile through `services.state.get_profile(project_root)`
  for `<leader>jt` and `<leader>xr`. The services panel's existing restart path
  already supplies the same current profile.
- When no profile is selected, do not add `-P`; Maven remains responsible for
  applying any `activeByDefault` profile.

## Expected Command

```text
mvn -Pmoss-mes-isg-dev -pl moss-service-message/moss-service-message-server -am \
  -Dmoss.skipTests=false -Dsurefire.failIfNoSpecifiedTests=false \
  -Dtest=com.lenovo.moss.service.message.server.EmailUtilTest#testNormalEmail test
```

## Verification

- A selected profile is inserted once after the Maven executable.
- No selected profile leaves the command unchanged.
- Rerunning reads the current profile rather than retaining the profile from
  the previous run.
