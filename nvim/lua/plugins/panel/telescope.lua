return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim", "kdheepak/lazygit.nvim" },
    config = function()
      local actions = require "telescope.actions"

      local telescope = require('telescope')
      telescope.setup {
        defaults = {
          prompt_prefix = " ",
          selection_caret = "❯ ",
          path_display = { "truncate" },
          -- path_display = function(opts, path)
          --   local tail = require("telescope.utils").path_tail(path)
          --   -- return string.format("%s (%s)", tail, path), { { { 1, #tail }, "Constant" } }
          --   return string.format("%s", tail), { { { 1, #tail }, "Constant" } }
          -- end,
          selection_strategy = "reset",
          -- sorting_strategy = "ascending",
          -- layout_strategy = "horizontal",
          layout_strategy = "vertical",
          layout_config = {
            -- horizontal = {
            --   prompt_position = "top",
            --   preview_width = 0.55,
            --   results_width = 0.8,
            -- },
            -- vertical = {
            --   prompt_position = "top",
            --   mirror = false,
            -- },
            -- width = 0.87,
            -- height = 0.80,
            -- preview_cutoff = 120,
          },
          mappings = {
            i = {
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,

              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,

              ["<C-q>"] = actions.close,

              ["<Down>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,

              ["<CR>"] = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,

              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,

              ["<PageUp>"] = actions.results_scrolling_up,
              ["<PageDown>"] = actions.results_scrolling_down,

              ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
              ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
              ["<C-c>"] = actions.send_to_qflist + actions.open_qflist,
              ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<C-l>"] = actions.complete_tag,
            },

            n = {
              ["<esc>"] = actions.close,
              ["<CR>"] = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,

              ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
              ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
              ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

              ["j"] = actions.move_selection_next,
              ["k"] = actions.move_selection_previous,
              ["H"] = actions.move_to_top,
              ["M"] = actions.move_to_middle,
              ["L"] = actions.move_to_bottom,

              ["<Down>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
              ["gg"] = actions.move_to_top,
              ["G"] = actions.move_to_bottom,

              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,

              ["<PageUp>"] = actions.results_scrolling_up,
              ["<PageDown>"] = actions.results_scrolling_down,
            },
          },
        },
        -- pickers = {
        --   live_grep = {
        --     entry_maker = function(entry)
        --       local text = entry.text or ""
        --       local filename = entry.filename or ""
        --       local lnum = entry.lnum and (":" .. entry.lnum) or ""
        --       local col = entry.col and (":" .. entry.col) or ""
        --
        --       local display_text = text
        --       if filename ~= "" then
        --         display_text = display_text .. " (" .. filename .. lnum .. ")"
        --       end
        --
        --       local ordinal = filename .. lnum .. col .. ":" .. text
        --       return {
        --         ordinal = ordinal,
        --         display = display_text,
        --         -- 其他必要字段...
        --       }
        --     end
        --   }
        -- },
        extensions = {
          media_files = {
            -- filetypes whitelist
            -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
            filetypes = { "png", "webp", "jpg", "jpeg" },
            -- find command (defaults to `fd`)
            find_cmd = "rg"
          }
        },
        preview = {
          mime_hook = function(filepath, bufnr, opts)
            local is_image = function(filepath)
              local image_extensions = { 'png', 'jpg' } -- Supported image formats
              local split_path = vim.split(filepath:lower(), '.', { plain = true })
              local extension = split_path[#split_path]
              return vim.tbl_contains(image_extensions, extension)
            end
            if is_image(filepath) then
              local term = vim.api.nvim_open_term(bufnr, {})
              local function send_output(_, data, _)
                for _, d in ipairs(data) do
                  vim.api.nvim_chan_send(term, d .. '\r\n')
                end
              end
              vim.fn.jobstart(
                {
                  'chafa', filepath -- Terminal image viewer command
                },
                { on_stdout = send_output, stdout_buffered = true, pty = true })
            else
              require("telescope.previewers.utils").set_preview_message(bufnr, opts.winid, "Binary cannot be previewed")
            end
          end
        }
      }
      telescope.load_extension("lazygit")
    end
  },
  {
    "nvim-telescope/telescope-media-files.nvim",
    config = function()
      require('telescope').load_extension('media_files')
    end
  }
}
