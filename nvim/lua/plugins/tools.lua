return {
  "tpope/vim-surround", --> type ysiw' to wrap the word with '' or type cs'` to change 'word' to `word`
  "tpope/vim-repeat",   --> repeat surround and so on
  {
    "ybian/smartim",    --> smart switch input method
    config = function()
      vim.g.smartim_default = "com.apple.keylayout.ABC"
    end
  },
  "itchyny/vim-cursorword",   --> Underlines the word under the cursor
  "dhruvasagar/vim-open-url", --> open brower with the url under the cursor
  {
    "airblade/vim-rooter",    --> Changes Vim working directory to project root
    config = function()
      -- airblade/vim-rooter
      vim.g.rooter_patterns = { ".git/" }
    end
  },
  -------------- decoration --------------
  "lilydjwg/colorizer",                --> show color by color code
  "jeffkreeftmeijer/vim-numbertoggle", --> Toggles between hybrid and absolute line numbers automatically
}
