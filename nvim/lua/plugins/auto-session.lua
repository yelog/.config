-- 保存当前文件打开和分屏状态
return {
  {
    "rmagatti/auto-session",
    config = function()
      local opts = {
        enabled = true,                                             -- Enables/disables auto creating, saving and restoring
        root_dir = vim.fn.stdpath "data" .. "/sessions/",           -- Root dir where sessions will be stored
        auto_save = true,                                           -- Enables/disables auto saving session on exit
        auto_restore = true,                                        -- Enables/disables auto restoring session on start
        auto_create = true,                                         -- Enables/disables auto creating new session files. Can take a function that should return true/false if a new session file should be created or not
        suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" }, -- Suppress session restore/create in certain directories
        allowed_dirs = nil,                                         -- Allow session restore/create in certain directories
        auto_restore_last_session = false,                          -- On startup, loads the last saved session if session for cwd does not exist
        git_use_branch_name = false,                                -- Include git branch name in session name
        git_auto_restore_on_branch_change = false,                  -- Should we auto-restore the session when the git branch changes. Requires git_use_branch_name
        lazy_support = true,                                        -- Automatically detect if Lazy.nvim is being used and wait until Lazy is done to make sure session is restored correctly. Does nothing if Lazy isn't being used. Can be disabled if a problem is suspected or for debugging
        bypass_save_filetypes = nil,                                -- List of filetypes to bypass auto save when the only buffer open is one of the file types listed, useful to ignore dashboards
        close_unsupported_windows = true,                           -- Close windows that aren't backed by normal file before autosaving a session
        args_allow_single_directory = true,                         -- Follow normal session save/load logic if launched with a single directory as the only argument
        args_allow_files_auto_save = false,                         -- Allow saving a session even when launched with a file argument (or multiple files/dirs). It does not load any existing session first. While you can just set this to true, you probably want to set it to a function that decides when to save a session when launched with file args. See documentation for more detail
        continue_restore_on_error = true,                           -- Keep loading the session even if there's an error
        show_auto_restore_notif = false,                            -- Whether to show a notification when auto-restoring
        cwd_change_handling = false,                                -- Follow cwd changes, saving a session before change and restoring after
        lsp_stop_on_restore = false,                                -- Should language servers be stopped when restoring a session. Can also be a function that will be called if set. Not called on autorestore from startup
        restore_error_handler = nil,                                -- Called when there's an error restoring. By default, it ignores fold errors otherwise it displays the error and returns false to disable auto_save
        purge_after_minutes = nil,                                  -- Sessions older than purge_after_minutes will be deleted asynchronously on startup, e.g. set to 14400 to delete sessions that haven't been accessed for more than 10 days, defaults to off (no purging), requires >= nvim 0.10
        log_level = "error",                                        -- Sets the log level of the plugin (debug, info, warn, error).

        session_lens = {
          load_on_setup = true, -- Initialize on startup (requires Telescope)
          picker_opts = nil,  -- Table passed to Telescope / Snacks to configure the picker. See below for more information
          mappings = {
            -- Mode can be a string or a table, e.g. {"i", "n"} for both insert and normal mode
            delete_session = { "i", "<C-D>" },
            alternate_session = { "i", "<C-S>" },
            copy_session = { "i", "<C-Y>" },
          },

          session_control = {
            control_dir = vim.fn.stdpath "data" .. "/auto_session/", -- Auto session control dir, for control files, like alternating between two sessions with session-lens
            control_filename = "session_control.json",             -- File name of the session control file
          },
        },
      }

      require("auto-session").setup(opts)
    end,
  },
  -- {
  --   'stevearc/resession.nvim',
  --   opts = {
  --     autosave = {
  --       enabled = true,
  --       interval = 60,
  --       notify = true,
  --     },
  --   },
  --   config = function(_, opts)
  --     local resession = require("resession")
  --     resession.setup()
  --     -- Resession does NOTHING automagically, so we have to set up some keymaps
  --     vim.keymap.set("n", "<leader>ss", resession.save)
  --     vim.keymap.set("n", "<leader>sl", resession.load)
  --     vim.keymap.set("n", "<leader>sd", resession.delete)
  --   end,
  -- }
}
