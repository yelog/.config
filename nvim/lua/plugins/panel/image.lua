return {
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        -- file and directory options
        dir_path = "assets", ---@type string | fun(): string
        extension = "png", ---@type string | fun(): string
        file_name = "%Y-%m-%d-%H-%M-%S", ---@type string | fun(): string
        use_absolute_path = false, ---@type boolean | fun(): boolean
        relative_to_current_file = false, ---@type boolean | fun(): boolean

        -- template options
        template = "$FILE_PATH", ---@type string | fun(context: table): string
        url_encode_path = false, ---@type boolean | fun(): boolean
        relative_template_path = true, ---@type boolean | fun(): boolean
        use_cursor_in_template = true, ---@type boolean | fun(): boolean
        insert_mode_after_paste = true, ---@type boolean | fun(): boolean

        -- prompt options
        prompt_for_file_name = false, ---@type boolean | fun(): boolean
        show_dir_path_in_prompt = false, ---@type boolean | fun(): boolean

        -- base64 options
        max_base64_size = 10, ---@type number | fun(): number
        embed_image_as_base64 = false, ---@type boolean | fun(): boolean

        -- image options
        process_cmd = "", ---@type string | fun(): string
        copy_images = false, ---@type boolean | fun(): boolean
        download_images = true, ---@type boolean | fun(): boolean

        -- drag and drop options
        drag_and_drop = {
          enabled = true, ---@type boolean | fun(): boolean
          insert_mode = false, ---@type boolean | fun(): boolean
        },
      },

      -- filetype specific options
      filetypes = {
        markdown = {
          url_encode_path = true, ---@type boolean | fun(): boolean
          template = "![$CURSOR]($FILE_PATH)", ---@type string | fun(context: table): string
          download_images = false, ---@type boolean | fun(): boolean
        },

        vimwiki = {
          url_encode_path = true, ---@type boolean | fun(): boolean
          template = "![$CURSOR]($FILE_PATH)", ---@type string | fun(context: table): string
          download_images = false, ---@type boolean | fun(): boolean
        },

        html = {
          template = '<img src="$FILE_PATH" alt="$CURSOR">', ---@type string | fun(context: table): string
        },

        tex = {
          relative_template_path = false, ---@type boolean | fun(): boolean
          template = [[
\begin{figure}[h]
  \centering
  \includegraphics[width=0.8\textwidth]{$FILE_PATH}
  \caption{$CURSOR}
  \label{fig:$LABEL}
\end{figure}
    ]], ---@type string | fun(context: table): string
        },

        typst = {
          template = [[
#figure(
  image("$FILE_PATH", width: 80%),
  caption: [$CURSOR],
) <fig-$LABEL>
    ]], ---@type string | fun(context: table): string
        },

        rst = {
          template = [[
.. image:: $FILE_PATH
   :alt: $CURSOR
   :width: 80%
    ]], ---@type string | fun(context: table): string
        },

        asciidoc = {
          template = 'image::$FILE_PATH[width=80%, alt="$CURSOR"]', ---@type string | fun(context: table): string
        },

        org = {
          template = [=[
#+BEGIN_FIGURE
[[file:$FILE_PATH]]
#+CAPTION: $CURSOR
#+NAME: fig:$LABEL
#+END_FIGURE
    ]=], ---@type string | fun(context: table): string
        },
      },

      -- file, directory, and custom triggered options
      files = {}, ---@type table | fun(): table
      dirs = {}, ---@type table | fun(): table
      custom = {}, ---@type table | fun(): table
    },
    keys = {
      -- suggested keymap
      { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  },
  {
    "3rd/image.nvim",
    lazy = true,
    ft = "markdown",
    config = function()
      require("image").setup({
        backend = "kitty",
        processor = "magick_rock", -- or "magick_cli"
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = true,
            filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
          },
          neorg = {
            enabled = true,
            filetypes = { "norg" },
          },
          typst = {
            enabled = true,
            filetypes = { "typst" },
          },
          html = {
            enabled = false,
          },
          css = {
            enabled = false,
          },
        },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,
        window_overlap_clear_enabled = false,                                               -- toggles images when windows are overlapped
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
        editor_only_render_when_focused = false,                                            -- auto show/hide images when the editor gains/looses focus
        tmux_show_only_in_active_window = false,                                            -- auto show/hide images in the correct Tmux window (needs visual-activity off)
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
      })
    end
  },
  {
    "3rd/diagram.nvim",
    dependencies = {
      "3rd/image.nvim",
    },
    opts = { -- you can just pass {}, defaults below
      renderer_options = {
        mermaid = {
          background = nil, -- nil | "transparent" | "white" | "#hex"
          theme = nil,      -- nil | "default" | "dark" | "forest" | "neutral"
          scale = 3,        -- nil | 1 (default) | 2  | 3 | ...
        },
        plantuml = {
          charset = nil,
        },
        d2 = {
          theme_id = nil,
          dark_theme_id = nil,
          scale = nil,
          layout = nil,
          sketch = nil,
        },
      }
    },
  },
}
