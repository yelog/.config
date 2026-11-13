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
  -- {
  --   'b0o/incline.nvim',
  --   depencencies = {
  --     'nvim-tree/nvim-web-devicons',
  --     'SmiteshP/nvim-navic'
  --   },
  --   config = function()
  --     local helpers = require 'incline.helpers'
  --     local devicons = require 'nvim-web-devicons'
  --     local navic = require 'nvim-navic'
  --     require('incline').setup {
  --       debounce_threshold = {
  --         falling = 50,
  --         rising = 10
  --       },
  --       hide = {
  --         cursorline = false,
  --         focused_win = false,
  --         only_win = false
  --       },
  --       highlight = {
  --         groups = {
  --           InclineNormal = {
  --             default = true,
  --             group = "NormalFloat"
  --           },
  --           InclineNormalNC = {
  --             default = true,
  --             group = "NormalFloat"
  --           }
  --         }
  --       },
  --       ignore = {
  --         buftypes = "special",
  --         filetypes = {},
  --         floating_wins = true,
  --         unlisted_buffers = true,
  --         wintypes = "special"
  --       },
  --       render = function(props)
  --         local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
  --         if filename == '' then
  --           filename = '[No Name]'
  --         end
  --         local ft_icon, ft_color = devicons.get_icon_color(filename)
  --         local modified = vim.bo[props.buf].modified
  --         local res = {
  --           ft_icon and { ' ', ft_icon, ' ', guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or '',
  --           ' ',
  --           { filename, gui = modified and 'bold,italic' or 'bold' },
  --           guibg = '#44406e',
  --         }
  --         if props.focused then
  --           for _, item in ipairs(navic.get_data(props.buf) or {}) do
  --             table.insert(res, {
  --               { ' > ',     group = 'NavicSeparator' },
  --               { item.icon, group = 'NavicIcons' .. item.type },
  --               { item.name, group = 'NavicText' },
  --             })
  --           end
  --         end
  --         table.insert(res, ' ')
  --         return res
  --       end,
  --       window = {
  --         margin = {
  --           horizontal = 1,
  --           vertical = 0
  --         },
  --         options = {
  --           signcolumn = "no",
  --           wrap = false
  --         },
  --         overlap = {
  --           borders = true,
  --           statusline = false,
  --           tabline = false,
  --           winbar = false
  --         },
  --         padding = 0,
  --         padding_char = " ",
  --         placement = {
  --           horizontal = "right",
  --           vertical = "top"
  --         },
  --         width = "fit",
  --         winhighlight = {
  --           active = {
  --             EndOfBuffer = "None",
  --             Normal = "InclineNormal",
  --             Search = "None"
  --           },
  --           inactive = {
  --             EndOfBuffer = "None",
  --             Normal = "InclineNormalNC",
  --             Search = "None"
  --           }
  --         },
  --         zindex = 50
  --       }
  --     }
  --   end,
  --   -- Optional: Lazy load Incline
  --   event = 'VeryLazy',
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
      local function highlight_color(name, field, fallbacks)
        local color = utils.get_highlight(name)[field]
        if color then
          return color
        end

        for _, fallback in ipairs(fallbacks) do
          color = utils.get_highlight(fallback)[field]
          if color then
            return color
          end
        end
      end

      local function setup_colors()
        return {
          bright_bg = highlight_color("Folded", "bg", { "StatusLine", "Normal" }),
          bright_fg = highlight_color("Folded", "fg", { "Normal" }),
          red = highlight_color("DiagnosticError", "fg", { "ErrorMsg", "Normal" }),
          dark_red = highlight_color("DiffDelete", "bg", { "StatusLine", "Normal" }),
          green = highlight_color("String", "fg", { "Normal" }),
          blue = highlight_color("Function", "fg", { "Normal" }),
          gray = highlight_color("NonText", "fg", { "Normal" }),
          orange = highlight_color("Constant", "fg", { "Normal" }),
          purple = highlight_color("Statement", "fg", { "Normal" }),
          cyan = highlight_color("Special", "fg", { "Normal" }),
          diag_warn = highlight_color("DiagnosticWarn", "fg", { "Normal" }),
          diag_error = highlight_color("DiagnosticError", "fg", { "Normal" }),
          diag_hint = highlight_color("DiagnosticHint", "fg", { "Normal" }),
          diag_info = highlight_color("DiagnosticInfo", "fg", { "Normal" }),
          git_del = highlight_color("diffDeleted", "fg", { "IgitHunkDelete", "DiagnosticError" }),
          git_add = highlight_color("diffAdded", "fg", { "IgitHunkAdd", "String" }),
          git_change = highlight_color("diffChanged", "fg", { "IgitHunkChange", "Function" }),
        }
      end

      local colors = setup_colors()
      local Git = {
        condition = function()
          local loaded, igit = pcall(require, "igit")
          return loaded and igit.status() ~= nil
        end,

        init = function(self)
          local loaded, igit = pcall(require, "igit")
          self.status_dict = loaded and igit.status(self.bufnr) or nil
          local counts = self.status_dict and self.status_dict.unstaged or {}
          self.has_changes = (counts.added or 0) ~= 0 or (counts.removed or 0) ~= 0 or
              (counts.changed or 0) ~= 0
        end,

        hl = { fg = "#ef9020" },
        update = {
          "BufEnter", "BufWritePost", "TextChanged", "TextChangedI", "FocusGained", "User",
        },


        { -- git branch name
          provider = function(self)
            return " " .. (self.status_dict and self.status_dict.branch or "")
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
            local counts = self.status_dict and self.status_dict.unstaged or {}
            local count = counts.added or 0
            return count > 0 and ("+" .. count)
          end,
          hl = "IgitHunkAdd",
        },
        {
          provider = function(self)
            local counts = self.status_dict and self.status_dict.unstaged or {}
            local count = counts.removed or 0
            return count > 0 and ("-" .. count)
          end,
          hl = "IgitHunkDelete",
        },
        {
          provider = function(self)
            local counts = self.status_dict and self.status_dict.unstaged or {}
            local count = counts.changed or 0
            return count > 0 and ("~" .. count)
          end,
          hl = "IgitHunkChange",
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
      -- local FileIcon = {
      --   provider = function()
      --     -- Get the current file name and extension
      --     local filename = vim.api.nvim_buf_get_name(0)
      --     local ext = vim.fn.fnamemodify(filename, ":e")
      --     local icon, icon_color = devicons.get_icon_color(filename, ext, { default = true })
      --     return icon or "" -- Default icon if none found
      --   end,
      --   hl = function()
      --     -- Get the icon color
      --     local filename = vim.api.nvim_buf_get_name(0)
      --     local ext = vim.fn.fnamemodify(filename, ":e")
      --     local _, icon_color = devicons.get_icon_color(filename, ext, { default = true })
      --     return { fg = icon_color, bold = true }
      --   end,
      -- }
      local FileIcon = {
        init = function(self)
          local filename = self.filename
          local extension = vim.fn.fnamemodify(filename, ":e")
          self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(filename, extension,
            { default = true })
        end,
        provider = function(self)
          return self.icon and (self.icon .. " ")
        end,
        hl = function(self)
          return { fg = self.icon_color }
        end
      }

      local FileType = {
        provider = function()
          return "[" .. string.upper(vim.bo.filetype) .. "]"
        end,
        hl = { fg = utils.get_highlight("Type").fg, bold = true },
      }

      local Space = {
        provider = " ", -- 使用显式的 1 个空格作为间距
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

      local InlineBlame = {
        condition = function()
          local loaded, igit = pcall(require, "igit")
          return loaded and igit.blame_statusline() ~= ""
        end,
        provider = function()
          local loaded, igit = pcall(require, "igit")
          return loaded and igit.blame_statusline() or ""
        end,
        hl = { fg = "gray" },
        update = {
          "CursorMoved",
          "CursorMovedI",
          "BufEnter",
          "TextChanged",
          "TextChangedI",
          "User",
        },
      }

      local function service_summary()
          local runtime = require("services.runtime").instance()
          local lifecycle = require("services.lifecycle")
          return require("services.status").summary(runtime:list(), lifecycle.shutdown_status())
      end

      local ServiceStatus = {
        init = function(self) self.summary = service_summary() end,
        condition = function() return service_summary() ~= nil end,
        provider = function(self) return " " .. self.summary.text .. " " end,
        hl = function(self)
          local color = {
            idle = colors.gray,
            starting = colors.blue,
            running = colors.green,
            closing = colors.orange,
            stopping = colors.orange,
            failed = colors.red,
            force = colors.red,
          }
          return { fg = color[self.summary.kind], bold = self.summary.kind ~= "idle" }
        end,
        update = { "User", pattern = "ServicesStatusChanged" },
      }


      local StatusLine = {
        hl = { bg = "NONE" }, -- 背景色设置为 NONE，让背景透明
        ViMode,
        -- Space,
        -- FileIcon,
        Space,
        RelativePath,
        Space,
        Git,
        Space,
        InlineBlame,
        { provider = "%=" }, -- Center alignment
        ServiceStatus,
        Navic,
        Space,
        FileType,
        Space,
        -- LSPActive,
        ScrollBar
      }

      -- we redefine the filename component, as we probably only want the tail and not the relative path
      local TablineFileName = {
        provider = function(self)
          -- self.filename will be defined later, just keep looking at the example!
          local filename = self.filename
          filename = filename == "" and "[No Name]" or vim.fn.fnamemodify(filename, ":t")
          return filename
        end,
        hl = function(self)
          return { bold = self.is_active or self.is_visible, italic = true }
        end,
      }

      -- this looks exactly like the FileFlags component that we saw in
      -- #crash-course-part-ii-filename-and-friends, but we are indexing the bufnr explicitly
      -- also, we are adding a nice icon for terminal buffers.
      local TablineFileFlags = {
        {
          condition = function(self)
            return vim.api.nvim_get_option_value("modified", { buf = self.bufnr })
          end,
          provider = "[+]",
          hl = { fg = "green" },
        },
        {
          condition = function(self)
            return not vim.api.nvim_get_option_value("modifiable", { buf = self.bufnr })
                or vim.api.nvim_get_option_value("readonly", { buf = self.bufnr })
          end,
          provider = function(self)
            if vim.api.nvim_get_option_value("buftype", { buf = self.bufnr }) == "terminal" then
              return "  "
            else
              return ""
            end
          end,
          hl = { fg = "orange" },
        },
      }

      -- Here the filename block finally comes together
      local TablineFileNameBlock = {
        init = function(self)
          self.filename = vim.api.nvim_buf_get_name(self.bufnr)
        end,
        -- 当 Git 状态变化或缓冲区切换/写入/返回焦点/终端关闭时刷新
        update = { "User", "BufEnter", "BufWritePost", "TextChanged", "TextChangedI", "FocusGained", "TermClose", "VimResume" },
        hl = function(self)
          -- 获取当前 buf 文件在 git 中的状态（逐个 buffer）
          local underline = self.is_active and true or false

          -- 状态查询只读取 IGit 的异步缓存，不在这里执行 Git 子进程。
          local tick = vim.api.nvim_buf_get_changedtick(self.bufnr)
          local loaded, igit = pcall(require, "igit")
          local current = loaded and igit.status(self.bufnr) or nil
          local gen = tostring(vim.g._heirline_git_generation or 0)
            .. ":" .. tostring(current and current.generation or 0)
          local ok_cache, cache = pcall(vim.api.nvim_buf_get_var, self.bufnr, "_heirline_tab_git_cache")
          if ok_cache and type(cache) == "table"
              and cache.tick == tick
              and cache.gen == gen
              and cache.filename == self.filename then
            return { fg = cache.fg, bold = true, underline = underline }
          end

          local fg = nil
          if current and not current.ignored then
            if current.file_state == "added" then
              fg = colors.git_add
            elseif current.modified then
              fg = colors.git_change
            end
          end

          -- 写入缓存
          pcall(vim.api.nvim_buf_set_var, self.bufnr, "_heirline_tab_git_cache", {
            tick = tick,
            gen = gen,
            filename = self.filename,
            fg = fg,
          })

          return { fg = fg, bold = true, underline = underline }
        end,
        on_click = {
          callback = function(_, minwid, _, button)
            if (button == "m") then -- close on mouse middle click
              vim.schedule(function()
                vim.api.nvim_buf_delete(minwid, { force = false })
              end)
            else
              vim.api.nvim_win_set_buf(0, minwid)
            end
          end,
          minwid = function(self)
            return self.bufnr
          end,
          name = "heirline_tabline_buffer_callback",
        },
        -- TablineBufnr, // buffer number
        FileIcon, -- turns out the version defined in #crash-course-part-ii-filename-and-friends can be reutilized as is here!
        TablineFileName,
        TablineFileFlags,
      }

      -- a nice "x" button to close the buffer
      -- local TablineCloseButton = {
      --   condition = function(self)
      --     return not vim.api.nvim_get_option_value("modified", { buf = self.bufnr })
      --   end,
      --   { provider = " " },
      --   {
      --     provider = "x",
      --     hl = { fg = "gray" },
      --     on_click = {
      --       callback = function(_, minwid)
      --         vim.schedule(function()
      --           vim.api.nvim_buf_delete(minwid, { force = false })
      --           vim.cmd.redrawtabline()
      --         end)
      --       end,
      --       minwid = function(self)
      --         return self.bufnr
      --       end,
      --       name = "heirline_tabline_close_buffer_callback",
      --     },
      --   },
      -- }

      -- The final touch! 文字和左右两侧的填充背景色
      local function tabline_highlight(self)
        local normal = utils.get_highlight("Normal")
        local tabline = utils.get_highlight("TabLine")
        if not self.is_active then
          return { fg = tabline.fg or normal.fg, bg = tabline.bg or normal.bg }
        end

        local selected = utils.get_highlight("PmenuSel")
        local tabline_selected = utils.get_highlight("TabLineSel")
        return {
          -- PmenuSel is a completion-menu highlight; use its background only.
          fg = tabline_selected.fg or normal.fg or tabline.fg,
          bg = selected.bg
            or tabline_selected.bg
            or utils.get_highlight("CursorLine").bg
            or tabline.bg
            or normal.bg,
        }
      end

      local TablineBufferBlock = {
        hl = function(self)
          return tabline_highlight(self)
        end,
        { provider = " " },
        TablineFileNameBlock,
        { provider = " " },
      }

      -- and here we go
      local BufferLine = utils.make_buflist(
        TablineBufferBlock,
        { provider = "", hl = { fg = "gray" } }, -- left truncation, optional (defaults to "<")
        { provider = "", hl = { fg = "gray" } } -- right trunctation, also optional (defaults to ...... yep, ">")
      -- by the way, open a lot of buffers and try clicking them ;)
      )
      local TabLineOffset = {
        condition = function(self)
          local win = vim.api.nvim_tabpage_list_wins(0)[1]
          local bufnr = vim.api.nvim_win_get_buf(win)
          self.winid = win

          if vim.bo[bufnr].filetype == "neo-tree" then
            self.title = "neo-tree"
            return true
            -- elseif vim.bo[bufnr].filetype == "TagBar" then
            --     ...
          end
        end,

        provider = function(self)
          local title = self.title
          local width = vim.api.nvim_win_get_width(self.winid)
          local pad = math.ceil((width - #title) / 2)
          return string.rep(" ", pad) .. title .. string.rep(" ", pad)
        end,

        hl = function(self)
          if vim.api.nvim_get_current_win() == self.winid then
            -- return "TablineSel"
            return "Tabline"
          else
            return "Tabline"
          end
        end,
      }
      local Tabpage = {
        provider = function(self)
          return "%" .. self.tabnr .. "T " .. self.tabpage .. " %T"
        end,
        hl = function(self)
          if not self.is_active then
            return "TabLine"
          else
            -- return "TabLineSel"
            return "TabLine"
          end
        end,
      }

      -- local TabpageClose = {
      --   provider = "%999X  %X",
      --   hl = "TabLine",
      -- }

      local TabPages = {
        -- only show this component if there's 2 or more tabpages
        condition = function()
          return #vim.api.nvim_list_tabpages() >= 2
        end,
        { provider = "%=" },
        utils.make_tablist(Tabpage),
        -- TabpageClose,
      }

      local TabLine = { TabLineOffset, BufferLine, TabPages }

      -- Yep, with heirline we're driving manual!
      vim.o.showtabline = 2
      vim.cmd([[au FileType * if index(['wipe', 'delete'], &bufhidden) >= 0 | set nobuflisted | endif]])

      -- require("heirline").load_colors(setup_colors)
      -- or pass it to config.opts.colors

      vim.api.nvim_create_augroup("Heirline", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          utils.on_colorscheme(setup_colors)
        end,
        group = "Heirline",
      })


      -- the winbar parameter is optional!
      require("heirline").setup({
        statusline = StatusLine,
        tabline = TabLine,
        opts = {
          colors = colors,
        }
      })

      -- 失效缓存并刷新 Tabline 的辅助方法
      local function _heirline_bump_git_generation()
        vim.g._heirline_git_generation = (vim.g._heirline_git_generation or 0) + 1
        -- 强制重绘以触发 hl 重新计算
        pcall(vim.cmd.redrawtabline)
      end

      -- 当从外部工具返回或关闭终端（如 lazygit）时，认为 Git 状态可能变化，递增世代以失效缓存
      local group = vim.api.nvim_create_augroup("HeirlineGitRefresh", { clear = true })
      vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
        group = group,
        callback = function()
          _heirline_bump_git_generation()
        end,
      })
      vim.api.nvim_create_autocmd("TermClose", {
        group = group,
        callback = function()
          _heirline_bump_git_generation()
        end,
      })
    end
  }
}
