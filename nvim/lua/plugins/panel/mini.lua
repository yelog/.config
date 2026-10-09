return {
  'echasnovski/mini.nvim',
  version = '*',
  config = function()
    local ai = require('mini.ai')
    ai.setup({
      n_lines = 200, -- 适当加大搜索半径，方便大文件中定位代码块
      custom_textobjects = {
        -- Tree-sitter definitions use uppercase objects; lowercase af/if remain Mini.ai function calls.
        F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
        C = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function(args)
        vim.b[args.buf].miniai_config = {
          custom_textobjects = {
            -- Markdown's `c` object selects fenced code blocks without changing Mini.ai elsewhere.
            c = ai.gen_spec.treesitter({
              a = { "@codeblock.outer" },
              i = { "@codeblock.inner" },
            }, {
              n_lines = 200,
              lang = "markdown",
            }),
          },
        }
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "xml",
      callback = function(args)
        vim.b[args.buf].miniai_config = {
          custom_textobjects = {
            t = {
              "<([%p%w]-)%f[^<%w][^<>]->.-</%1>",
              "^<.->().*()</[^/]->$",
            },
          },
        }
      end,
    })
  end
}
