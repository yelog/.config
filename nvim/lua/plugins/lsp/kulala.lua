return {
  "mistweaverco/kulala.nvim",
  ft = { "http", "rest" },
  keys = {
    { "<leader>is", function() require("kulala").run() end, desc = "Send HTTP request", mode = { "n", "v" } },
    { "<leader>ia", function() require("kulala").run_all() end, desc = "Send all HTTP requests" },
    { "<leader>ir", function() require("kulala").replay() end, desc = "Replay HTTP request" },
    { "<leader>ib", function() require("kulala").scratchpad() end, desc = "Open HTTP scratchpad" },
    { "<leader>ie", function() require("kulala").set_selected_env() end, desc = "Select HTTP environment" },
    { "<leader>if", function() require("kulala").search() end, desc = "Find HTTP request" },
  },
  opts = {
    kulala_core = {
      timeout = 60000,
    },
    treesitter = {
      cli_path = "tree-sitter",
    },
    default_env = "dev",
    environment_scope = "g",
    response_format = {
      indent = 2,
      expand_tabs = true,
      sort_keys = false,
    },
    ui = {
      display_mode = "split",
      split_direction = "right",
      max_response_size = 262144,
      default_view = "body",
      default_winbar_panes = { "body", "headers", "verbose", "script_output", "report" },
      scratchpad_default_contents = {
        "# @name scratchpad",
        "GET https://echo.kulala.app/get",
      },
    },
    lsp = {
      enable = true,
      keymaps = false,
    },
    global_keymaps = false,
    kulala_keymaps = true,
  },
}
