local wilder = require('wilder')
wilder.setup({modes = {':', '/', '?'},
-- next_key = '<Tab>',
-- previous_key = '<S-Tab>',
next_key = '<Tab>',
previous_key = '<S-Tab>',
})

wilder.set_option('renderer', wilder.popupmenu_renderer(
  wilder.popupmenu_border_theme({
    highlighter = wilder.basic_highlighter(),
    highlights = {
      accent = wilder.make_hl('WilderAccent', 'Pmenu', {{a = 1}, {a = 1}, {foreground = '#f4468f'}}),
    },
    border = 'rounded',
    reverse = 1,        -- if 1, shows the candidates from bottom to top
  })
))

-- fuzzy
wilder.set_option('pipeline', {
  wilder.debounce(10),
  wilder.branch(
    wilder.cmdline_pipeline({
      -- 0 turns off fuzzy matching
      -- 1 turns on fuzzy matching
      -- 2 partial fuzzy matching (match does not have to begin with the same first letter)
      fuzzy = 1,
      set_pcre2_pattern = 1
    }),
    wilder.python_search_pipeline({
      -- can be set to wilder#python_fuzzy_delimiter_pattern() for stricter fuzzy matching
      pattern = wilder.python_fuzzy_pattern(),
      -- omit to get results in the order they appear in the buffer
      sorter = wilder.python_difflib_sorter(),
      -- can be set to 're2' for performance, requires pyre2 to be installed
      -- see :h wilder#python_search() for more details
      engine = 're',
    })
  ),
})
