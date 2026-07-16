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

local captured
package.preload["neo-tree"] = function()
  return {
    setup = function(opts)
      captured = opts
    end,
  }
end

local spec = dofile(config_root .. "/lua/plugins/panel/neo-tree.lua")

assert_equal("nvim-neo-tree/neo-tree.nvim", spec[1], "Neo-tree should use the canonical plugin name")
assert_equal("MunifTanjim/nui.nvim", spec.dependencies[3], "Neo-tree should depend on nui.nvim")

spec.config()

assert(captured, "Neo-tree setup should receive configuration options")
assert_equal("left", captured.window.position, "Neo-tree should open on the left")
assert_equal(40, captured.window.width, "Neo-tree should use a 40-column window")
assert_equal(true, captured.enable_git_status, "Neo-tree git status should be enabled")
assert_equal(true, captured.enable_diagnostics, "Neo-tree diagnostics should be enabled")
assert_equal(true, captured.filesystem.follow_current_file, "Neo-tree should follow the current file")
assert_equal(true, captured.filesystem.filtered_items.hide_dotfiles, "Neo-tree should hide dotfiles")
assert_equal(true, captured.filesystem.filtered_items.hide_gitignored, "Neo-tree should hide Git-ignored files")
assert_equal("function", type(captured.filesystem.commands.image_wezterm), "image_wezterm should be a command")
assert_equal("function", type(captured.filesystem.commands.avante_add_files), "avante_add_files should be a command")
assert_equal(true, captured.buffers.show_unloaded, "Neo-tree buffers should include unloaded buffers")
assert_equal("float", captured.git_status.window.position, "Neo-tree Git status should float")

print("neo-tree-tests: ok")
