local M = {}

---Map match positions from `dir/filename` to `filename dir`.
---@param path string
---@param positions number[]
---@return number[]
function M.remap_positions(path, positions)
  local dir, filename = path:match("^(.*)/([^/]+)$")
  if not dir or not filename then
    return vim.deepcopy(positions)
  end

  local mapped = {}
  local filename_start = #dir + 2
  local dir_offset = #filename + 1
  for _, pos in ipairs(positions) do
    if pos <= #dir then
      mapped[#mapped + 1] = dir_offset + pos
    elseif pos >= filename_start then
      mapped[#mapped + 1] = pos - filename_start + 1
    end
    -- The separator slash is intentionally omitted from the display.
  end
  return mapped
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

  local positions = picker.matcher:positions(item).text or {}
  Snacks.picker.highlight.matches(ret, M.remap_positions(path, positions), content_offset)
  return ret
end

return M
