return {
  "yelog/igit.nvim",
  dev = true,
  lazy = false, -- Register the interactive :igit abbreviation at startup.
  keys = {
    {
      "<D-g>",
      function()
        local igit = require("igit")
        if not igit.close() then
          igit.open()
        end
      end,
      mode = { "n", "t" },
      desc = "Toggle IGit",
    },
    {
      "<leader>gi",
      function()
        require("igit").open()
      end,
      desc = "IGit",
    },
    {
      "<D-S-H>",
      function()
        require("igit").open("log", { file = "%" })
      end,
      mode = { "n", "i", "t" },
      desc = "IGit Current File History",
    },
  },
  opts = {
    command = function()
      local result = vim.system({ vim.fn.expand("~/.local/bin/ig-use"), "path" }, { text = true }):wait(1000)
      if result.code ~= 0 then
        local message = vim.trim(result.stderr or "")
        error(message ~= "" and message or "Cannot resolve the selected IGit executable. Run ig-use status.", 0)
      end
      -- Keep pane navigation inside the embedded terminal at its edges.
      return { "/usr/bin/env", "KITTY_LISTEN_ON=", vim.trim(result.stdout or "") }
    end,
    command_alias = true,
    window = {
      layout = "float", -- "float", "left", "right", "bottom", "tab"
      width = 0.9,
      height = 0.85,
      border = "rounded",
    },
  },
}
