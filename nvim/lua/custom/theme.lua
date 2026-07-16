local M = {}

local function valid_colorscheme(name)
  return type(name) == "string" and name ~= ""
end

local function read_state(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end

  local decoded, state = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded or type(state) ~= "table" or not valid_colorscheme(state.colorscheme) then
    return nil
  end

  return state
end

local function apply_colorscheme(name)
  return pcall(vim.cmd.colorscheme, { args = { name } })
end

function M.setup(opts)
  opts = opts or {}

  local path = opts.path or (vim.fn.stdpath("state") .. "/theme.json")
  local default = opts.default or "tokyonight"
  local group = vim.api.nvim_create_augroup("ThemePersistence", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      local colorscheme = vim.g.colors_name
      if not valid_colorscheme(colorscheme) then
        return
      end

      pcall(function()
        vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
        vim.fn.writefile({ vim.json.encode({
          colorscheme = colorscheme,
          background = vim.o.background,
        }) }, path)
      end)
    end,
  })

  local state = read_state(path)
  if state and (state.background == "dark" or state.background == "light") then
    vim.o.background = state.background
  end

  if not state or not apply_colorscheme(state.colorscheme) then
    apply_colorscheme(default)
  end
end

return M
