local M = {}

local highlight_group = vim.api.nvim_create_augroup("ServicesLogHighlights", { clear = true })

local function define_highlights()
  vim.api.nvim_set_hl(0, "ServicesLogInfo", { link = "DiagnosticInfo" })
  vim.api.nvim_set_hl(0, "ServicesLogWarn", { link = "DiagnosticWarn" })
  vim.api.nvim_set_hl(0, "ServicesLogError", { link = "DiagnosticError" })
  vim.api.nvim_set_hl(0, "ServicesLogDebug", { link = "DiagnosticHint" })
  vim.api.nvim_set_hl(0, "ServicesLogLogger", { link = "Type" })
  vim.api.nvim_set_hl(0, "ServicesLogLineNumber", { link = "Number" })
  vim.api.nvim_set_hl(0, "ServicesLogStacktrace", { link = "Comment" })
end

define_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = highlight_group,
  callback = define_highlights,
})

local level_groups = {
  TRACE = "ServicesLogDebug",
  DEBUG = "ServicesLogDebug",
  INFO = "ServicesLogInfo",
  WARN = "ServicesLogWarn",
  ERROR = "ServicesLogError",
  FATAL = "ServicesLogError",
}

local function add_span(spans, start_col, end_col, hl_group)
  table.insert(spans, { start_col = start_col, end_col = end_col, hl_group = hl_group })
end

function M.highlight_line(line)
  local spans = {}
  local timestamp_start, timestamp_end = line:find("^%d%d%d%d%-%d%d%-%d%d%s+%d%d:%d%d:%d%d%.%d+")
  if not timestamp_start then
    if line:match("^%s*at%s+[%w_$.]+%(") then
      add_span(spans, 0, #line, "ServicesLogStacktrace")
    elseif line:match("^Caused by:") then
      add_span(spans, 0, #line, "ServicesLogError")
    end
    return spans
  end

  local level_start, level_end, level = line:find("%[([A-Z]+)%s*%]", timestamp_end + 1)
  if not level or not level_groups[level] then return spans end
  add_span(spans, level_start, level_start + #level, level_groups[level])

  local logger_start, logger_end, logger = line:find("%[([^%]]+)%]%s+%-%s*", level_end + 1)
  if not logger then return spans end
  local class_name, line_number = logger:match("^(.*):(%d+)$")
  if class_name then
    add_span(spans, logger_start, logger_start + #class_name, "ServicesLogLogger")
    local number_start = logger_start + #class_name + 1
    add_span(spans, number_start, number_start + #line_number, "ServicesLogLineNumber")
  else
    add_span(spans, logger_start, logger_end, "ServicesLogLogger")
  end
  return spans
end

return M
