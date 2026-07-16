return {
  "stevearc/overseer.nvim",
  init = function()
    local runtime = require("services.runtime").setup()
    require("services.lifecycle").setup(runtime)
    local panel = require("services.panel").setup({ runtime = runtime })

    vim.api.nvim_create_user_command("ServicesToggle", function()
      panel:toggle()
    end, { desc = "Toggle services panel", force = true })
    vim.api.nvim_create_user_command("ServicesOpen", function()
      panel:open()
    end, { desc = "Open services panel", force = true })
  end,
  config = function()
    require("overseer").setup({
      output = {
        use_terminal = true,
        preserve_output = true,
      },
      task_list = {
        direction = "bottom",
        min_height = 10,
        max_height = { 24, 0.35 },
      },
    })
  end,
}
