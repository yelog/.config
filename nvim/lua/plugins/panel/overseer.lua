return {
  "stevearc/overseer.nvim",
  init = function()
    local runtime = require("services.runtime").setup()
    local panel = require("services.panel").setup({ runtime = runtime })

    vim.api.nvim_create_user_command("ServicesToggle", function()
      panel:toggle()
    end, { desc = "Toggle services panel", force = true })
    vim.api.nvim_create_user_command("ServicesOpen", function()
      panel:open()
    end, { desc = "Open services panel", force = true })
  end,
  config = function()
    require("overseer").setup({})
  end,
}
