return {
  'echasnovski/mini.nvim',
  version = '*',
  config = function()
    local ai = require('mini.ai')
    ai.setup({
      n_lines = 200, -- 适当加大搜索半径，方便大文件中定位代码块
      custom_textobjects = {
        -- 给 Markdown 代码块绑定对象 id = 'c'
        c = ai.gen_spec.treesitter({
          a = { "@codeblock.outer" }, -- 包含围栏 ```…```
          i = { "@codeblock.inner" }, -- 仅内容
        }, {
          n_lines = 200,              -- 可单独为该对象提高搜索范围
          lang = "markdown",          -- 围栏内可能切换到注入语言，仍按 Markdown 查询代码块
        }),
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function(args)
        vim.keymap.set("x", "ic", function()
          require("mini.ai").select_textobject("i", "c")
        end, { buffer = args.buf, desc = "Select inner Markdown code block" })
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
