local M = {}

local palettes = {
  dark = {
    parameter = "#C9B477",
    type = "#6FAFA5",
    declaration = "#56A8F5",
    call = "#82B7E8",
  },
  light = {
    parameter = "#806116",
    type = "#246C73",
    declaration = "#245EAE",
    call = "#3B6C9E",
  },
}

local role_groups = {
  variable = {
    "@variable",
    "@lsp.type.variable",
    "@lsp.typemod.variable.readonly",
  },
  parameter = {
    "@variable.parameter",
    "@lsp.type.parameter",
  },
  field = {
    "@variable.member",
    "@constant",
    "@lsp.type.property",
    "@lsp.type.enumMember",
    "@lsp.type.recordComponent",
    "@lsp.typemod.property.readonly",
    "@lsp.typemod.property.static",
  },
  type = {
    "@type",
    "@type.parameter",
    "@lsp.type.type",
    "@lsp.type.class",
    "@lsp.type.interface",
    "@lsp.type.enum",
    "@lsp.type.typeParameter",
  },
  declaration = {
    "@function.method",
    "@constructor.declaration",
    "@lsp.typemod.method.declaration",
  },
  call = {
    "@function.method.call",
    "@lsp.type.method",
  },
}

function M.apply_jb_highlights()
  local colors = vim.tbl_extend("force", {
    variable = vim.api.nvim_get_hl(0, { name = "@variable", link = false }).fg,
    field = vim.api.nvim_get_hl(0, { name = "@variable.member", link = false }).fg,
  }, palettes[vim.o.background])

  for role, groups in pairs(role_groups) do
    for _, name in ipairs(groups) do
      local group = name .. ".java"
      local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
      highlight.fg = colors[role]
      vim.api.nvim_set_hl(0, group, highlight)
    end
  end

  local static_method = "@lsp.typemod.method.static.java"
  local highlight = vim.api.nvim_get_hl(0, { name = static_method, link = false })
  highlight.fg = nil
  vim.api.nvim_set_hl(0, static_method, highlight)
end

return M
