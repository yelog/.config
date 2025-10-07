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
          -- 指定语言可选：{ lang = "markdown" }
        }),
      },
    })
  end
}
