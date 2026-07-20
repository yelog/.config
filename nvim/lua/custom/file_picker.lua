local M = {}

local function fuzzy_positions(needle, haystack)
  local from = 1
  local positions = {}
  for i = 1, #needle do
    local pos = haystack:find(needle:sub(i, i), from, true)
    if not pos then
      return {}
    end
    positions[#positions + 1] = pos
    from = pos + 1
  end
  return positions
end

local function contiguous_positions(needle, haystack, original)
  local from = 1
  local fallback
  while true do
    local start = haystack:find(needle, from, true)
    if not start then
      return fallback or {}
    end
    local positions = {}
    for pos = start, start + #needle - 1 do
      positions[#positions + 1] = pos
    end
    fallback = fallback or positions

    local previous = start > 1 and original:sub(start - 1, start - 1) or nil
    local current = original:sub(start, start)
    if start == 1
      or not previous:match("[%w]")
      or (previous:match("%l") ~= nil and current:match("%u") ~= nil)
    then
      return positions
    end
    from = start + 1
  end
end

local function best_positions(needle, text)
  local lower_needle, lower_text = needle:lower(), text:lower()
  local positions = contiguous_positions(lower_needle, lower_text, text)
  return #positions > 0 and positions or fuzzy_positions(lower_needle, lower_text)
end

---Score the last query path segment against the filename only.
---@param query string
---@param path string
---@return number
function M.filename_match_bonus(query, path)
  query = vim.trim(query or "")
  local segment = query:match("([^/\\]+)$")
  if not segment or segment == "" then
    return 0
  end

  local filename = path:match("([^/\\]+)$") or path
  local lower_segment = segment:lower()
  local lower_filename = filename:lower()
  if lower_filename == lower_segment then
    return 4000
  end

  local start = lower_filename:find(lower_segment, 1, true)
  if start then
    local previous = start > 1 and filename:sub(start - 1, start - 1) or nil
    local current = filename:sub(start, start)
    local at_boundary = start == 1
      or not previous:match("[%w]")
      or (previous:match("%l") ~= nil and current:match("%u") ~= nil)
    return at_boundary and 3000 or 2000
  end

  return #fuzzy_positions(lower_segment, lower_filename) > 0 and 500 or 0
end

---@param matcher snacks.picker.Matcher
---@param item snacks.picker.Item
function M.on_match(matcher, item)
  item.score = item.score + M.filename_match_bonus(matcher.pattern, item.file or item.text or "")
end

---Choose visible highlight positions for each query path segment.
---@param query string
---@param path string
---@return number[]
function M.highlight_positions(query, path)
  local dir, filename = path:match("^(.*)/([^/]+)$")
  if not dir or not filename then
    dir, filename = "", path
  end

  local components = {}
  local search_from = 1
  for component in dir:gmatch("[^/\\]+") do
    local start = dir:find(component, search_from, true)
    components[#components + 1] = { text = component, start = start }
    search_from = start + #component + 1
  end

  local function directory_positions(segment)
    for index = #components, 1, -1 do
      local component = components[index]
      local positions = best_positions(segment, component.text)
      if #positions > 0 then
        local display_offset = #filename + 1 + component.start - 1
        return vim.tbl_map(function(pos) return display_offset + pos end, positions)
      end
    end
    return {}
  end

  query = vim.trim(query or "")
  local segments = {}
  for segment in query:gmatch("[^/\\]+") do
    segments[#segments + 1] = segment
  end
  local has_separator = query:find("[/\\]") ~= nil
  local trailing_separator = query:find("[/\\]$") ~= nil

  local result = {}
  for index, segment in ipairs(segments) do
    local filename_scope = not has_separator or (index == #segments and not trailing_separator)
    local positions = filename_scope and best_positions(segment, filename) or {}
    if #positions == 0 then
      positions = directory_positions(segment)
    end
    vim.list_extend(result, positions)
  end
  return result
end

---@param item snacks.picker.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function M.format(item, picker)
  local path = item.text or item.file or ""
  local dir, filename = path:match("^(.*)/([^/]+)$")
  if not dir or not filename then
    filename, dir = path, nil
  end

  local ret = {} ---@type snacks.picker.Highlight[]
  if picker.opts.icons.files.enabled ~= false then
    local icon, hl = Snacks.util.icon(path, "file", { fallback = picker.opts.icons.files })
    icon = Snacks.picker.util.align(icon, picker.opts.formatters.file.icon_width or 2)
    ret[#ret + 1] = { icon, hl, virtual = true }
  end
  local content_offset = Snacks.picker.highlight.offset(ret)

  ret[#ret + 1] = { filename, "SnacksPickerFile" }
  if dir then
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { dir, "SnacksPickerDir" }
  end

  local positions = M.highlight_positions(picker.matcher.pattern, path)
  Snacks.picker.highlight.matches(ret, positions, content_offset)
  return ret
end

return M
