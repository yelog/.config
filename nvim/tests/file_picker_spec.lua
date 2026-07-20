local config_root = vim.fn.getcwd()
vim.opt.rtp:append(config_root)
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/snacks.nvim")

local matcher = require("snacks.picker.core.matcher").new()
local file_picker = require("custom.file_picker")

matcher:init("gateway/pom.xml")
local path = "moss-gateway/pom.xml"
local mapped = file_picker.highlight_positions("gateway/pom.xml", path)
local display = "pom.xml moss-gateway"

local highlighted = {}
for _, pos in ipairs(mapped) do
  highlighted[#highlighted + 1] = display:sub(pos, pos)
end

assert(table.concat(highlighted):find("pom.xml", 1, true), "filename match should be highlighted on the left")
assert(table.concat(highlighted):find("gateway", 1, true), "directory match should be highlighted on the right")
assert(not display:find("moss%-gateway/pom%.xml"), "directory display must not repeat the filename")

local application_path = "moss-gateway/src/main/java/com/lenovo/moss/gateway/MossGatewayApplication.java"
local application_display = "MossGatewayApplication.java moss-gateway/src/main/java/com/lenovo/moss/gateway"
local application_positions = file_picker.highlight_positions("gateway/appli", application_path)
local application_highlight = {}
for index, pos in ipairs(application_positions) do
  application_highlight[#application_highlight + 1] = application_display:sub(pos, pos)
  if index <= #"gateway" then
    assert(pos > #"MossGatewayApplication.java", "segments before slash should only highlight the directory")
  else
    assert(pos <= #"MossGatewayApplication.java", "the last segment should prefer the filename")
  end
end
assert(table.concat(application_highlight):lower() == "gatewayappli",
  "path and filename query segments should highlight their scoped regions")

local filename_only = file_picker.highlight_positions("appli", application_path)
for _, pos in ipairs(filename_only) do
  assert(pos <= #"MossGatewayApplication.java", "queries without slash should prefer the filename")
end

local nested = file_picker.highlight_positions("src/main/java/appli", application_path)
local nested_highlight = {}
for _, pos in ipairs(nested) do
  nested_highlight[#nested_highlight + 1] = application_display:sub(pos, pos)
end
assert(table.concat(nested_highlight):lower() == "srcmainjavaappli",
  "multi-level directory segments should remain scoped to the path")

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

local exact = file_picker.filename_match_bonus("gateway/pom.xml", "moss-gateway/pom.xml")
local boundary = file_picker.filename_match_bonus("gateway/appli", "moss-gateway/MossGatewayApplication.java")
local substring = file_picker.filename_match_bonus("gateway/cati", "moss-gateway/MossGatewayApplication.java")
local fuzzy = file_picker.filename_match_bonus("gateway/appli", "moss-gateway/AlpineProcessLogicInterface.java")
local directory_only = file_picker.filename_match_bonus("gateway/appli", "moss-gateway/appli/Other.java")

assert(exact > boundary, "exact filename matches should rank above boundary substring matches")
assert(boundary > substring, "boundary substring matches should rank above ordinary substrings")
assert(substring > fuzzy, "continuous filename matches should rank above fuzzy filename matches")
assert(fuzzy > directory_only, "fuzzy filename matches should rank above directory-only matches")

local ranked = { score = 100, file = "moss-gateway/MossGatewayApplication.java" }
file_picker.on_match({ pattern = "gateway/appli" }, ranked)
assert(ranked.score == 100 + boundary, "on_match should add the current query's filename quality bonus")

print("file-picker-tests: ok")
