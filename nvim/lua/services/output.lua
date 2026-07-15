local M = {}

local Output = {}
Output.__index = Output

local default_palette = {
  "#000000", "#cd0000", "#00cd00", "#cdcd00",
  "#0000ee", "#cd00cd", "#00cdcd", "#e5e5e5",
  "#7f7f7f", "#ff0000", "#00ff00", "#ffff00",
  "#5c5cff", "#ff00ff", "#00ffff", "#ffffff",
}
local highlight_cache = {}
local highlight_styles = {}
local ansi_priority = 200

local function new_style()
  return {
    fg = nil,
    bg = nil,
    bold = false,
    dim = false,
    italic = false,
    underline = false,
    reverse = false,
  }
end

local function new_stream()
  return {
    carry = "",
    line = "",
    spans = {},
    style = new_style(),
  }
end

local function hex_color(red, green, blue)
  return string.format("#%02x%02x%02x", red, green, blue)
end

local function color_channels(color, fallback)
  local value = color or fallback
  if type(value) == "string" then value = tonumber(value:gsub("^#", ""), 16) end
  value = type(value) == "number" and value or fallback
  return math.floor(value / 0x10000) % 0x100,
    math.floor(value / 0x100) % 0x100,
    value % 0x100
end

local function normal_colors()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  return normal.fg or 0xe5e5e5, normal.bg or 0x000000
end

local function blend_color(foreground, background, ratio)
  local fr, fg, fb = color_channels(foreground, 0xe5e5e5)
  local br, bg, bb = color_channels(background, 0x000000)
  local function blend(front, back)
    return math.floor(front * ratio + back * (1 - ratio) + 0.5)
  end
  return hex_color(blend(fr, br), blend(fg, bg), blend(fb, bb))
end

local function terminal_color(index)
  local configured = vim.g["terminal_color_" .. index]
  return type(configured) == "string" and configured or default_palette[index + 1]
end

local function indexed_color(index)
  index = math.max(0, math.min(255, index))
  if index < 16 then return terminal_color(index) end
  if index < 232 then
    local value = index - 16
    local levels = { 0, 95, 135, 175, 215, 255 }
    local red = math.floor(value / 36)
    local green = math.floor((value % 36) / 6)
    local blue = value % 6
    return hex_color(levels[red + 1], levels[green + 1], levels[blue + 1])
  end
  local gray = 8 + (index - 232) * 10
  return hex_color(gray, gray, gray)
end

local function style_key(style)
  if not style.fg and not style.bg and not style.bold and not style.dim
    and not style.italic and not style.underline and not style.reverse then
    return nil
  end
  return table.concat({
    style.fg or "",
    style.bg or "",
    style.bold and "1" or "0",
    style.dim and "1" or "0",
    style.italic and "1" or "0",
    style.underline and "1" or "0",
    style.reverse and "1" or "0",
  }, ":")
end

local function highlight_definition(style)
  local normal_fg, normal_bg = normal_colors()
  local foreground = style.fg
  if style.dim then foreground = blend_color(foreground or normal_fg, style.bg or normal_bg, 0.6) end
  return {
    fg = foreground,
    bg = style.bg,
    bold = style.bold or nil,
    italic = style.italic or nil,
    underline = style.underline or nil,
    reverse = style.reverse or nil,
  }
end

local function define_highlight(name, style)
  vim.api.nvim_set_hl(0, name, highlight_definition(style))
end

local function highlight_for(style)
  local key = style_key(style)
  if not key then return nil end
  if highlight_cache[key] then return highlight_cache[key] end

  local name = "ServicesAnsi_" .. vim.fn.sha256(key):sub(1, 12)
  highlight_styles[name] = vim.deepcopy(style)
  define_highlight(name, style)
  highlight_cache[key] = name
  return name
end

local highlight_group = vim.api.nvim_create_augroup("ServicesAnsiHighlights", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = highlight_group,
  callback = function()
    for name, style in pairs(highlight_styles) do
      define_highlight(name, style)
    end
  end,
})

local function reset_style(style)
  style.fg = nil
  style.bg = nil
  style.bold = false
  style.dim = false
  style.italic = false
  style.underline = false
  style.reverse = false
end

