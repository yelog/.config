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

local function read(relative_path)
  return table.concat(vim.fn.readfile(config_root .. "/" .. relative_path), "\n")
end

local format = require("custom.format")
local config = format.config()

assert_equal({ "stylua" }, config.formatters_by_ft.lua, "Lua should use Stylua")
assert_equal({ "rustfmt", lsp_format = "fallback" }, config.formatters_by_ft.rust, "Rust should use rustfmt")
assert_equal({ "prettier", stop_after_first = true }, config.formatters_by_ft.vue, "Vue should use Prettier")
assert_equal(config.formatters_by_ft.vue, config.formatters_by_ft.typescript, "TypeScript should share Vue formatting")
assert_equal(config.formatters_by_ft.vue, config.formatters_by_ft.javascript, "JavaScript should share Vue formatting")
assert_equal(config.formatters_by_ft.vue, config.formatters_by_ft.markdown, "Markdown should use Prettier")
assert_equal("fallback", config.default_format_opts.lsp_format, "Java and unconfigured files should fall back to LSP")
assert_equal(nil, config.format_on_save, "Formatting must remain manual-only")
assert_equal(nil, config.format_after_save, "Formatting must not run after save")

local conform_spec = read("lua/plugins/lsp/conform.lua")
assert(conform_spec:find("stevearc/conform.nvim", 1, true), "Conform plugin should be installed")
assert(not conform_spec:find("format_on_save", 1, true), "Conform plugin should not configure format-on-save")
assert(
  read("stylua.toml"):find('indent_type = "Spaces"', 1, true),
  "Stylua should preserve the existing space indentation"
)

local lsp = read("lua/plugins/lsp/lsp.lua")
assert(lsp:find("vim.diagnostic.severity.ERROR", 1, true), "Inline diagnostics should be limited to errors")
assert(lsp:find("vim.diagnostic.severity.WARN", 1, true), "Diagnostic signs should include warnings")

local keymaps = read("lua/key-map.lua")
assert(
  keymaps:find('require("custom.format").format', 1, true),
  "Manual format mappings should use the shared formatter"
)
assert(keymaps:find("diagnostics_buffer", 1, true), "A current-buffer diagnostics picker should be mapped")
assert(keymaps:find("picker.diagnostics()", 1, true), "A workspace diagnostics picker should be mapped")

print("format-tests: ok")
