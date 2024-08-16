-- 保存当前文件打开和分屏状态
return {
  "rmagatti/auto-session",
  config = function()
    local opts = {
      log_level = "error",
      auto_session_enable_last_session = false,
      auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
      auto_session_enabled = true,
      auto_save_enabled = true,
      auto_restore_enabled = nil,
      auto_session_suppress_dirs = nil,
      auto_session_use_git_branch = nil,
      -- the configs below are lua only
      bypass_session_save_file_types = nil,
      -- pre_save_cmds = { "Neotree left close" },
      -- save_extra_cmds = {
      --   "Neotree left show"
      -- },
      -- post_restore_cmds = {
      --   "Neotree left show"
      -- },
      cwd_change_handling = {
        restore_upcoming_session = true,   -- already the default, no need to specify like this, only here as an example
        pre_cwd_changed_hook = nil,        -- already the default, no need to specify like this, only here as an example
        post_cwd_changed_hook = function() -- example refreshing the lualine status line _after_ the cwd changes
          require("lualine").refresh()     -- refresh lualine so the new session name is displayed in the status bar
        end,
      },
      bypass_session_save_file_types = nil, -- table: Bypass auto save when only buffer open is one of these file types, useful to ignore dashboards
      close_unsupported_windows = true,     -- boolean: Close windows that aren't backed by normal file
      args_allow_single_directory = true,   -- boolean Follow normal sesion save/load logic if launched with a single directory as the only argument
      args_allow_files_auto_save = false,   -- boolean|function Allow saving a session even when launched with a file argument (or multiple files/dirs). It does not load any existing session first. While you can just set this to true, you probably want to set it to a function that decides when to save a session when launched with file args. See documentation for more detail
      silent_restore = false,                -- Suppress extraneous messages and source the whole session, even if there's an error. Set to false to get the line number a restore error
    }

    require("auto-session").setup(opts)
  end,
}
