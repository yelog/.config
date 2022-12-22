vim.api.nvim_command("source ~/.config/nvim/base.vim")

require("utils")
require("utils.plugins")

require("core.key-map")

require("config.colorscheme")
require("config.comment")
-- require('config.toggleterm')
require("config.bufferline")
require("config.telescope")
require("config.neo-tree")
require("config.notify")
require("config.true-zen")
require("config.lualine")
require("config.indent-blankline")
require("config.auto-session")
require("config.wilder")
require("config.null-ls")
require("config.which-key")
require("config.markdown")
require("config.bullets")
require("config.lsp")
require("config.jdtls")
require("config.mason")
require("config.cmp")
require("config.neodev")
require("config.hop")
require("config.signature")
require("config.illuminate")
require("config.autopairs")
require("config.autotag")
require("config.gitgutter")
require("config.autosave")
require("config.lspkind")
require("config.dressing")
require("config.treesitter")
