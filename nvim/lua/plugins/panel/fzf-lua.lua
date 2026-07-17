return {
  "ibhagwan/fzf-lua",
  -- optional for icon support
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require('fzf-lua').setup({
      previewers = {
        builtin = {
          render_markdown = { enabled = false, filetypes = { ["markdown"] = true } }
        }
      }
    })
  end
}
