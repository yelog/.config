local M = {}

local function utf8(code)
  if code < 0x80 then
    return string.char(code)
  elseif code < 0x800 then
    return string.char(0xc0 + math.floor(code / 64), 0x80 + code % 64)
  elseif code < 0x10000 then
    return string.char(0xe0 + math.floor(code / 4096), 0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
  end
  return string.char(0xf0 + math.floor(code / 262144), 0x80 + math.floor(code / 4096) % 64,
    0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
end

local function unicode_at(text, slash)
  local hex = text:sub(slash + 2, slash + 5)
  if text:sub(slash, slash + 1) == "\\u" and #hex == 4 and hex:match("^%x+$") then
    return tonumber(hex, 16)
  end
end

-- Decode printable non-ASCII escapes only. Keep properties syntax (\n, \u0020,
-- \u005c, continuations, and literal \\u sequences) intact in the editable text.
function M.decode(text)
  local output, replacements = {}, {}
  local cursor, from = 1, 1
  while true do
    local first, last = text:find("\\+", from)
    if not first then break end
    local code = (last - first + 1) % 2 == 1 and unicode_at(text, last) or nil
    local finish = last + 6
    if code and code >= 0xd800 and code <= 0xdbff then
      local low = unicode_at(text, finish)
      code = low and low >= 0xdc00 and low <= 0xdfff
        and 0x10000 + (code - 0xd800) * 0x400 + low - 0xdc00 or nil
      finish = finish + 6
    end
    if code and code >= 0xa0 and not (code >= 0xd800 and code <= 0xdfff) then
      local character = utf8(code)
      output[#output + 1] = text:sub(cursor, last - 1)
      output[#output + 1] = character
      replacements[#replacements + 1] = { text = character, raw = text:sub(last, finish - 1) }
      cursor, from = finish, finish
    else
      from = last + 1
    end
  end
  output[#output + 1] = text:sub(cursor)
  return table.concat(output), replacements
end

function M.snapshot(raw, previous)
  local state = { lines = {}, unchanged = {}, spellings = {} }
  if previous then
    for decoded, original in pairs(previous.unchanged) do state.unchanged[decoded] = original end
    for character, original in pairs(previous.spellings) do state.spellings[character] = original end
  end
  local decoded_lines = {}
  for index, line in ipairs(vim.split(raw, "\n", { plain = true })) do
    local decoded, replacements = M.decode(line)
    state.lines[index] = { raw = line, decoded = decoded }
    state.unchanged[decoded] = state.unchanged[decoded] or line
    decoded_lines[index] = decoded
    for _, replacement in ipairs(replacements) do
      state.spellings[replacement.text] = state.spellings[replacement.text] or replacement.raw
    end
  end
  return state, table.concat(decoded_lines, "\n")
end

local function escape(text, spellings)
  return (text:gsub("[\194-\244][\128-\191]+", function(character)
    if spellings[character] then return spellings[character] end
    local bytes = { character:byte(1, -1) }
    local code = bytes[1] % (2 ^ (7 - #bytes))
    for index = 2, #bytes do code = code * 64 + bytes[index] % 64 end
    if code <= 0xffff then return string.format("\\u%04x", code) end
    code = code - 0x10000
    return string.format("\\u%04x\\u%04x", 0xd800 + math.floor(code / 0x400), 0xdc00 + code % 0x400)
  end))
end

function M.encode(text, state)
  local lines = vim.split(text, "\n", { plain = true })
  for index, line in ipairs(lines) do
    local original = state.lines[index]
    lines[index] = original and original.decoded == line and original.raw
      or state.unchanged[line] or escape(line, state.spellings)
  end
  return table.concat(lines, "\n")
end

return M