local function sgr_values(params)
  if params == "" then return { 0 } end
  local values = {}
  for value in (params .. ";"):gmatch("(.-);") do
    table.insert(values, tonumber(value) or 0)
  end
  return values
end

local function apply_sgr(style, params)
  local values = sgr_values(params)
  local index = 1
  while index <= #values do
    local code = values[index]
    if code == 0 then
      reset_style(style)
    elseif code == 1 then
      style.bold = true
    elseif code == 2 then
      style.dim = true
    elseif code == 3 then
      style.italic = true
    elseif code == 4 then
      style.underline = true
    elseif code == 7 then
      style.reverse = true
    elseif code == 22 then
      style.bold = false
      style.dim = false
    elseif code == 23 then
      style.italic = false
    elseif code == 24 then
      style.underline = false
    elseif code == 27 then
      style.reverse = false
    elseif code >= 30 and code <= 37 then
      style.fg = terminal_color(code - 30)
    elseif code == 39 then
      style.fg = nil
    elseif code >= 40 and code <= 47 then
      style.bg = terminal_color(code - 40)
    elseif code == 49 then
      style.bg = nil
    elseif code >= 90 and code <= 97 then
      style.fg = terminal_color(code - 90 + 8)
    elseif code >= 100 and code <= 107 then
      style.bg = terminal_color(code - 100 + 8)
    elseif (code == 38 or code == 48) and values[index + 1] == 5 and values[index + 2] then
      if code == 38 then
        style.fg = indexed_color(values[index + 2])
      else
        style.bg = indexed_color(values[index + 2])
      end
      index = index + 2
    elseif (code == 38 or code == 48) and values[index + 1] == 2
      and values[index + 2] and values[index + 3] and values[index + 4] then
      local color = hex_color(values[index + 2], values[index + 3], values[index + 4])
      if code == 38 then
        style.fg = color
      else
        style.bg = color
      end
      index = index + 4
    end
    index = index + 1
  end
end

