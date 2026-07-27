local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error((message or "values differ")
      .. "\nexpected: " .. vim.inspect(expected)
      .. "\nactual:   " .. vim.inspect(actual))
  end
end

local temp_dir = vim.fn.tempname()
local workspace_root = temp_dir .. "/workspace"
vim.fn.mkdir(workspace_root .. "/moss-cloud", "p")
vim.fn.mkdir(workspace_root .. "/another-project", "p")
vim.fn.writefile({ "not a workspace" }, workspace_root .. "/workspace.txt")

local cleaner = require("custom.jdtls_workspace_cleaner")

assert_equal({
  workspace_root .. "/another-project",
  workspace_root .. "/moss-cloud",
}, cleaner.list_workspaces(workspace_root), "only direct workspace directories should be listed")
assert(cleaner.is_workspace_path(workspace_root, workspace_root .. "/moss-cloud"), "child workspace should be accepted")
assert(not cleaner.is_workspace_path(workspace_root, workspace_root), "workspace root must not be deletable")
assert(
  not cleaner.is_workspace_path(workspace_root, workspace_root .. "/moss-cloud/.metadata"),
  "nested paths must not be deletable"
)
assert(not cleaner.is_workspace_path(workspace_root, temp_dir), "outside path must not be deletable")

local active = cleaner.client_workspace({
  name = "jdtls",
  config = { cmd = { "jdtls", "-data", workspace_root .. "/moss-cloud" } },
})
assert_equal(workspace_root .. "/moss-cloud", active, "jdtls data directory should be detected")
assert_equal(nil, cleaner.client_workspace({
  name = "lua_ls",
  config = { cmd = { "lua-language-server", "-data", workspace_root .. "/moss-cloud" } },
}), "non-JDTLS clients must be ignored")
assert_equal(workspace_root .. "/moss-cloud", cleaner.client_workspace({
  name = "jdtls",
  config = { cmd = { "jdtls", "--data=" .. workspace_root .. "/moss-cloud" } },
}), "JDTLS long data argument should be detected")

vim.fn.delete(temp_dir, "rf")
print("jdtls-workspace-cleaner-spec-tests: ok")
