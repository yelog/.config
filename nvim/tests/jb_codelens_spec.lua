vim.cmd.colorscheme("jb")

local codelens = vim.api.nvim_get_hl(0, { name = "LspCodeLens", link = false })

assert(codelens.fg == 0x727782,
  "JB CodeLens text should use the no-background inline-hint gray")
assert(codelens.underline,
  "JB CodeLens text should retain the theme underline")
assert(codelens.sp == 0x868A91,
  "JB CodeLens text should retain the theme underline color")

print("jb-codelens-tests: ok")
