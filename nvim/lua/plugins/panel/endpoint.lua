return {
  "zerochae/endpoint.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  cmd = {
    "Endpoint",
  },
  config = function()
    require("endpoint").setup({
      -- New improved config structure (v1.1+)
      cache = {
        mode = "none", -- "none", "session", "persistent"
      },
      picker = {
        type = "snacks", -- "telescope", "vim_ui_select", "snacks"
        options = {
          telescope = { theme = "dropdown" },
          snacks = { preview = "file" },
        },
      },
      ui = {
        show_icons = true,
        show_method = true,
        methods = {
          GET = { icon = "📘", color = "TelescopeResultsNumber" },
          POST = { icon = "📗", color = "TelescopeResultsConstant" },
          PUT = { icon = "📙", color = "TelescopeResultsKeyword" },
          DELETE = { icon = "📕", color = "TelescopeResultsSpecialChar" },
          PATCH = { icon = "📒", color = "TelescopeResultsFunction" },
        },
      },
      frameworks = {
        rails = {
          display_format = "smart",
          show_action_annotation = true,
        },
      },
    })
  end,
}
