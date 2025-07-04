return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    quickfile = { enabled = true },
    -- scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = {
      debounce = 200,            -- time in ms to wait before updating
      notify_jump = false,       -- show a notification when jumping
      notify_end = true,         -- show a notification when reaching the end
      foldopen = true,           -- open folds after jumping
      jumplist = true,           -- set jump point before jumping
      modes = { "n", "i", "c" }, -- modes to show references
      filter = function(buf)     -- what buffers to enable `snacks.words`
        return vim.g.snacks_words ~= false and vim.b[buf].snacks_words ~= false
      end,
    },
    styles = {
      notification = {
        -- wo = { wrap = true } -- Wrap notifications
      }
    },
    -- scroll = { -- 比较卡顿， 体验不好
    --   animate = {
    --     duration = { step = 15, total = 250 },
    --     easing = "linear",
    --   },
    --   -- faster animation when repeating scroll after delay
    --   animate_repeat = {
    --     delay = 100, -- delay in ms before using the repeat animation
    --     duration = { step = 5, total = 50 },
    --     easing = "linear",
    --   },
    --   -- what buffers to animate
    --   filter = function(buf)
    --     return vim.g.snacks_scroll ~= false and vim.b[buf].snacks_scroll ~= false and vim.bo[buf].buftype ~= "terminal"
    --   end,
    -- }
  },
  keys = {
    { "<leader>z",  function() Snacks.zen() end,                   desc = "Toggle Zen Mode" },
    { "<leader>Z",  function() Snacks.zen.zoom() end,              desc = "Toggle Zoom" },
    { "<leader>.",  function() Snacks.scratch() end,               desc = "Toggle Scratch Buffer" },
    { "<leader>S",  function() Snacks.scratch.select() end,        desc = "Select Scratch Buffer" },
    { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>bd", function() Snacks.bufdelete() end,             desc = "Delete Buffer" },
    { "<leader>cR", function() Snacks.rename.rename_file() end,    desc = "Rename File" },
    { "<leader>gB", function() Snacks.gitbrowse() end,             desc = "Git Browse" },
    { "<leader>gb", function() Snacks.git.blame_line() end,        desc = "Git Blame Line" },
    { "<leader>gf", function() Snacks.lazygit.log_file() end,      desc = "Lazygit Current File History" },
    { "<leader>gg", function() Snacks.lazygit() end,               desc = "Lazygit" },
    -- { "<D-g>",      function() Snacks.lazygit() end,         desc = "Toggle Lazygit" },
    { "<leader>gl", function() Snacks.lazygit.log() end,           desc = "Lazygit Log (cwd)" },
    -- { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git Log" },
    { "<leader>fi", function() Snacks.picker.icons() end,          desc = "Icons" },
    { "<leader>fj", function() Snacks.picker.jumps() end,          desc = "Jumps" },
    { "<leader>un", function() Snacks.notifier.hide() end,         desc = "Dismiss All Notifications" },
    { "<c-/>",      function() Snacks.terminal() end,              desc = "Toggle Terminal" },
    { "<c-_>",      function() Snacks.terminal() end,              desc = "which_key_ignore" },
    -- { "]]",         function() Snacks.words.jump(vim.v.count1) end,       desc = "Next Reference",              mode = { "n", "t" } },
    -- { "[[",         function() Snacks.words.jump(-vim.v.count1) end,      desc = "Prev Reference",              mode = { "n", "t" } },
    -- LSP
    -- { "gd",         function() Snacks.picker.lsp_definitions() end,       desc = "Goto Definition" },
    -- { "gD",         function() Snacks.picker.lsp_declarations() end,      desc = "Goto Declaration" },
    -- { "gu",         function() Snacks.picker.lsp_references() end,        nowait = true,                        desc = "References" },
    -- { "gI",         function() Snacks.picker.lsp_implementations() end,   desc = "Goto Implementation" },
    -- { "gy",         function() Snacks.picker.lsp_type_definitions() end,  desc = "Goto T[y]pe Definition" },
    -- { "<leader>ss", function() Snacks.picker.lsp_symbols() end,           desc = "LSP Symbols" },
    -- { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
    {
      "<leader>N",
      desc = "Neovim News",
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
          },
        })
      end,
    }
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map(
          "<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.dim():map("<leader>uD")
      end,
    })
  end,
}
