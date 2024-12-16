local maps = { i = {}, n = {}, v = {}, t = {}, [""] = {} }

maps[""]["<Space>"] = "<Nop>"

-- Base
maps.n["Q"] = { "<cmd>qa<cr>", desc = "Quit" }
maps.n["<up>"] = { "<cmd>res-5<cr>", desc = "up" }
maps.n["<down>"] = { "<cmd>res+5<cr>", desc = "down" }
maps.n["<left>"] = { "<cmd>vertical res-5<cr>", desc = "left" }
maps.n["<right>"] = { "<cmd>vertical res+5<cr>", desc = "right" }
-- local neoTree = require("neo-tree")
maps.n["<c-q>"] = {
  function()
    -- print(vim.fn.tabpagewinnr(vim.fn.tabpagenr(), '$'))
    -- print(neoTree.get_prior_window())
    -- vim.fn.getwininfo(1)
    -- print(vim.fn.tabpagenr('$'))

    -- if vim.fn.tabpagewinnr(vim.fn.tabpagenr(), '$') > 1 then
    -- if vim.fn.len(vim.fn.getbufinfo({ buflisted = 1 })) > 1 then
    -- close current file
    -- vim.cmd("bdelete")
    vim.cmd("Bdelete")
    -- else
    -- --   -- close current window
    --   vim.cmd("close")
    -- end
  end,
  desc = "Quit",
}
-- maps.n["Q"] = { "<cmd>w<cr><cmd>qa<cr>", desc = "Quit" }

-- plugin
maps.n["<leader>pi"] = { "<cmd>Lazy<cr>", desc = "plug install" }
-- maps.n["<leader>pi"] = { "<cmd>PackerInstall<cr>", desc = "plug install" }
-- maps.n["<leader>pc"] = { "<cmd>PackerClean<cr>", desc = "plug clean" }
-- maps.n["<leader>pu"] = { "<cmd>PackerUpdate<cr>", desc = "plug update" }

-- lsp
maps.n["<leader>li"] = { "<cmd>Mason<cr>", desc = "Mason dashboard" }
-- maps.n["<D-s>"] = { "<cmd>EslintFixAll<cr>", desc = "Eslint Fix All" }

-- Bind <leader>ll to format_with_lsp in all filetypes
-- vim.api.nvim_set_keymap('n', '<leader>ll', ':lua vim.lsp.buf.format({ async = true })<CR>', { noremap = true, silent = true })

-- Bind <leader>ll to :TableModeRealign only in Markdown files

maps.n["<D-s>"] = {
  function()
    local eslintFileType = { "javascript", "typescript", "vue" }
    if vim.bo.filetype == "markdown" then
      vim.cmd("TableModeRealign")
    elseif my.is_include(vim.bo.filetype, eslintFileType) then
      vim.cmd("EslintFixAll")
    else
      vim.lsp.buf.format({ async = true })
    end
  end,
  desc = "format code",
}
maps.n["<leader>ll"] = {
  function()
    vim.lsp.buf.format({ async = true })
  end,
  desc = "format code",
}

maps.v["<leader>ll"] = {
  function()
    vim.lsp.buf.format({ async = true })
  end,
  desc = "format code",
}

-- Telescope
maps.n["<D-M>"] = {
  function()
    require("telescope.builtin").lsp_document_symbols()
  end,
  desc = "Search symbols",
}
maps.n["<D-O>"] = {
  function()
    require("telescope.builtin").find_files()
  end,
  desc = "search file",
}
maps.n["<leader>ff"] = {
  function()
    require("telescope.builtin").find_files()
  end,
  desc = "search file",
}
maps.n["<leader>fb"] = {
  function()
    require("telescope.builtin").buffers()
  end,
  desc = "Search buffers",
}
maps.n["<leader>fn"] = {
  function()
    require("telescope").extensions.notify.notify()
  end,
  desc = "Search buffers",
}
maps.n["gd"] = {
  function()
    require("telescope.builtin").lsp_definitions()
  end,
  desc = "Search definition",
}
maps.n["gu"] = {
  function()
    require("telescope.builtin").lsp_references()
  end,
  desc = "Search references",
}
maps.n["<leader>fk"] = {
  function()
    require("telescope.builtin").keymaps()
  end,
  desc = "Search keymap",
}
maps.n["<leader>ft"] = {
  function()
    require("telescope.builtin").help_tags()
  end,
  desc = "Search tags",
}
maps.n["<leader>fm"] = {
  function()
    require("telescope.builtin").marks()
  end,
  desc = "Search marks",
}
maps.n["<leader>fh"] = {
  function()
    require("telescope.builtin").oldfiles()
  end,
  desc = "Search hisotry",
}
maps.n["<D-e>"] = {
  function()
    require("telescope.builtin").oldfiles()
  end,
  desc = "Search hisotry",
}
maps.n["<leader>f;"] = {
  function()
    require("telescope.builtin").builtin()
  end,
  desc = "Search builtin",
}
maps.n["<leader>fs"] = {
  function()
    require("telescope.builtin").live_grep()
  end,
  desc = "Search word",
}
local get_selection = function()
  return vim.fn.getregion(
    vim.fn.getpos ".", vim.fn.getpos "v", { mode = vim.fn.mode() }
  )
