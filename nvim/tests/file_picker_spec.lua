local config_root = vim.fn.getcwd()
vim.opt.rtp:append(config_root)
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/snacks.nvim")

local matcher = require("snacks.picker.core.matcher").new()
local file_picker = require("custom.file_picker")

matcher:init("gateway/pom.xml")
local path = "moss-gateway/pom.xml"
local positions = matcher:positions({ text = path, idx = 1, score = 0 }).text
local mapped = file_picker.remap_positions(path, positions)
local display = "pom.xml moss-gateway"

local highlighted = {}
for _, pos in ipairs(mapped) do
  highlighted[#highlighted + 1] = display:sub(pos, pos)
end

assert(table.concat(highlighted):find("pom.xml", 1, true), "filename match should be highlighted on the left")
assert(table.concat(highlighted):find("gateway", 1, true), "directory match should be highlighted on the right")
assert(not display:find("moss%-gateway/pom%.xml"), "directory display must not repeat the filename")

_G.Snacks = require("snacks")

local function assert_format(icon_enabled, icon_width)
  local original_icon = Snacks.util.icon
  Snacks.util.icon = function() return string.rep("I", icon_width), "Special" end
  local formatted = file_picker.format({ text = path, file = path, idx = 1, score = 0 }, {
    matcher = matcher,
    opts = {
      icons = { files = { enabled = icon_enabled } },
      formatters = { file = { icon_width = icon_width } },
    },
  })
  Snacks.util.icon = original_icon

  local text, extmarks = Snacks.picker.highlight.to_text(formatted)
  local prefix = icon_enabled and string.rep(" ", icon_width) or ""
  assert(text == prefix .. display, "formatter should render filename first without repeating it in the directory")

  local actual = {}
  for _, mark in ipairs(extmarks) do
    if mark.hl_group == "SnacksPickerMatch" then
      actual[#actual + 1] = mark.col
    end
  end
  local expected = vim.tbl_map(function(pos) return pos - 1 + #prefix end, mapped)
  assert(vim.deep_equal(actual, expected), "match highlights should account for the rendered icon width")
end

assert_format(false, 0)
assert_format(true, 2)
assert_format(true, 4)

print("file-picker-tests: ok")
