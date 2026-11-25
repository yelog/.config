local M = {}
local codec = require("custom.properties_codec")
local encoding = "java-properties"
local states, pending = {}, {}
local previous_converter

local function read(path)
  local file = assert(io.open(path, "rb"))
  local text = file:read("*a")
  file:close()
  return text
end

local function encode(text, buf)
  return codec.encode(text, assert(states[buf], "properties conversion state is missing"))
end

function M.git_text(text, buf)
  if vim.b[buf].java_properties_unicode and vim.bo[buf].fileencoding == encoding then
    return encode(text, buf)
  end
end

function M.convert()
  if vim.v.charconvert_from ~= encoding and vim.v.charconvert_to ~= encoding then
    if previous_converter ~= "" then return vim.api.nvim_eval(previous_converter) end
    return 1
  end
  local ok, err = pcall(function()
    local buf = vim.api.nvim_get_current_buf()
    local input = read(vim.v.fname_in)
    local output
    if vim.v.charconvert_from == encoding then
      states[buf], output = codec.snapshot(input)
    else
      output = encode(input, buf)
    end
    assert(vim.fn.writefile(vim.split(output, "\n", { plain = true }), vim.v.fname_out, "b") == 0,
      "could not write converted properties")
    if vim.v.charconvert_to == encoding then states[buf] = codec.snapshot(output, states[buf]) end
  end)
  if not ok then
    vim.schedule(function() vim.notify("Java properties: " .. tostring(err), vim.log.levels.ERROR) end)
  end
  return ok and 0 or 1
end

function M.setup()
  if M.initialized then return end
  M.initialized = true
  previous_converter = vim.o.charconvert
  vim.o.charconvert = "v:lua.require'custom.java_properties'.convert()"
  local properties = require("editorconfig").properties
  for _, name in ipairs({ "charset", "end_of_line", "insert_final_newline" }) do
    local apply = properties[name]
    properties[name] = function(buf, ...)
      if not states[buf] or vim.bo[buf].fileencoding ~= encoding then
        return apply(buf, ...)
      end
    end
  end
  local group = vim.api.nvim_create_augroup("java_properties_unicode", { clear = true })
  vim.api.nvim_create_autocmd("BufReadPre", {
    group = group,
    pattern = "*.properties",
    callback = function(event)
      states[event.buf] = nil
      vim.b[event.buf].java_properties_unicode = nil
      if vim.v.cmdarg:find("++enc", 1, true) then return end
      local ok, raw = pcall(read, event.file)
      if not ok or raw:find("\0", 1, true) then return end
      local _, replacements = codec.decode(raw)
      if #replacements == 0 then return end
      if vim.fn.exists("#nvim.editorconfig#BufWritePre") == 1 then
        vim.api.nvim_clear_autocmds({ group = "nvim.editorconfig", event = "BufWritePre", buffer = event.buf })
      end
      pending[event.buf] = vim.o.fileencodings
      vim.o.fileencodings = encoding .. "," .. vim.o.fileencodings
    end,
  })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    pattern = "*.properties",
    callback = function(event)
      if pending[event.buf] then
        vim.o.fileencodings, pending[event.buf] = pending[event.buf], nil
      end
      if vim.bo[event.buf].fileencoding == encoding then
        vim.b[event.buf].java_properties_unicode = true
        vim.bo[event.buf].fixendofline = false
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(event) states[event.buf], pending[event.buf] = nil, nil end,
  })
end

return M
