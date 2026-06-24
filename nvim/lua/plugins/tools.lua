return {
  "tpope/vim-surround", --> type ysiw' to wrap the word with '' or type cs'` to change 'word' to `word`
  "tpope/vim-repeat",   --> repeat surround and so on
  {
    "keaising/im-select.nvim",
    config = function()
      local default_im = "com.apple.keylayout.ABC"

      require("im_select").setup({
        default_im_select = default_im,
        default_command = "macism",
        set_default_events = { "InsertLeave", "CmdlineLeave", "VimEnter" },
        set_previous_events = { "InsertEnter" },
        keep_quiet_on_no_binary = false,
        async_switch_im = false,
      })

      local function force_default_im_in_normal_mode()
        local mode = vim.api.nvim_get_mode().mode

        if mode:match("^[nvsV\022]") then
          vim.fn.jobstart({ "macism", default_im }, { detach = true })
        end
      end

      vim.api.nvim_create_autocmd({ "FocusGained", "VimEnter" }, {
        callback = force_default_im_in_normal_mode,
      })
    end,
  },
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
