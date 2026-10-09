local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))

local function read(relative_path)
  local path = config_root .. "/" .. relative_path
  local lines = vim.fn.readfile(path)
  assert(#lines > 0, "expected non-empty file: " .. path)
  return table.concat(lines, "\n")
end

local function assert_contains(text, needle, message)
  assert(text:find(needle, 1, true), message .. "\nmissing: " .. needle)
end

local function assert_not_contains(text, needle, message)
  assert(not text:find(needle, 1, true), message .. "\nunexpected: " .. needle)
end

local keymaps = read("lua/key-map.lua")
local markdown = read("lua/plugins/style/markdown.lua")
local copilot = read("lua/plugins/complete/copilot.lua")
local lsp = read("lua/plugins/lsp/lsp.lua")
local snacks = read("lua/plugins/panel/snacks.lua")
local fzf_lua = read("lua/plugins/panel/fzf-lua.lua")
local grug_far = read("lua/plugins/grug-far.lua")
local indent_guides = read("lua/plugins/style/indent-blankline.lua")
local noice = read("lua/plugins/style/noice.lua")
local mini = read("lua/plugins/panel/mini.lua")
local treesitter = read("lua/plugins/lsp/treesitter.lua")
local trouble = read("lua/plugins/panel/trouble.lua")
local dap_view = read("lua/plugins/panel/dap-view.lua")
local base = read("base.vim")

assert_not_contains(keymaps, "Autosession delete", "Resession should be the only session deletion implementation")
assert_not_contains(keymaps, "local avanteApi = require", "Avante should not load while global keymaps initialize")
assert_not_contains(keymaps, 'map({ "n", "v" }, "<CR>"', "Markdown Enter should not be a global mapping")
assert_not_contains(keymaps, 'require("copilot.suggestion")', "Copilot acceptance should be owned by Blink")
assert_contains(keymaps,
  'map("n", "<c-q>", function()\n  if vim.bo.filetype == "neo-tree" then\n    vim.cmd("Neotree close")\n    return\n  end\n  Snacks.bufdelete()\nend, { desc = "Delete buffer" })',
  "Ctrl-Q should delete buffers without closing their windows")
assert_not_contains(keymaps, "local function split_type()",
  "Ctrl-Q should not infer window geometry before deleting a buffer")

assert_contains(markdown, 'vim.keymap.set({ "n", "v" }, "<CR>"', "Marklive should install its Enter mapping")
assert_contains(markdown, "buffer = args.buf", "Marklive Enter should be buffer-local")

assert_not_contains(copilot, "copilotlsp-nvim/copilot-lsp", "Disabled NES should not install copilot-lsp")
assert_contains(copilot, "enabled = false", "Copilot inline suggestions should be disabled")
assert_not_contains(copilot, 'accept = "<Tab>"', "Copilot should not compete with Blink for Tab")

assert_contains(
  lsp,
  'group = vim.api.nvim_create_augroup("lsp_codelens_',
  "CodeLens refresh should use a named per-buffer augroup"
)
assert_contains(lsp, "clear = true", "CodeLens refresh should replace prior buffer autocmds")
assert_contains(
  lsp,
  '{ desc = "i18n popup or signature help", buffer = bufnr }',
  "LSP signature help should be buffer-local"
)
assert_not_contains(lsp, '"copilot",', "Mason should not install a duplicate native Copilot LSP")
assert_not_contains(lsp, "vim.lsp.enable('copilot')", "Neovim should not start a duplicate native Copilot LSP")
assert_contains(lsp, '"yamlls",', "Mason should install the YAML language server")
assert_contains(lsp, "vim.lsp.enable('yamlls')", "Neovim should enable the YAML language server")

assert_contains(snacks, '{ "<leader>bS"', "Scratch selection should use the Buffer namespace")
assert_not_contains(snacks, '{ "<leader>S"', "Scratch selection should not replace the save mapping")
assert_contains(keymaps, "Snacks.picker.files({", "File search should use Snacks' path-aware highlighter")
assert_contains(keymaps, 'format = require("custom.file_picker").format',
  "File search should map path matches onto its filename-first display")
assert_contains(keymaps, 'on_match = require("custom.file_picker").on_match',
  "File search should prioritize high-quality filename matches")
assert_contains(keymaps, "pattern = query", "Visual file search should preserve the selected initial query")
assert_not_contains(fzf_lua, 'formatter = "path.dirname_first"',
  "fzf-lua should not override the file layout owned by Snacks")
assert_not_contains(base, "noremap <LEADER>sw", "Snacks should be the sole wrap toggle")
assert_contains(keymaps, '{ "<leader>x", group = "Tasks" }', "Which-Key should expose the Tasks namespace")

assert_contains(snacks, "notifier = {\n      enabled = true", "Snacks should own vim.notify")
assert_contains(snacks, "indent = { enabled = true }", "Snacks should own indent guides")
assert_contains(noice, "notify = { enabled = false }", "Noice should not compete with Snacks for vim.notify")
assert_contains(noice, 'view = "mini"', "Noice messages should use an auto-hiding mini view")
assert_contains(noice, 'view_error = "mini"', "Errors should not create persistent Noice popup windows")
assert_contains(noice, 'timeout = 2000', "Noice mini messages should auto-hide quickly")
assert_contains(noice, 'progress = {\n          enabled = true,\n          view = "mini"',
  "LSP progress should use a transient mini view instead of a large popup")
assert_contains(noice, 'message = {\n          enabled = true,\n          view = "mini"',
  "LSP status messages should use the same transient mini view")
local _, lsp_config_count = noice:gsub("      lsp = {", "")
assert(lsp_config_count == 1, "Noice should use one merged LSP configuration block")
assert_contains(indent_guides, "indent = {\n          enable = false", "hlchunk should retain chunks without duplicate indent guides")
assert_contains(mini, 'F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" })',
  "Mini.ai should own Tree-sitter function-definition textobjects")
assert_contains(mini, 'C = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" })',
  "Mini.ai should own Tree-sitter class textobjects")
assert_contains(mini, 'pattern = "markdown"', "Markdown code-block textobjects should be buffer-local")
assert_contains(mini, 'vim.b[args.buf].miniai_config = {', "Markdown textobjects should not override global Mini.ai objects")
local global_ai_textobjects = mini:match("custom_textobjects = {(.-)\n      },")
assert(global_ai_textobjects, "Mini.ai should declare its global textobjects")
assert_not_contains(global_ai_textobjects, "c =", "The Markdown `c` textobject should not be global")
assert_not_contains(treesitter, 'select_textobject("@function.outer"',
  "Tree-sitter textobjects should not override Mini.ai function mappings")
assert_not_contains(treesitter, 'select_textobject("@class.outer"',
  "Tree-sitter textobjects should not override Mini.ai class mappings")
assert_contains(treesitter, 'select_textobject("@local.scope"', "Tree-sitter local-scope selection should remain available")
assert(not vim.uv.fs_stat(config_root .. "/lua/plugins/style/cursorword.lua"),
  "vim-cursorword should be removed because vim-illuminate already highlights the word under the cursor")
assert_contains(trouble, '"<leader>xx"', "Trouble should expose workspace diagnostics")
assert_contains(trouble, '"<leader>xX"', "Trouble should expose buffer diagnostics")
assert_contains(dap_view, '"<leader>du"', "nvim-dap-view should have a dedicated toggle mapping")
assert_contains(dap_view, '"mfussenegger/nvim-dap"', "nvim-dap-view should reuse the configured DAP client")

assert_contains(grug_far, '"MagicDuck/grug-far.nvim"', "grug-far should provide project-wide replacement")
assert_contains(grug_far, '"<D-S-R>"', "Cmd+Shift+R should open grug-far")
assert_contains(grug_far, '"--fixed-strings"', "grug-far should default to literal matching")
assert_contains(grug_far, '"--ignore-case"', "grug-far should support case-insensitive matching")
assert_contains(grug_far, 'visualSelectionUsage = "prefill-search"',
  "Visual selections should prefill the replacement search")
assert_contains(grug_far, 'style = "float"',
  "grug-far should open in a Snacks floating window")
assert_contains(grug_far, "grug_far._createWindow = function(context)",
  "grug-far should bind its buffer to the Snacks floating window")
assert_contains(grug_far, "fixbuf = false", "Snacks should allow grug-far to replace its temporary buffer")
assert_not_contains(grug_far, "windowCreationCommand =", "grug-far should not depend on an Ex split command")

print("config-correctness-tests: ok")
