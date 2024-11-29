-- 底部状态栏
return {
  -- {
  --
  --   "nvim-lualine/lualine.nvim",
  --   dependencies = { "nvim-tree/nvim-web-devicons" },
  --   config = function()
  --     require("lualine").setup({
  --       options = {
  --         icons_enabled = true,
  --         theme = "auto",
  --         component_separators = { left = "", right = "" },
  --         section_separators = { left = "", right = "" },
  --         disabled_filetypes = {
  --           statusline = {},
  --           winbar = {},
  --         },
  --         ignore_focus = {},
  --         always_divide_middle = true,
  --         globalstatus = true,
  --         refresh = {
  --           statusline = 1000,
  --         },
  --       },
  --       sections = {
  --         lualine_a = { "mode" },
  --         lualine_b = { "branch", "diff", "diagnostics" },
  --         -- lualine_c = { require("auto-session.lib").current_session_name },
  --         lualine_c = {},
  --         lualine_x = { "encoding", "fileformat", "filetype" },
  --         lualine_y = { "progress" },
  --         lualine_z = { "location" },
  --       },
  --       inactive_section = {},
  --       tabline = {},
  --       winbar = {},
  --       inactive_winbar = {},
  --       extensions = {},
  --     })
  --   end,
  -- },
  {
    "rebelot/heirline.nvim", -- https://github.com/rebelot/heirline.nvim
    -- You can optionally lazy-load heirline on UiEnter
    -- to make sure all required plugins and colorschemes are loaded before setup
    -- event = "UiEnter",
    -- opts = function(_, opts)
    --   return opts
    -- end
    config = function()
      local conditions = require("heirline.conditions")
      local utils = require("heirline.utils")
      local colors = {
        bright_bg = utils.get_highlight("Folded").bg,
        bright_fg = utils.get_highlight("Folded").fg,
        red = utils.get_highlight("DiagnosticError").fg,
        dark_red = utils.get_highlight("DiffDelete").bg,
        green = utils.get_highlight("String").fg,
        blue = utils.get_highlight("Function").fg,
        gray = utils.get_highlight("NonText").fg,
        orange = utils.get_highlight("Constant").fg,
        purple = utils.get_highlight("Statement").fg,
        cyan = utils.get_highlight("Special").fg,
        diag_warn = utils.get_highlight("DiagnosticWarn").fg,
        diag_error = utils.get_highlight("DiagnosticError").fg,
        diag_hint = utils.get_highlight("DiagnosticHint").fg,
        diag_info = utils.get_highlight("DiagnosticInfo").fg,
        git_del = utils.get_highlight("diffDeleted").fg,
        git_add = utils.get_highlight("diffAdded").fg,
        git_change = utils.get_highlight("diffChanged").fg,
      }
      local Git = {
        condition = conditions.is_git_repo,

        init = function(self)
          self.status_dict = vim.b.gitsigns_status_dict
          self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or
              self.status_dict.changed ~= 0
        end,

        hl = { fg = "#ef9020" },


        { -- git branch name
          provider = function(self)
            return " " .. self.status_dict.head
          end,
          hl = { bold = true, fg = "#ef9020" }
        },
        -- You could handle delimiters, icons and counts similar to Diagnostics
        {
          condition = function(self)
            return self.has_changes
          end,
          provider = "("
        },
        {
          provider = function(self)
            local count = self.status_dict.added or 0
            return count > 0 and ("+" .. count)
          end,
          hl = "GitSignsAdd",
        },
        {
          provider = function(self)
            local count = self.status_dict.removed or 0
            return count > 0 and ("-" .. count)
          end,
          hl = "GitSignsDelete",
        },
        {
          provider = function(self)
            local count = self.status_dict.changed or 0
            return count > 0 and ("~" .. count)
          end,
          hl = "GitSignsChange",
        },
        {
          condition = function(self)
            return self.has_changes
          end,
          provider = ")",
        },
        on_click = {
          callback = function()
            -- If you want to use Fugitive:
            -- vim.cmd("G")

            -- If you prefer Lazygit
            -- use vim.defer_fn() if the callback requires
            -- opening of a floating window
            -- (this also applies to telescope)
            vim.defer_fn(function()
              vim.cmd("LazyGit")
            end, 100)
          end,
          name = "heirline_git",
        },
      }

      local LSPActive = {
        condition = conditions.lsp_attached,
        update = { 'LspAttach', 'LspDetach' },

        -- You can keep it simple,
        -- provider = " [LSP]",

        -- Or complicate things a bit and get the servers names
        provider = function()
          local names = {}
          for i, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
            table.insert(names, server.name)
          end
          return " [" .. table.concat(names, " ") .. "]"
        end,
        hl = { fg = "green", bold = true },
      }

      local ViMode = {
        -- get vim current mode, this information will be required by the provider
        -- and the highlight functions, so we compute it only once per component
        -- evaluation and store it as a component attribute
        init = function(self)
          self.mode = vim.fn.mode(1) -- :h mode()
        end,
        -- Now we define some dictionaries to map the output of mode() to the
        -- corresponding string and color. We can put these into `static` to compute
        -- them at initialisation time.
        static = {
          mode_names = { -- change the strings if you like it vvvvverbose!
            n = "N",
            no = "N?",
            nov = "N?",
            noV = "N?",
            ["no\22"] = "N?",
            niI = "Ni",
            niR = "Nr",
            niV = "Nv",
            nt = "Nt",
            v = "V",
            vs = "Vs",
            V = "V_",
            Vs = "Vs",
            ["\22"] = "^V",
            ["\22s"] = "^V",
            s = "S",
            S = "S_",
            ["\19"] = "^S",
            i = "I",
            ic = "Ic",
            ix = "Ix",
            R = "R",
            Rc = "Rc",
            Rx = "Rx",
            Rv = "Rv",
            Rvc = "Rv",
            Rvx = "Rv",
            c = "C",
            cv = "Ex",
            r = "...",
            rm = "M",
            ["r?"] = "?",
            ["!"] = "!",
            t = "T",
          },
          mode_colors = {
            n = "#5c92fa",
            i = "#009f4d",
            v = "cyan",
            V = "cyan",
            ["\22"] = "cyan",
            c = "orange",
            s = "purple",
            S = "purple",
            ["\19"] = "purple",
            R = "orange",
            r = "orange",
            ["!"] = "red",
            t = "red",
          }
        },
        -- We can now access the value of mode() that, by now, would have been
        -- computed by `init()` and use it to index our strings dictionary.
        -- note how `static` fields become just regular attributes once the
        -- component is instantiated.
        -- To be extra meticulous, we can also add some vim statusline syntax to
        -- control the padding and make sure our string is always at least 2
        -- characters long. Plus a nice Icon.
        provider = function(self)
          return " %2(" .. self.mode_names[self.mode] .. "%)"
        end,
        -- Same goes for the highlight. Now the foreground will change according to the current mode.
        hl = function(self)
          local mode = self.mode:sub(1, 1) -- get only the first mode character
          return { fg = self.mode_colors[mode], bold = true, }
        end,
        -- Re-evaluate the component only on ModeChanged event!
        -- Also allows the statusline to be re-evaluated when entering operator-pending mode
        update = {
          "ModeChanged",
          pattern = "*:*",
          callback = vim.schedule_wrap(function()
            vim.cmd("redrawstatus")
          end),
        },
      }


      -- Define a component to show the relative path
      local RelativePath = {
        provider = function()
          -- Get the current file's absolute path
          local filepath = vim.api.nvim_buf_get_name(0)
          -- Get the current working directory (project root)
          local cwd = vim.fn.getcwd()
          -- Return the relative path
          return vim.fn.fnamemodify(filepath, ":~:.")
        end,
        -- Optional: styling
        hl = { fg = "blue", bold = true },
      }

      -- Ensure you have nvim-web-devicons installed
      local devicons = require("nvim-web-devicons")

      -- Define a component to show the file icon
      local FileIcon = {
        provider = function()
          -- Get the current file name and extension
          local filename = vim.api.nvim_buf_get_name(0)
          local ext = vim.fn.fnamemodify(filename, ":e")
          local icon, icon_color = devicons.get_icon_color(filename, ext, { default = true })
          return icon or "" -- Default icon if none found
        end,
        hl = function()
          -- Get the icon color
          local filename = vim.api.nvim_buf_get_name(0)
          local ext = vim.fn.fnamemodify(filename, ":e")
          local _, icon_color = devicons.get_icon_color(filename, ext, { default = true })
          return { fg = icon_color, bold = true }
        end,
      }

      local FileType = {
        provider = function()
          return "[" .. string.upper(vim.bo.filetype) .. "]"
        end,
        hl = { fg = utils.get_highlight("Type").fg, bold = true },
      }

      local Space = {
        provider = " ", -- 使用显式的 3 个空格作为间距
      }

      -- I take no credits for this! 🦁
      local ScrollBar = {
        static = {
          sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }
          -- Another variant, because the more choice the better.
          -- sbar = { '🭶', '🭷', '🭸', '🭹', '🭺', '🭻' }
        },
        provider = function(self)
          local curr_line = vim.api.nvim_win_get_cursor(0)[1]
          local lines = vim.api.nvim_buf_line_count(0)
          local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
          return string.rep(self.sbar[i], 2)
        end,
        hl = { fg = "blue", bg = "bright_bg" },
      }

      -- The easy way.
      local Navic = {
        condition = function() return require("nvim-navic").is_available() end,
        provider = function()
          return require("nvim-navic").get_location({ highlight = true })
        end,
        update = 'CursorMoved'
      }


      local StatusLine = {
        ViMode,
        -- Space,
        -- FileIcon,
        Space,
        RelativePath,
        Space,
        Git,
        { provider = "%=" }, -- Center alignment
        Navic,
        Space,
        FileType,
        Space,
        LSPActive,
        ScrollBar
      }

      -- the winbar parameter is optional!
      require("heirline").setup({
        statusline = StatusLine,
        opts = {
          colors = colors,
        }
      })
    end
  }
}
