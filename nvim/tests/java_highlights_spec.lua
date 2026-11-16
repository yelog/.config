local test_file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:gsub("^@", ""), ":p")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
local theme_root = vim.fn.stdpath("data") .. "/lazy/jb.nvim"
assert(vim.uv.fs_stat(theme_root .. "/colors/jb.lua"), "the installed JB theme is required")
vim.opt.runtimepath:prepend(config_root)
vim.opt.runtimepath:append(theme_root)

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error(message .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual))
  end
end

local function highlight(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function other_highlights()
  local result = {}
  for name, attributes in pairs(vim.api.nvim_get_hl(0, {})) do
    if not name:match("%.java$") and not name:match("^Dap") and name ~= "LspCodeLens" then
      result[name] = attributes
    end
  end
  return result
end

local function luminance(color)
  local channels = {}
  for _, shift in ipairs({ 16, 8, 0 }) do
    local channel = math.floor(color / 2 ^ shift) % 256 / 255
    channels[#channels + 1] = channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4
  end
  return channels[1] * 0.2126 + channels[2] * 0.7152 + channels[3] * 0.0722
end

local roles = {
  variable = { "@variable.java", "@lsp.type.variable.java", "@lsp.typemod.variable.readonly.java" },
  parameter = { "@variable.parameter.java", "@lsp.type.parameter.java" },
  field = {
    "@variable.member.java",
    "@constant.java",
    "@lsp.type.property.java",
    "@lsp.type.enumMember.java",
    "@lsp.type.recordComponent.java",
    "@lsp.typemod.property.readonly.java",
    "@lsp.typemod.property.static.java",
  },
  type = {
    "@type.java",
    "@type.parameter.java",
    "@lsp.type.type.java",
    "@lsp.type.class.java",
    "@lsp.type.interface.java",
    "@lsp.type.enum.java",
    "@lsp.type.typeParameter.java",
  },
  declaration = {
    "@function.method.java",
    "@constructor.declaration.java",
    "@lsp.typemod.method.declaration.java",
  },
  call = { "@function.method.call.java", "@lsp.type.method.java" },
}

local function java_highlights()
  local result = {}
  for _, groups in pairs(roles) do
    for _, name in ipairs(groups) do
      result[name] = highlight(name)
    end
  end
  result["@lsp.typemod.method.static.java"] = highlight("@lsp.typemod.method.static.java")
  return result
end

dofile(config_root .. "/lua/plugins/style/jb.lua").config()

for _, background in ipairs({ "dark", "light", "dark" }) do
  vim.o.background = background
  vim.cmd("noautocmd colorscheme jb")
  local original_java = java_highlights()
  local original_other = other_highlights()
  local original_codelens = highlight("LspCodeLens")
  local original_variable = highlight("@variable").fg
  local original_field = highlight("@variable.member").fg

  vim.cmd.colorscheme("jb")
  local colors = {}
  local seen_colors = {}
  local background_luminance = luminance(highlight("Normal").bg)
  for role, groups in pairs(roles) do
    local color = highlight(groups[1]).fg
    assert(color, role .. " should have a foreground in " .. background .. " mode")
    assert(not seen_colors[color], role .. " should be visually distinct in " .. background .. " mode")
    seen_colors[color] = role
    colors[role] = color
    local foreground_luminance = luminance(color)
    local contrast = (math.max(foreground_luminance, background_luminance) + 0.05)
      / (math.min(foreground_luminance, background_luminance) + 0.05)
    assert(contrast >= 4.5, role .. " should maintain readable contrast in " .. background .. " mode")
    for _, name in ipairs(groups) do
      local attributes = highlight(name)
      assert_equal(color, attributes.fg, name .. " should match its Tree-sitter and semantic role")
      local expected = vim.deepcopy(original_java[name])
      expected.fg = color
      assert_equal(expected, attributes, name .. " should retain all existing non-color attributes")
    end
  end

  assert_equal(original_variable, colors.variable, "local variables should retain the theme gray")
  assert_equal(original_field, colors.field, "fields should retain the theme purple")
  assert(luminance(colors.call) > luminance(colors.declaration), "calls should use a lighter blue than declarations")
  local parameter_red = math.floor(colors.parameter / 0x10000)
  local parameter_green = math.floor(colors.parameter / 0x100) % 0x100
  local parameter_blue = colors.parameter % 0x100
  assert(
    parameter_red > parameter_green and parameter_green > parameter_blue,
    "parameters should use a coherent warm yellow in both backgrounds"
  )
  local type_red = math.floor(colors.type / 0x10000)
  local type_green = math.floor(colors.type / 0x100) % 0x100
  local type_blue = colors.type % 0x100
  assert(type_green > type_red and type_blue > type_red, "types should use a coherent teal in both backgrounds")
  for _, role in ipairs({ "declaration", "call" }) do
    assert(
      colors[role] % 0x100 > math.floor(colors[role] / 0x100) % 0x100,
      role .. " should remain blue in both backgrounds"
    )
  end

  local static_method = highlight("@lsp.typemod.method.static.java")
  local original_static = vim.deepcopy(original_java["@lsp.typemod.method.static.java"])
  original_static.fg = nil
  assert_equal(original_static, static_method, "static methods should retain attributes without overriding role colors")
  assert(static_method.italic, "static methods should retain italics")
  assert(highlight("@lsp.typemod.property.static.java").italic, "static fields should retain italics")
  assert(highlight("@lsp.type.variable.java").underline, "semantic variables should retain the theme underline")
  assert_equal(original_other, other_highlights(), "global and other language groups should remain unchanged")

  original_codelens.fg = 0x727782
  assert_equal(original_codelens, highlight("LspCodeLens"), "CodeLens should retain its existing styling")
  assert_equal(0xF0524F, highlight("DapBreakpoint").fg, "JB breakpoint colors should remain unchanged")
  assert(highlight("DapBreakpoint").bold, "JB breakpoints should remain bold")
  assert_equal(0x3C3225, highlight("DapStoppedLine").bg, "JB stopped-line styling should remain unchanged")

  local expected_java = java_highlights()
  vim.api.nvim_set_hl(0, "@lsp.type.parameter.java", { fg = "#FF0000" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.method.static.java", { fg = "#FF0000" })
  vim.cmd.colorscheme("jb")
  assert_equal(expected_java, java_highlights(), "theme reload should restore Java roles and modifier attributes")
  assert_equal(original_other, other_highlights(), "theme reload should preserve other language groups")
end

vim.cmd("noautocmd colorscheme default")
local default_highlights = vim.api.nvim_get_hl(0, {})
vim.cmd.colorscheme("default")
assert_equal(default_highlights, vim.api.nvim_get_hl(0, {}), "other colorschemes should remain unchanged")

print("java-highlights-tests: ok (dark, light, dark reload; role contrast >= 4.5:1)")
