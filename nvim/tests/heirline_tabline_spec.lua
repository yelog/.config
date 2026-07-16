local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
local captured_buffer_block
local highlights = {
  PmenuSel = { bg = "#32426b" },
  TabLineSel = { bg = "#343a55" },
  CursorLine = { bg = "#292e42" },
  TabLine = { bg = "#000000" },
  default = { fg = "#ffffff" },
}

package.preload["heirline.conditions"] = function()
  return { is_git_repo = function() return false end }
end

package.preload["heirline.utils"] = function()
  return {
    get_highlight = function(name) return highlights[name] or highlights.default end,
    surround = function(_, _, component) return component end,
    make_buflist = function(component)
      captured_buffer_block = component
      return component
    end,
    make_tablist = function(component) return component end,
    on_colorscheme = function() end,
  }
end

package.preload["heirline"] = function()
  return { setup = function() end }
end

package.preload["nvim-web-devicons"] = function()
  return { get_icon_color = function() end }
end

local specs = dofile(config_root .. "/lua/plugins/panel/status-line.lua")
specs[1].config()

assert(captured_buffer_block[1].provider == " ",
  "buffer tabs must have left padding")
assert(captured_buffer_block[3].provider == " ",
  "buffer tabs must have right padding")
assert(captured_buffer_block.hl({ is_active = true }).bg == "#32426b",
  "active buffer tabs must use the PmenuSel background when it is available")
assert(captured_buffer_block.hl({ is_active = false }).bg == "#000000",
  "inactive buffer tabs must use the TabLine background")
highlights.PmenuSel.bg = nil
assert(captured_buffer_block.hl({ is_active = true }).bg == "#343a55",
  "active buffer tabs must fall back to TabLineSel when PmenuSel has no background")
highlights.TabLineSel.bg = nil
assert(captured_buffer_block.hl({ is_active = true }).bg == "#292e42",
  "active buffer tabs must fall back to CursorLine when PmenuSel and TabLineSel have no backgrounds")
highlights.CursorLine.bg = nil
assert(captured_buffer_block.hl({ is_active = true }).bg == "#000000",
  "active buffer tabs must fall back to TabLine when no active-tab highlight has a background")
print("heirline-tabline-tests: ok")
