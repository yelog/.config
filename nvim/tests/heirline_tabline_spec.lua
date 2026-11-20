local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
local captured_buffer_block
local captured_setup
local igit_states = {}
local highlights = {
  PmenuSel = { fg = "#111111", bg = "#32426b" },
  TabLineSel = { fg = "#f0f0f0", bg = "#343a55" },
  CursorLine = { bg = "#292e42" },
  TabLine = { fg = "#a0a0a0", bg = "#000000" },
  Normal = { fg = "#ffffff", bg = "#101010" },
  IgitHunkAdd = { fg = "#109900" },
  IgitHunkChange = { fg = "#0099FF" },
  default = {},
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
  return {
    setup = function(opts)
      captured_setup = opts
    end,
  }
end

package.preload["igit"] = function()
  return {
    status = function(bufnr)
      return igit_states[bufnr or vim.api.nvim_get_current_buf()]
    end,
  }
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
assert(captured_buffer_block.hl({ is_active = true }).fg == "#f0f0f0",
  "active buffer tabs must use TabLineSel foreground instead of PmenuSel foreground")
assert(captured_buffer_block.hl({ is_active = false }).bg == "#000000",
  "inactive buffer tabs must use the TabLine background")
assert(captured_buffer_block.hl({ is_active = false }).fg == "#a0a0a0",
  "inactive buffer tabs must use the TokyoNight TabLine foreground override")
highlights.TabLineSel.fg = nil
assert(captured_buffer_block.hl({ is_active = true }).fg == "#ffffff",
  "active buffer tabs must fall back to the readable Normal foreground")
highlights.TabLineSel.fg = "#f0f0f0"
highlights.PmenuSel.bg = nil
assert(captured_buffer_block.hl({ is_active = true }).bg == "#343a55",
  "active buffer tabs must fall back to TabLineSel when PmenuSel has no background")
highlights.TabLineSel.bg = nil
assert(captured_buffer_block.hl({ is_active = true }).bg == "#292e42",
  "active buffer tabs must fall back to CursorLine when PmenuSel and TabLineSel have no backgrounds")
highlights.CursorLine.bg = nil
assert(captured_buffer_block.hl({ is_active = true }).bg == "#000000",
  "active buffer tabs must fall back to TabLine when no active-tab highlight has a background")
highlights.TabLine.fg = nil
assert(captured_buffer_block.hl({ is_active = false }).fg == "#ffffff",
  "inactive buffer tabs must retain the Normal foreground fallback")

local bufnr = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(bufnr, "/tmp/project/src/Example.java")

local tab_file_block = captured_buffer_block[2]
local relative_path = captured_setup.statusline[3]
local tab_context = {
  bufnr = bufnr,
  filename = "/tmp/project/src/Example.java",
  is_active = true,
}
local path_context = {}
relative_path.init(path_context)

igit_states[bufnr] = { file_state = "modified", modified = true }
assert(tab_file_block.hl(tab_context).fg == "#0099FF",
  "modified tab filenames must use the Igit hunk change color")
assert(relative_path[2].hl(path_context).fg == "#0099FF",
  "modified statusline filenames must use the Igit hunk change color")
assert(relative_path[1].provider(path_context) == "/tmp/project/src/",
  "statusline paths must split the directory from the filename")
assert(relative_path[2].provider(path_context) == "Example.java",
  "statusline paths must keep the filename separate for status coloring")

igit_states[bufnr] = { file_state = "added", modified = true }
assert(tab_file_block.hl(tab_context).fg == "#109900",
  "added tab filenames must use the Igit hunk add color")
assert(relative_path[2].hl(path_context).fg == "#109900",
  "added statusline filenames must use the Igit hunk add color")

igit_states[bufnr] = { file_state = "clean", modified = false }
assert(tab_file_block.hl(tab_context).fg == nil,
  "clean tab filenames must use the default foreground")
assert(relative_path[2].hl(path_context).fg == nil,
  "clean statusline filenames must use the default foreground")

igit_states[bufnr] = { file_state = "ignored", modified = true, ignored = true }
assert(tab_file_block.hl(tab_context).fg == nil,
  "ignored tab filenames must use the default foreground")
assert(relative_path[2].hl(path_context).fg == nil,
  "ignored statusline filenames must use the default foreground")

igit_states[bufnr] = { file_state = "modified", modified = true }
highlights.IgitHunkChange.fg = "#123456"
assert(tab_file_block.hl(tab_context).fg == "#123456",
  "tab filenames must read the current Igit highlight instead of a cached color")
assert(relative_path[2].hl(path_context).fg == "#123456",
  "statusline filenames must read the current Igit highlight instead of a cached color")
highlights.IgitHunkChange.fg = "#0099FF"

print("heirline-tabline-tests: ok")
