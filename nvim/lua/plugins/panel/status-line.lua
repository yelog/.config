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


      local StatusLine = {
        hl = { bg = "NONE" }, -- 背景色设置为 NONE，让背景透明
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
          local bg = utils.get_highlight("TabLine").bg
          local underline = self.is_active and true or false

          -- 使用每个 buffer 的 changedtick 做轻量缓存，避免重复执行外部命令
          local tick = vim.api.nvim_buf_get_changedtick(self.bufnr)
          -- 额外引入全局“git世代”计数，外部操作（如 lazygit 提交）时递增以失效缓存
          local gen = vim.g._heirline_git_generation or 0
          local ok_cache, cache = pcall(vim.api.nvim_buf_get_var, self.bufnr, "_heirline_tab_git_cache")
          if ok_cache and type(cache) == "table"
              and cache.tick == tick
              and cache.gen == gen
              and cache.filename == self.filename then
            return { fg = cache.fg, bg = bg, bold = true, underline = underline }
          end

          -- 如果你在此处调试想看触发频率，建议只在 changedtick 变化时提示：
          local ok_tick, last_tick = pcall(vim.api.nvim_buf_get_var, self.bufnr, "_heirline_tab_dbg_tick")
          if not ok_tick or last_tick ~= tick then
            pcall(vim.api.nvim_buf_set_var, self.bufnr, "_heirline_tab_dbg_tick", tick)
            -- 取消注释进行调试：
            -- vim.notify("更新 TablineFileNameBlock", vim.log.levels.INFO, { title = "Heirline" })
          end
          -- vim.notify("计算 TablineFileNameBlock 高亮", vim.log.levels.DEBUG, { title = "Heirline" })

          local fg = nil

          -- 先尝试从 gitsigns 获取行级改动统计
          local dict
          local ok, v = pcall(vim.api.nvim_buf_get_var, self.bufnr, "gitsigns_status_dict")
          if ok and type(v) == "table" then
            dict = v
          else
            -- 备用：有些情况下 get_var 不存在时用 getbufvar 兜底
            local v2 = vim.fn.getbufvar(self.bufnr, "gitsigns_status_dict")
            if type(v2) == "table" then
              dict = v2
            end
          end

          -- 计算 git 仓库根目录、相对路径，以及该文件是否存在于 HEAD
          local filename = self.filename or ""
          local in_head = nil
          local toproot = nil
          local relpath = nil
          if filename ~= "" then
            local filedir = vim.fn.fnamemodify(filename, ":h")
            local root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(filedir) .. ' rev-parse --show-toplevel')[1]
            if root and root ~= '' and not tostring(root):match('^fatal:') then
              toproot = vim.fn.trim(root)
              local root_prefix = toproot
              if root_prefix:sub(-1) ~= '/' then root_prefix = root_prefix .. '/' end
              relpath = filename
              if relpath:sub(1, #root_prefix) == root_prefix then
                relpath = relpath:sub(#root_prefix + 1)
              end
              local cmd = 'git -C ' ..
                  vim.fn.shellescape(toproot) .. ' cat-file -e ' .. vim.fn.shellescape('HEAD:' .. relpath)
              vim.fn.system(cmd)
              in_head = (vim.v.shell_error == 0)
            end
          end

          if toproot and relpath then
            -- 新逻辑（以 git status 为准，避免缓存/异步延迟导致误判）：
            -- - 不在 HEAD：
            --     - 如果被 .gitignore 忽略，则不高亮（不应视为新增）
            --     - 否则视为未跟踪/新增 => GitSignsAdd
            -- - 在 HEAD：只要 git status 对该文件有记录（不包含 ?? 情况），就视为有改动 => GitSignsChange
            -- - 其他 => 默认颜色
            if in_head == false then
              -- 可能是未跟踪或被忽略的文件，优先检查 ignore
              local cmd_ignore = 'git -C '
                  .. vim.fn.shellescape(toproot)
                  .. ' check-ignore -q -- '
                  .. vim.fn.shellescape(relpath)
              vim.fn.system(cmd_ignore)
              local is_ignored = (vim.v.shell_error == 0)
              if not is_ignored then
                fg = utils.get_highlight("GitSignsAdd").fg
              end
            elseif in_head == true then
              -- 如果缓冲区有未保存修改，直接认为有改动（即时反馈）
              local buf_modified = vim.api.nvim_get_option_value("modified", { buf = self.bufnr })
              if buf_modified then
                fg = utils.get_highlight("GitSignsChange").fg
              else
                -- 已保存状态：以 git status 为准
                local out = vim.fn.systemlist('git -C ' ..
                    vim.fn.shellescape(toproot) .. ' status --porcelain -- ' .. vim.fn.shellescape(relpath))
                local has_changes = false
                if type(out) == 'table' and #out > 0 then
                  for _, line in ipairs(out) do
                    -- 在 HEAD 时不会出现 ??（未跟踪），出现即忽略；其余任意状态视为有改动
                    if not line:match('^%?%?') then
                      has_changes = true
                      break
                    end
                  end
                end
                if has_changes then
                  fg = utils.get_highlight("GitSignsChange").fg
                end
              end
            else
              -- in_head == nil：无法确定（非 git 仓库或其他原因），保持默认颜色
            end
          end

          -- 写入缓存
          pcall(vim.api.nvim_buf_set_var, self.bufnr, "_heirline_tab_git_cache", {
            tick = tick,
            gen = gen,
            filename = self.filename,
            fg = fg,
          })

          return { fg = fg, bg = bg, bold = true, underline = underline }
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
        Space,
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

      -- The final touch! 文字和左右两侧的分隔符的背景色
      local TablineBufferBlock = utils.surround({ "", "" }, function(self)
        -- if self.is_active then
        --   return utils.get_highlight("TabLineSel").bg
        -- else
        return utils.get_highlight("TabLine").bg
        -- end
        -- end, { TablineFileNameBlock, TablineCloseButton })
      end, { TablineFileNameBlock })

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
      local function setup_colors()
        return {
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
      end

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
