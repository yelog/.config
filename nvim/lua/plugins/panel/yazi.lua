---@type LazySpec
return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  dependencies = {
    -- check the installation instructions at
    -- https://github.com/folke/snacks.nvim
    "folke/snacks.nvim"
  },
  keys = {
    -- 👇 in this section, choose your own keymappings!
    -- {
    --   "<leader>-",
    --   mode = { "n", "v" },
    --   "<cmd>Yazi<cr>",
    --   desc = "Open yazi at the current file",
    -- },
    -- {
    --   -- Open in the current working directory
    --   "<leader>cw",
    --   "<cmd>Yazi cwd<cr>",
    --   desc = "Open the file manager in nvim's working directory",
    -- },
    -- {
    --   "<D-1>",
    --   "<cmd>Yazi toggle<cr>",
    --   desc = "Resume the last yazi session",
    -- },
  },
  ---@type YaziConfig | {}
  opts = {
    -- if you want to open yazi instead of netrw, see below for more info
    open_for_directories = false,
    keymaps = {
      show_help = "?",
    },
  },
  -- 👇 if you use `open_for_directories=true`, this is recommended
  init = function()
    -- GUI/long-running Neovim instances may not inherit Homebrew's PATH.
    local paths = vim.split(vim.env.PATH or "", ":", { plain = true })
    for _, path in ipairs({ "/opt/homebrew/sbin", "/opt/homebrew/bin" }) do
      if vim.fn.isdirectory(path) == 1 and not vim.tbl_contains(paths, path) then
        table.insert(paths, 1, path)
      end
    end
    vim.env.PATH = table.concat(paths, ":")

    -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
    -- vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
}
