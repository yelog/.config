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
local base = read("base.vim")

assert_not_contains(keymaps, "Autosession delete", "Resession should be the only session deletion implementation")
assert_not_contains(keymaps, "local avanteApi = require", "Avante should not load while global keymaps initialize")
assert_not_contains(keymaps, 'map({ "n", "v" }, "<CR>"', "Markdown Enter should not be a global mapping")
assert_not_contains(keymaps, 'require("copilot.suggestion")', "Copilot acceptance should be owned by Blink")

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

assert_contains(snacks, '{ "<leader>bS"', "Scratch selection should use the Buffer namespace")
assert_not_contains(snacks, '{ "<leader>S"', "Scratch selection should not replace the save mapping")
assert_not_contains(base, "noremap <LEADER>sw", "Snacks should be the sole wrap toggle")
assert_contains(keymaps, '{ "<leader>x", group = "Tasks" }', "Which-Key should expose the Tasks namespace")

print("config-correctness-tests: ok")
