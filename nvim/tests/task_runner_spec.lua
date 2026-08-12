local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error(
      (message or "values differ") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual)
    )
  end
end

local runner = require("custom.task_runner")

local maven = runner.build("nearest", {
  root = "/project",
  file = "/project/src/test/java/com/acme/OrderTest.java",
  filetype = "java",
  cursor_line = 5,
  lines = { "package com.acme;", "class OrderTest {", "  @Test", "  void createsOrder() {", "  }", "}" },
  files = { ["/project/mvnw"] = true },
})
assert_equal(
  {
    "./mvnw",
    "-Dmoss.skipTests=false",
    "-Dsurefire.failIfNoSpecifiedTests=false",
    "-Dtest=com.acme.OrderTest#createsOrder",
    "test",
  },
  maven.cmd,
  "Maven nearest should target the package, class, and method"
)
assert_equal("/project", maven.cwd, "Java tasks should run at the build root")

local reactor_maven = runner.build("nearest", {
  root = "/workspace/services/message",
  maven_root = "/workspace",
  module_pom = "/workspace/services/message/pom.xml",
  file = "/workspace/services/message/src/test/java/com/lenovo/moss/EmailUtilTest.java",
  filetype = "java",
  cursor_line = 5,
  lines = {
    "package com.lenovo.moss;",
    "class EmailUtilTest {",
    "  @Test",
    "  void testNormalEmail() {",
    "  }",
    "}",
  },
  files = { ["/workspace/pom.xml"] = true },
})
assert_equal({
  "mvn",
  "-pl",
  "services/message",
  "-am",
  "-Dmoss.skipTests=false",
  "-Dsurefire.failIfNoSpecifiedTests=false",
  "-Dtest=com.lenovo.moss.EmailUtilTest#testNormalEmail",
  "test",
}, reactor_maven.cmd, "Maven nearest should select the reactor module and enable tests")
assert_equal("/workspace", reactor_maven.cwd, "Maven reactor tests should run at the aggregator root")
assert_equal("EmailUtilTest#testNormalEmail", reactor_maven.service.name,
  "Java nearest should expose the method name to the services panel")
assert_equal("test", reactor_maven.service.service_type,
  "Java tests should use a dedicated services panel category")
assert_equal("/workspace", reactor_maven.service.project_root,
  "Java test services should belong to the Maven reactor root")

local registered_definition
local restarted_key
local restarted_opts
local focused_key
local opened_root
local selected_profile = "moss-sit"
local fake_service = { key = "test::fake" }
package.loaded["services.runtime"] = {
  instance = function()
    return {
      register = function(_, definition)
        registered_definition = definition
        fake_service.key = definition.key
        return fake_service
      end,
      restart = function(_, key, opts)
        restarted_key = key
        restarted_opts = opts
      end,
    }
  end,
}
package.loaded["services.state"] = {
  get_profile = function() return selected_profile end,
}
package.loaded["services.panel"] = {
  instance = function()
    return {
      open = function(_, root)
        opened_root = root
        return { root = root }
      end,
      render = function() end,
      focus = function(_, _, key) focused_key = key end,
    }
  end,
}
runner.run("nearest", {
  root = "/workspace/services/message",
  maven_root = "/workspace",
  module_pom = "/workspace/services/message/pom.xml",
  file = "/workspace/services/message/src/test/java/com/lenovo/moss/EmailUtilTest.java",
  filetype = "java",
  cursor_line = 5,
  lines = {
    "package com.lenovo.moss;",
    "class EmailUtilTest {",
    "  @Test",
    "  void testNormalEmail() {",
    "  }",
    "}",
  },
  files = { ["/workspace/pom.xml"] = true },
})
assert_equal("/workspace", opened_root, "running a Java test should open the services panel at the project root")
assert_equal("EmailUtilTest#testNormalEmail", registered_definition.name,
  "the registered service should display the test method")
assert_equal(registered_definition.key, restarted_key, "running a Java test should start its service")
assert_equal({ profile = "moss-sit" }, restarted_opts,
  "running a Java test should use the services panel Maven profile")
assert_equal(registered_definition.key, focused_key, "the services panel should focus the running test")
assert_equal({ "mvn", "-Pmoss-sit", "test" }, registered_definition.prepare({ cmd = { "mvn", "test" } }, "moss-sit"),
  "Java test services should insert a selected Maven profile")
assert_equal({ "mvn", "test" }, registered_definition.prepare({ cmd = { "mvn", "test" } }, nil),
  "Java test services should preserve Maven activeByDefault when no profile is selected")

selected_profile = "moss-mes-isg-dev"
runner.rerun()
assert_equal({ profile = "moss-mes-isg-dev" }, restarted_opts,
  "rerunning a Java test should read the latest services panel Maven profile")

local gradle = runner.build("file", {
  root = "/project",
  file = "/project/src/test/java/com/acme/OrderTest.java",
  filetype = "java",
  lines = { "package com.acme;", "class OrderTest {}" },
  files = { ["/project/gradlew"] = true },
})
assert_equal(
  { "./gradlew", "test", "--tests", "com.acme.OrderTest" },
  gradle.cmd,
  "Gradle file should target the qualified test class"
)

local vitest_file = runner.build("file", {
  root = "/web",
  file = "/web/src/order.test.ts",
  filetype = "typescript",
  files = { ["/web/pnpm-lock.yaml"] = true },
})
assert_equal(
  { "pnpm", "exec", "vitest", "run", "src/order.test.ts" },
  vitest_file.cmd,
  "Vitest file should use the project package manager and relative path"
)

local vitest_nearest = runner.build("nearest", {
  root = "/web",
  file = "/web/src/order.test.ts",
  filetype = "typescript",
  cursor_line = 3,
  lines = { "describe('orders', () => {", "  it('creates an order', () => {", "  })", "})" },
  files = { ["/web/package-lock.json"] = true },
})
assert_equal(
  { "npx", "--no-install", "vitest", "run", "src/order.test.ts", "-t", "creates an order" },
  vitest_nearest.cmd,
  "Vitest nearest should filter by the closest test name"
)

local cargo = runner.build("nearest", {
  root = "/rust",
  file = "/rust/src/lib.rs",
  filetype = "rust",
  cursor_line = 3,
  lines = { "#[test]", "fn parses_order() {", "}" },
  files = { ["/rust/Cargo.toml"] = true },
})
assert_equal({ "cargo", "test", "parses_order" }, cargo.cmd, "Cargo nearest should target the closest function")

local lua_file = runner.build("file", {
  root = config_root,
  file = config_root .. "/tests/project_search_spec.lua",
  filetype = "lua",
  files = {},
})
assert_equal(
  { "nvim", "--headless", "-u", "NONE", "+luafile " .. config_root .. "/tests/project_search_spec.lua", "+qa!" },
  lua_file.cmd,
  "Neovim config specs should run with the native headless harness"
)

local lua_all = runner.build("all", {
  root = config_root,
  file = config_root .. "/lua/key-map.lua",
  filetype = "lua",
  files = {},
})
assert_equal("zsh", lua_all.cmd[1], "All config specs should use a shell loop task")
assert(lua_all.cmd[3]:find("tests/%*_spec%.lua"), "All config specs should include every spec")

local unsupported, err = runner.build("all", {
  root = "/text",
  file = "/text/readme.txt",
  filetype = "text",
  files = {},
})
assert_equal(nil, unsupported, "Unsupported filetypes should not create a task")
assert(err and err:find("No test runner"), "Unsupported filetypes should explain the failure")

print("task-runner-tests: ok")