local function append_segment(stream, text)
  if text == "" then return end
  local start_col = #stream.line
  stream.line = stream.line .. text
  local highlight = highlight_for(stream.style)
  if not highlight then return end

  local previous = stream.spans[#stream.spans]
  if previous and previous.hl_group == highlight and previous.end_col == start_col then
    previous.end_col = start_col + #text
  else
    table.insert(stream.spans, {
      start_col = start_col,
      end_col = start_col + #text,
      hl_group = highlight,
    })
  end
end

local function csi_end(data, start)
  for index = start + 2, #data do
    local byte = data:byte(index)
    if byte >= 0x40 and byte <= 0x7e then return index end
  end
end

local function osc_end(data, start)
  local bell = data:find("\a", start + 2, true)
  local string_terminator = data:find("\27\\", start + 2, true)
  if bell and (not string_terminator or bell < string_terminator) then return bell end
  if string_terminator then return string_terminator + 1 end
end

local function next_control(data, start)
  local esc = data:find("\27", start, true)
  local newline = data:find("\n", start, true)
  local carriage_return = data:find("\r", start, true)
  local next_index = esc
  if newline and (not next_index or newline < next_index) then next_index = newline end
  if carriage_return and (not next_index or carriage_return < next_index) then next_index = carriage_return end
  return next_index
end

function Output:_queue_line(text, spans, stream_name)
  table.insert(self.pending_lines, {
    text = text,
    spans = spans,
  })
  if self.on_line then self.on_line(text, stream_name) end
  if self.render_scheduled then return end

  self.render_scheduled = true
  vim.schedule(function()
    self.render_scheduled = false
    self:_render_pending()
  end)
end

function Output:_finish_line(stream, stream_name)
  self:_queue_line(stream.line, stream.spans, stream_name)
  stream.line = ""
  stream.spans = {}
end

function Output:_render_pending()
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    self.pending_lines = {}
    return
  end
  local pending = self.pending_lines
  self.pending_lines = {}
  if #pending == 0 then return end

  local lines = {}
  for _, entry in ipairs(pending) do
    table.insert(lines, entry.text)
  end

  vim.bo[self.bufnr].modifiable = true
  if self.line_count == 0 then
    vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)
  else
    vim.api.nvim_buf_set_lines(self.bufnr, -1, -1, false, lines)
  end
  vim.bo[self.bufnr].modifiable = false

  local first_row = self.line_count
  for offset, entry in ipairs(pending) do
    for _, span in ipairs(entry.spans) do
      vim.api.nvim_buf_set_extmark(self.bufnr, self.namespace, first_row + offset - 1, span.start_col, {
        end_col = span.end_col,
        hl_group = span.hl_group,
        priority = ansi_priority,
      })
    end
  end
  self.line_count = self.line_count + #pending

  local overflow = self.line_count - self.limit
  if overflow > 0 then
    vim.bo[self.bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(self.bufnr, 0, overflow, false, {})
    vim.bo[self.bufnr].modifiable = false
    self.line_count = self.line_count - overflow
  end
end

function Output:push(stream_name, data)
  if type(data) ~= "string" or data == "" then return end
  local stream = self.streams[stream_name] or self.streams.stdout
  local data_with_carry = stream.carry .. data
  stream.carry = ""

  local index = 1
  while index <= #data_with_carry do
    local control = next_control(data_with_carry, index)
    if not control then
      append_segment(stream, data_with_carry:sub(index))
      break
    end
    if control > index then
      append_segment(stream, data_with_carry:sub(index, control - 1))
      index = control
    end

    local byte = data_with_carry:byte(index)
    if byte == 10 then
      self:_finish_line(stream, stream_name)
      index = index + 1
    elseif byte == 13 then
      index = index + 1
    elseif data_with_carry:sub(index + 1, index + 1) == "[" then
      local final = csi_end(data_with_carry, index)
      if not final then
        stream.carry = data_with_carry:sub(index)
        break
      end
      if data_with_carry:sub(final, final) == "m" then
        local params = data_with_carry:sub(index + 2, final - 1)
        if params:match("^[0-9;]*$") then apply_sgr(stream.style, params) end
      end
      index = final + 1
    elseif data_with_carry:sub(index + 1, index + 1) == "]" then
      local final = osc_end(data_with_carry, index)
      if not final then
        stream.carry = data_with_carry:sub(index)
        break
      end
      index = final + 1
    else
      index = math.min(index + 2, #data_with_carry + 1)
    end
  end
end

function Output:flush(stream_name)
  local names = stream_name and { stream_name } or { "stdout", "stderr" }
  for _, name in ipairs(names) do
    local stream = self.streams[name]
    if stream then
      stream.carry = ""
      if stream.line ~= "" or #stream.spans > 0 then self:_finish_line(stream, name) end
    end
  end
end

function Output:clear()
  self.pending_lines = {}
  self.line_count = 0
  self.streams = { stdout = new_stream(), stderr = new_stream() }
  if not vim.api.nvim_buf_is_valid(self.bufnr) then return end
  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {})
  vim.api.nvim_buf_clear_namespace(self.bufnr, self.namespace, 0, -1)
  vim.bo[self.bufnr].modifiable = false
end

function Output:archive_from_buffer(source_bufnr)
  if not source_bufnr or not vim.api.nvim_buf_is_valid(source_bufnr) then return false end
  local lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
  self:clear()
  for _, line in ipairs(lines) do
    self:_queue_line(line, {}, "archive")
  end
  return true
end

function Output:configure_window(winid)
  winid = winid or 0
  vim.api.nvim_set_option_value("wrap", true, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("linebreak", true, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("number", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("signcolumn", "no", { scope = "local", win = winid })
  vim.api.nvim_set_option_value("foldcolumn", "0", { scope = "local", win = winid })
end

function Output:dispose()
  self.pending_lines = {}
  if not vim.api.nvim_buf_is_valid(self.bufnr) then return end
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(winid) == self.bufnr then
      vim.bo[self.bufnr].bufhidden = "wipe"
      return
    end
  end
  vim.api.nvim_buf_delete(self.bufnr, { force = true })
end

function M.new(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].filetype = "ServicesLog"
  if opts.name then pcall(vim.api.nvim_buf_set_name, bufnr, "[service-log] " .. opts.name) end

  return setmetatable({
    bufnr = bufnr,
    namespace = vim.api.nvim_create_namespace("services_output_" .. bufnr),
    limit = math.max(1, opts.limit or 10000),
    on_line = opts.on_line,
    streams = { stdout = new_stream(), stderr = new_stream() },
    pending_lines = {},
    line_count = 0,
    render_scheduled = false,
  }, Output)
end

return M
