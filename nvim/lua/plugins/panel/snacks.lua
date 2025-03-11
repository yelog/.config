return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    quickfile = { enabled = true },
    -- scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      notification = {
        -- wo = { wrap = true } -- Wrap notifications
      }
    }
    -- image =
    -- ---@class snacks.image.Config
    -- ---@field enabled? boolean enable image viewer
    -- ---@field wo? vim.wo|{} options for windows showing the image
    -- ---@field bo? vim.bo|{} options for the image buffer
    -- ---@field formats? string[]
    -- --- Resolves a reference to an image with src in a file (currently markdown only).
    -- --- Return the absolute path or url to the image.
    -- --- When `nil`, the path is resolved relative to the file.
    -- ---@field resolve? fun(file: string, src: string): string?
    -- ---@field convert? snacks.image.convert.Config
    -- {
    --   formats = {
    --     "png",
    --     "jpg",
    --     "jpeg",
    --     "gif",
    --     "bmp",
    --     "webp",
    --     "tiff",
    --     "heic",
    --     "avif",
    --     "mp4",
    --     "mov",
    --     "avi",
    --     "mkv",
    --     "webm",
    --     "pdf",
    --   },
    --   force = false, -- try displaying the image, even if the terminal does not support it
    --   doc = {
    --     -- enable image viewer for documents
    --     -- a treesitter parser must be available for the enabled languages.
    --     enabled = true,
    --     -- render the image inline in the buffer
    --     -- if your env doesn't support unicode placeholders, this will be disabled
    --     -- takes precedence over `opts.float` on supported terminals
    --     inline = true,
    --     -- render the image in a floating window
    --     -- only used if `opts.inline` is disabled
    --     float = true,
    --     max_width = 80,
    --     max_height = 40,
    --     -- Set to `true`, to conceal the image text when rendering inline.
    --     conceal = false, -- (experimental)
    --   },
    --   img_dirs = { "img", "images", "assets", "static", "public", "media", "attachments" },
    --   -- window options applied to windows displaying image buffers
    --   -- an image buffer is a buffer with `filetype=image`
    --   wo = {
    --     wrap = false,
    --     number = false,
    --     relativenumber = false,
    --     cursorcolumn = false,
    --     signcolumn = "no",
    --     foldcolumn = "0",
    --     list = false,
    --     spell = false,
    --     statuscolumn = "",
    --   },
    --   cache = vim.fn.stdpath("cache") .. "/snacks/image",
    --   debug = {
    --     request = false,
    --     convert = false,
    --     placement = false,
    --   },
    --   env = {},
    --   ---@class snacks.image.convert.Config
    --   convert = {
    --     notify = true, -- show a notification on error
    --     ---@type snacks.image.args
    --     mermaid = function()
    --       local theme = vim.o.background == "light" and "neutral" or "dark"
    --       return { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-t", theme, "-s", "{scale}" }
    --     end,
    --     ---@type table<string,snacks.image.args>
    --     magick = {
    --       default = { "{src}[0]", "-scale", "1920x1080>" }, -- default for raster images
    --       vector = { "-density", 192, "{src}[0]" },         -- used by vector images like svg
    --       math = { "-density", 192, "{src}[0]", "-trim" },
    --       pdf = { "-density", 192, "{src}[0]", "-background", "white", "-alpha", "remove", "-trim" },
    --     },
    --   },
    --   math = {
    --     enabled = true, -- enable math expression rendering
    --     -- in the templates below, `${header}` comes from any section in your document,
    --     -- between a start/end header comment. Comment syntax is language-specific.
    --     -- * start comment: `// snacks: header start`
    --     -- * end comment:   `// snacks: header end`
    --     typst = {
    --       tpl = [[
    --     #set page(width: auto, height: auto, margin: (x: 2pt, y: 2pt))
    --     #show math.equation.where(block: false): set text(top-edge: "bounds", bottom-edge: "bounds")
    --     #set text(size: 12pt, fill: rgb("${color}"))
    --     ${header}
    --     ${content}]],
    --     },
    --     latex = {
    --       font_size = "Large", -- see https://www.sascha-frank.com/latex-font-size.html
    --       -- for latex documents, the doc packages are included automatically,
    --       -- but you can add more packages here. Useful for markdown documents.
    --       packages = { "amsmath", "amssymb", "amsfonts", "amscd", "mathtools" },
    --       tpl = [[
    --     \documentclass[preview,border=2pt,varwidth,12pt]{standalone}
    --     \usepackage{${packages}}
    --     \begin{document}
    --     ${header}
    --     { \${font_size} \selectfont
    --       \color[HTML]{${color}}
    --     ${content}}
    --     \end{document}]],
    --     },
    --   },
    -- }
  },
  keys = {
    { "<leader>z",  function() Snacks.zen() end,                     desc = "Toggle Zen Mode" },
    { "<leader>Z",  function() Snacks.zen.zoom() end,                desc = "Toggle Zoom" },
    { "<leader>.",  function() Snacks.scratch() end,                 desc = "Toggle Scratch Buffer" },
    { "<leader>S",  function() Snacks.scratch.select() end,          desc = "Select Scratch Buffer" },
    { "<leader>n",  function() Snacks.notifier.show_history() end,   desc = "Notification History" },
    { "<leader>bd", function() Snacks.bufdelete() end,               desc = "Delete Buffer" },
    { "<leader>cR", function() Snacks.rename.rename_file() end,      desc = "Rename File" },
    { "<leader>gB", function() Snacks.gitbrowse() end,               desc = "Git Browse" },
    { "<leader>gb", function() Snacks.git.blame_line() end,          desc = "Git Blame Line" },
    { "<leader>gf", function() Snacks.lazygit.log_file() end,        desc = "Lazygit Current File History" },
    { "<leader>gg", function() Snacks.lazygit() end,                 desc = "Lazygit" },
    -- { "<D-g>",      function() Snacks.lazygit() end,         desc = "Toggle Lazygit" },
    { "<leader>gl", function() Snacks.lazygit.log() end,             desc = "Lazygit Log (cwd)" },
    { "<leader>un", function() Snacks.notifier.hide() end,           desc = "Dismiss All Notifications" },
    { "<c-/>",      function() Snacks.terminal() end,                desc = "Toggle Terminal" },
    { "<c-_>",      function() Snacks.terminal() end,                desc = "which_key_ignore" },
    { "]]",         function() Snacks.words.jump(vim.v.count1) end,  desc = "Next Reference",              mode = { "n", "t" } },
    { "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference",              mode = { "n", "t" } },
    {
      "<leader>N",
      desc = "Neovim News",
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
          },
        })
      end,
    }
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map(
          "<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.dim():map("<leader>uD")
      end,
    })
  end,
}
