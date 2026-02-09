return {
  "tpope/vim-surround", --> type ysiw' to wrap the word with '' or type cs'` to change 'word' to `word`
  "tpope/vim-repeat",   --> repeat surround and so on
  {
    "ybian/smartim",    --> smart switch input method
    config = function()
      vim.g.smartim_default = "com.apple.keylayout.ABC"
    end
  },
  -- {
  --   "keaising/im-select.nvim",
  --   config = function()
  --     require('im_select').setup({
  --       -- IM will be set to `default_im_select` in `normal` mode
  --       -- For Windows/WSL, default: "1033", aka: English US Keyboard
  --       -- For macOS, default: "com.apple.keylayout.ABC", aka: US
  --       -- For Linux, default:
  --       --               "keyboard-us" for Fcitx5
  --       --               "1" for Fcitx
  --       --               "xkb:us::eng" for ibus
  --       -- You can use `im-select` or `fcitx5-remote -n` to get the IM's name
  --       default_im_select       = "com.apple.keylayout.ABC",
  --
  --       -- Can be binary's name, binary's full path, or a table, e.g. 'im-select',
  --       -- '/usr/local/bin/im-select' for binary without extra arguments,
  --       -- or { "AIMSwitcher.exe", "--imm" } for binary need extra arguments to work.
  --       -- For Windows/WSL, default: "im-select.exe"
  --       -- For macOS, default: "macism"
  --       -- For Linux, default: "fcitx5-remote" or "fcitx-remote" or "ibus"
  --       default_command         = "macism",
  --
  --       -- Restore the default input method state when the following events are triggered
  --       -- "VimEnter" and "FocusGained" were removed for causing problems, add it by your needs
  --       set_default_events      = { "InsertLeave", "CmdlineLeave", "FocusGained", "VimEnter" },
  --
  --       -- Restore the previous used input method state when the following events
  --       -- are triggered, if you don't want to restore previous used im in Insert mode,
  --       -- e.g. deprecated `disable_auto_restore = 1`, just let it empty
  --       -- as `set_previous_events = {}`
  --       set_previous_events     = { "InsertEnter" },
  --
  --       -- Show notification about how to install executable binary when binary missed
  --       keep_quiet_on_no_binary = false,
  --
  --       -- Async run `default_command` to switch IM or not
  --       async_switch_im         = true
  --     })
  --   end,
  -- },
  "dhruvasagar/vim-open-url", --> open brower with the url under the cursor
  {
    "airblade/vim-rooter",    --> Changes Vim working directory to project root
    config = function()
      -- airblade/vim-rooter
      vim.g.rooter_patterns = { ".git/" }
    end
  },
  {
    "monaqa/dial.nvim",
    config = function()
      vim.keymap.set("n", "<C-a>", function()
        require("dial.map").manipulate("increment", "normal")
      end)
      vim.keymap.set("n", "<C-x>", function()
        require("dial.map").manipulate("decrement", "normal")
      end)
      vim.keymap.set("n", "g<C-a>", function()
        require("dial.map").manipulate("increment", "gnormal")
      end)
      vim.keymap.set("n", "g<C-x>", function()
        require("dial.map").manipulate("decrement", "gnormal")
      end)
      vim.keymap.set("v", "<C-a>", function()
        require("dial.map").manipulate("increment", "visual")
      end)
      vim.keymap.set("v", "<C-x>", function()
        require("dial.map").manipulate("decrement", "visual")
      end)
      vim.keymap.set("v", "g<C-a>", function()
        require("dial.map").manipulate("increment", "gvisual")
      end)
      vim.keymap.set("v", "g<C-x>", function()
        require("dial.map").manipulate("decrement", "gvisual")
      end)
    end
  },
  -------------- decoration --------------
  "jeffkreeftmeijer/vim-numbertoggle", --> Toggles between hybrid and absolute line numbers automatically
}
