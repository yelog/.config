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
    {
      "<leader>gj",
      function()
        require("igit").next_hunk()
      end,
      desc = "Next Git Hunk",
    },
    {
      "<leader>gk",
      function()
        require("igit").prev_hunk()
      end,
      desc = "Previous Git Hunk",
    },
    {
      "<leader>gp",
      function()
        require("igit").preview_hunk()
      end,
      desc = "Preview Git Hunk",
    },
    {
      "<leader>gs",
      function()
        require("igit").stage_hunk()
      end,
      mode = { "n", "x" },
      desc = "Stage Git Hunk or Selection",
    },
    {
      "<leader>gu",
      function()
        require("igit").unstage_hunk()
      end,
      mode = { "n", "x" },
      desc = "Unstage Git Hunk or Selection",
    },
    {
      "<leader>gr",
      function()
        require("igit").reset_hunk()
      end,
      mode = { "n", "x" },
      desc = "Reset Git Hunk or Selection",
    },
    {
      "ih",
      function()
        require("igit").select_hunk()
      end,
      mode = { "x", "o" },
      desc = "Select Git Hunk",
    },
    {
      "<leader>gS",
      function()
        require("igit").stage_file()
      end,
      desc = "Stage Git File",
    },
    {
      "<leader>gU",
      function()
        require("igit").unstage_file()
      end,
      desc = "Unstage Git File",
    },
    {
      "<leader>gR",
      function()
        require("igit").reset_file()
      end,
      desc = "Reset Git File",
    },
    {
      "<leader>gb",
      function()
        require("igit").toggle_inline_blame()
      end,
      desc = "Toggle Inline Blame",
    },
    {
      "<leader>gB",
      function()
        require("igit").file_blame()
      end,
      desc = "Toggle File Blame",
    },
    {
      "<leader>gob",
      function()
        require("igit").browse()
      end,
      desc = "Open Current File in Browser",
    },
    {
      "<D-W>",
      function()
        require("igit").file_diff()
      end,
      desc = "Show diff of current file with HEAD",
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
    hunks = {
      enabled = true,
      debounce = 100,
      signs = {
        add = "▍",
        change = "▍",
        delete = "▶",
      },
      colors = {
        add = "#109900",
        change = "#0099FF",
        delete = "#747583",
      },
      staged_signs = true,
      priority = 6,
      max_file_size = 1024 * 1024,
    },
    status = {
      enabled = true,
      debounce = 100,
    },
    blame = {
      inline = {
        enabled = true,
        position = "eol",
        format = "{author}, {date}: {summary}",
        date_format = "%Y-%m-%d",
        delay = 100,
      },
      file = {
        format = "{date} {author}",
        date_format = "%Y/%m/%d",
      },
      colors = {
        age1 = "#252932",
        age2 = "#29354d",
        age3 = "#2d4266",
        age4 = "#315080",
        age5 = "#355e9b",
        uncommitted = "#574151",
      },
    },
    browse = {
      hosts = {},
    },
  },
}