end
local get_cursor_word = function()
  return vim.fn.expand("<cword>")
end
maps.n["<D-S-f>"] = {
  function()
    -- require("telescope.builtin").live_grep { default_text = get_cursor_word() }
    require("telescope.builtin").live_grep()
  end,
  desc = "Search word",
}
maps.v["<D-S-f>"] = {
  function()
    require("telescope.builtin").live_grep { default_text = table.concat(get_selection())
    }
  end,
  desc = "Search word",
}
maps.n["<leader>fS"] = {
  function()
    require("telescope.builtin").live_grep({
      additional_args = function(args)
        return vim.list_extend(args, { "--hidden", "--no-ignore" })
      end,
    })
  end,
  desc = "Search words in all files",
}

-- local truezen = require('true-zen')
--> true-zen
maps.n["<leader>zn"] = { "<cmd>TZNarrow<cr>", desc = "" }
maps.v["<leader>zn"] = { "<cmd>'<,'>TZNarrow<cr>", desc = "" }
maps.n["<leader>zf"] = { "<cmd>TZFocus<cr>", desc = "" }
maps.n["<leader>zm"] = { "<cmd>TZMinimalist<cr>", desc = "" }
maps.n["<leader>za"] = { "<cmd>TZAtaraxis<cr>", desc = "" }

-- neo-tree
-- maps.n["<leader>e"] = { function() require("telescope.builtin").find_files() end, desc = "Search file" }
-- maps.n["<leader>e"] = { "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" }
maps.n["<D-1>"] = { "<cmd>Neotree left toggle<cr>", desc = "Toggle Explorer" }
maps.n["<leader>te"] = { "<cmd>Neotree left toggle<cr>", desc = "Toggle Explorer" }
-- maps.n["<D-1>"] = { "<cmd>Neotree left toggle<cr>", desc = "Toggle Explorer" }
-- maps.n["<D-2>"] = { "<cmd>Neotree float toggle<cr>", desc = "Toggle Explorer" }
-- maps.n["<leader>o"] = { "<cmd>Neotree focus<cr>", desc = "Focus Explorer" }

-- table of contents
maps.n["<leader>ts"] = { "<cmd>AerialToggle<cr>", desc = "Toggle Structure" }
-- maps.n["<leader>ts"] = { "<cmd>SymbolsOutline<cr>", desc = "Toggle Structure" }

-- bufferline
maps.n["<c-n>"] = { "<cmd>BufferLineCycleNext<cr>", desc = "Buffer Next" }
maps.n["<c-p>"] = { "<cmd>BufferLineCyclePrev<cr>", desc = "Buffer Previous" }
maps.n["<leader>bn"] = { "<cmd>BufferLineMoveNext<cr>", desc = "Buffer Move Next" }
maps.n["<leader>bp"] = { "<cmd>BufferLineMovePrev<cr>", desc = "Buffer Move Previous" }
maps.n["<leader>bo"] = { "<cmd>BufferLineCloseLeft<cr><cmd>BufferLineCloseRight<cr>", desc = "Buffer Close Others" }
maps.n["<leader>bc"] = { "<cmd>BufferLinePickClose<cr>", desc = "Buffer Close Pick" }
maps.n["<leader>bcl"] = { "<cmd>BufferLineCloseLeft<cr>", desc = "Buffer Close Left" }
maps.n["<leader>bcr"] = { "<cmd>BufferLineCloseRight<cr>", desc = "Buffer Close Right" }
-- maps.n["<c-q>"] = { "<cmd>bdelete<cr>", desc = "Buffer Close" }

-- rebelot/heirline.nvim
-- maps.n["<c-n>"] = { "<cmd>bnext<cr>", desc = "Buffer Next" }
-- maps.n["<c-p>"] = { "<cmd>bprevious<cr>", desc = "Buffer Previous" }

-- markdown
maps.n["<leader>tm"] = { "<cmd>TableModeToggle<cr>", desc = "Table Mode Toggle" }
maps.n["<leader>tm"] = { "<cmd>TableModeToggle<cr>", desc = "Table Mode Toggle" }
maps.n["<leader>mc"] = { "<cmd>CheckSwitch<cr>", desc = "Checkbox Switch" }
maps.v["<leader>mc"] = { "<cmd>CheckSwitch<cr>gv", desc = "Checkbox Switch" }
-- maps.n["<D-l>"] = { "<cmd>CheckSwitch<cr>", desc = "Checkbox Switch" }
-- maps.v["<leader>"] = { "<cmd>CheckSwitch<cr>gv", desc = "Checkbox Switch" }
maps.n["<leader>md"] = { "<cmd>ObsidianToday<cr>", desc = "goto daily task" }
-- maps.n["gf"] = { function()
--   if require("obsidian").util.cursor_on_markdown_link() then
--     return "<cmd>ObsidianFollowLink<CR>"
--   else
--     return "gf"
--   end
-- end,
--   desc = "goto file",
-- }

