-- 把 buffer 并排显示在头部
return {
  {
    "akinsho/bufferline.nvim",
    -- version > v3.5.0 close icon will not show
    -- version = "main",
    dependencies = { "nvim-tree/nvim-web-devicons", version = "*" },
    config = function()
      vim.opt.termguicolors = true
      local bufferline = require("bufferline")
      bufferline.setup({
        options = {
          mode = "buffers", -- set to "tabs" to only show tabpages instead
          offsets = {
            { filetype = "NvimTree", text = "", padding = 1 },
            { filetype = "neo-tree", text = "", padding = 1 },
            { filetype = "Outline",  text = "", padding = 1 },
          },
          separator_style = "thin",
          -- hover = {
          -- 	enabled = true,
          -- 	delay = 200,
          -- 	reveal = { "close" },
          -- },
          indicator = {
            icon = "▎", -- this should be omitted if indicator style is not 'icon'
            style = "underline",
          },
          diagnostics = "nvim_lsp",
          max_name_length = 20,
          max_prefix_length = 13,
          tab_size = 20,
          diagnostics_indicator = function(count, level, diagnostics_dict, context)
            local s = " "
            for e, n in pairs(diagnostics_dict) do
              local sym = e == "error" and " "
                  or (e == "warning" and " " or " ")
              s = s .. n .. sym
            end
            return s
          end
        },
      })
    end,
  },
  "moll/vim-bbye", -- bdelete has problem, so use tghishis
}
