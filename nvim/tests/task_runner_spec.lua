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
  { "./mvnw", "-Dtest=com.acme.OrderTest#createsOrder", "test" },
  maven.cmd,
  "Maven nearest should target the package, class, and method"
)
assert_equal("/project", maven.cwd, "Java tasks should run at the build root")

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
