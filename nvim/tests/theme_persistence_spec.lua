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
local state_path = temp_dir .. "/theme.json"
vim.fn.mkdir(temp_dir, "p")

local theme = require("custom.theme")

vim.fn.writefile({ vim.json.encode({ colorscheme = "blue", background = "dark" }) }, state_path)
theme.setup({ path = state_path, default = "default" })
assert_equal("blue", vim.g.colors_name, "saved colorscheme should restore")

vim.cmd.colorscheme("default")
local saved = vim.json.decode(table.concat(vim.fn.readfile(state_path), "\n"))
assert_equal("default", saved.colorscheme, "ColorScheme should persist immediately")
assert_equal(vim.o.background, saved.background, "ColorScheme should persist the current background")

vim.fn.writefile({ vim.json.encode({ colorscheme = "missing-theme" }) }, state_path)
theme.setup({ path = state_path, default = "blue" })
assert_equal("blue", vim.g.colors_name, "missing saved theme should fall back")

vim.fn.writefile({ "{malformed" }, state_path)
theme.setup({ path = state_path, default = "default" })
assert_equal("default", vim.g.colors_name, "malformed state should fall back")

local received_opts
package.loaded["resession"] = nil
package.preload["resession"] = function()
  return {
    setup = function(opts) received_opts = opts end,
    save = function() end,
    load = function() end,
    delete = function() end,
  }
end

local specs = dofile(config_root .. "/lua/plugins/auto-session.lua")
specs[1].config(nil, specs[1].opts)
assert(received_opts == specs[1].opts, "resession.setup should receive the declared opts table")
assert_equal(true, received_opts.autosave.enabled, "Resession autosave should remain enabled")
assert_equal(300, received_opts.autosave.interval, "Resession autosave should run every five minutes")
assert_equal(false, received_opts.autosave.notify, "Resession autosave should not notify")

vim.fn.delete(temp_dir, "rf")
print("theme-persistence-tests: ok")
