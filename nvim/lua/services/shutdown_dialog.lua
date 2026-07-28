local M = {}

local buffer
local window

local function close()
  if window and vim.api.nvim_win_is_valid(window) then
    vim.api.nvim_win_close(window, true)
  end
  if buffer and vim.api.nvim_buf_is_valid(buffer) then
    vim.api.nvim_buf_delete(buffer, { force = true })
  end
  buffer = nil
  window = nil
end

local function dimensions(lines)
  local width = 36
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line) + 6)
  end
  width = math.min(width, math.max(20, vim.o.columns - 4))
  return width, #lines + 2
end

local function configure(width, height)
  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 100,
    title = " Services ",
    title_pos = "center",
  }
end

---@param _ string|nil
---@param status { phase: string, text: string }|nil
function M.render(_, status)
  if not status or not status.text then
    close()
    return
  end

  local lines = {
    "正在关闭服务",
    "",
    status.text,
    "请稍候，正在终止后台进程",
  }
  local width, height = dimensions(lines)
  if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
    buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].modifiable = false
  end

  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false

  local config = configure(width, height)
  if window and vim.api.nvim_win_is_valid(window) then
    vim.api.nvim_win_set_config(window, config)
  else
    window = vim.api.nvim_open_win(buffer, false, config)
  end
  -- VimLeavePre waits synchronously for child processes, so redraw immediately.
  vim.cmd("redraw!")
end

return M