-- git
-- maps.n["<leader>gg"] = { "<cmd>LazyGit<cr>", desc = "LazyGit" }
-- maps.n["<leader>gh"] = { "<cmd>LazyGitFilterCurrentFile<cr>", desc = "Current file history" }
-- maps.n["<leader>gf"] = { "<cmd>GitGutterFold<cr>", desc = "git fold" }
-- maps.n["<leader>gp"] = { "<cmd>GitGutterPrevHunk<cr>", desc = "git prev hunk" }
-- maps.n["<leader>gn"] = { "<cmd>GitGutterNextHunk<cr>", desc = "git next hunk" }
-- maps.n["<leader>gu"] = { "<cmd>GitGutterUndoHunk<cr>", desc = "git reset" }
-- maps.n["<leader>gd"] = { "<cmd>GitGutterPreviewHunk<cr>", desc = "git review hunk" }
-- maps.n["<leader>gd"] = { "<cmd>GitGutterDiffOrig<cr>", desc = "git diff" }
-- maps.n["<leader>gb"] = { "<cmd>Git blame<cr>", desc = "git blame" }

-- use gisign
-- maps.n["<leader>gw"] = {
--   function()
--     local view = require("diffview.lib").get_current_view()
--     if view then
--       vim.cmd("DiffviewClose")
--     else
--       vim.cmd("DiffviewOpen ")
--     end
--   end,
--   desc = "git diff",
-- }

-- task manager
-- maps.n["<leader>tn"] = { "<cmd>ToDoTxtCapture<cr>", desc= "New Todo"}
-- maps.n["<D-2>"] = { "<cmd>AerialToggle<cr>", desc= "Toggle outline"}
maps.n["<D-2>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle outline" }
maps.t["<D-2>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle outline" }
maps.i["<D-2>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle outline" }
maps.v["<D-2>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle outline" }

--ChatGPT
-- maps.n["<leader>ai"] = { "<cmd>ChatGPT<cr>", desc = "ChatGPT"}
-- maps.n["<leader>ai"] = { "<cmd>NeoAIToggle<cr>", desc = "ChatGPT" }
maps.i["<D-k>"] = { "<esc>V<cmd>AvanteEdit<cr>", desc = "AvanteEditor" }
maps.n["<D-k>"] = { "V<cmd>AvanteEdit<cr>", desc = "AvanteEditor" }
maps.v["<D-k>"] = { "<cmd>AvanteEdit<cr>", desc = "AvanteEditor" }
maps.i["<D-K>"] = { "<esc><cmd>AvanteChat<cr>", desc = "AvanteEditor" }
maps.n["<D-K>"] = { "<cmd>AvanteChat<cr>", desc = "AvanteEditor" }
maps.v["<D-K>"] = { "<cmd>AvanteChat<cr>", desc = "AvanteEditor" }
maps.i["<right>"] = {
  function()
    local copilot = require("copilot.suggestion")
    if (copilot.is_visible()) then
      copilot.accept()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, true, true), "n", true)
    end
  end,
  desc = "Accept Copilot Or Right"
}

-- 跳转vim分屏/tmux分屏
maps.n["<M-h>"] = { "<cmd>lua require('tmux').move_left()<cr>", desc = "" }
maps.n["<M-j>"] = { "<cmd>lua require('tmux').move_bottom()<cr>", desc = "" }
maps.n["<M-k>"] = { "<cmd>lua require('tmux').move_top()<cr>", desc = "" }
maps.n["<M-l>"] = { "<cmd>lua require('tmux').move_right()<cr>", desc = "" }

-- maps.n['<C-S-n>'] = { "<cmd>Neotree left toggle<cr>", desc = "Toggle Explorer" }
-- maps.n['<C-S-p>'] = { "<cmd>Neotree left toggle<cr>", desc = "Toggle Explorer" }
-- maps.n['<D-n>'] = { "<cmd>Neotree left toggle<cr>", desc = "Toggle Explorer" }
-- maps.n['<D-m>'] = { "<cmd>Neotree left toggle<cr>", desc = "Toggle Explorer" }
-- maps.n['<D-N>'] = { "<cmd>Neotree left toggle<cr>", desc = "Toggle Explorer" }

-- maps.n['R'] = { "<cmd>:set splitright<cr><cmd>vsp<cr><cmd>term lua %<cr>", desc = "run lua file" }

my.set_mappings(maps)

-- 使用 Option + h/j/k/l 进行 Neovim 分屏切换
-- vim.api.nvim_set_keymap('n', '<D-h>', ':wincmd h<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<D-j>', ':wincmd j<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<D-k>', ':wincmd k<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<D-l>', ':wincmd l<CR>', { noremap = true, silent = true })
