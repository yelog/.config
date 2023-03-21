local maps = { i = {}, n = {}, v = {}, t = {}, [""] = {} }

maps[""]["<Space>"] = "<Nop>"

-- Base
maps.n["Q"] = { "<cmd>qa<cr>", desc = "Quit" }
-- local neoTree = require("neo-tree")
maps.n["<c-q>"] = { function ()
    -- print(vim.fn.tabpagewinnr(vim.fn.tabpagenr(), '$'))
  -- print(neoTree.get_prior_window())
  -- vim.fn.getwininfo(1)
  -- print(vim.fn.tabpagenr('$'))

  -- if vim.fn.tabpagewinnr(vim.fn.tabpagenr(), '$') > 1 then
  -- if vim.fn.len(vim.fn.getbufinfo({ buflisted = 1 })) > 1 then
    -- close current file
    -- vim.cmd("bdelete")
    vim.cmd('Bdelete')
  -- else
  -- --   -- close current window
  --   vim.cmd("close")
  -- end
end, desc = "Quit" }
-- maps.n["Q"] = { "<cmd>w<cr><cmd>qa<cr>", desc = "Quit" }

-- plugin
maps.n["<leader>pp"] = { "<cmd>Lazy<cr>", desc = "plug install" }
-- maps.n["<leader>pi"] = { "<cmd>PackerInstall<cr>", desc = "plug install" }
-- maps.n["<leader>pc"] = { "<cmd>PackerClean<cr>", desc = "plug clean" }
-- maps.n["<leader>pu"] = { "<cmd>PackerUpdate<cr>", desc = "plug update" }

-- lsp
maps.n["<leader>li"] = { "<cmd>Mason<cr>", desc = "Mason dashboard" }
maps.n["<leader>ll"] = { function() vim.lsp.buf.format { async = true } end, desc = "format code" }
maps.v["<leader>ll"] = { function() vim.lsp.buf.format { async = true } end, desc = "format code" }


-- Telescope
maps.n["<M-M>"] = { function() require("telescope.builtin").lsp_document_symbols() end, desc = "Search file" }
maps.n["<leader>ff"] = { function() require("telescope.builtin").find_files() end, desc = "search symbols" }
maps.n["<leader>fb"] = { function() require("telescope.builtin").buffers() end, desc = "Search buffers" }
maps.n["<leader>fn"] = { function() require('telescope').extensions.notify.notify() end, desc = "Search buffers" }
maps.n["<leader>fr"] = { function() require("telescope.builtin").lsp_references() end, desc = "Search references" }
maps.n["<leader>fk"] = { function() require("telescope.builtin").keymaps() end, desc = "Search keymap" }
maps.n["<leader>ft"] = { function() require("telescope.builtin").help_tags() end, desc = "Search tags" }
maps.n["<leader>fm"] = { function() require("telescope.builtin").marks() end, desc = "Search marks" }
maps.n["<leader>fh"] = { function() require("telescope.builtin").oldfiles() end, desc = "Search hisotry" }
maps.n["<leader>f;"] = { function() require("telescope.builtin").builtin() end, desc = "Search builtin" }
maps.n["<leader>fs"] = { function() require("telescope.builtin").live_grep() end, desc = "Search word" }
maps.n["<leader>fS"] = {
  function()
    require("telescope.builtin").live_grep {
      additional_args = function(args) return vim.list_extend(args, { "--hidden", "--no-ignore" }) end,
    }
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
maps.n["<M-1>"] = { "<cmd>Neotree left toggle<cr>", desc = "Toggle Explorer" }
-- maps.n["<M-2>"] = { "<cmd>Neotree float toggle<cr>", desc = "Toggle Explorer" }
-- maps.n["<leader>o"] = { "<cmd>Neotree focus<cr>", desc = "Focus Explorer" }

-- bufferline
maps.n["<c-n>"] = { "<cmd>BufferLineCycleNext<cr>", desc = "Buffer Next" }
maps.n["<c-p>"] = { "<cmd>BufferLineCyclePrev<cr>", desc = "Buffer Previous" }
maps.n["<leader>tn"] = { "<cmd>BufferLineMoveNext<cr>", desc = "Buffer Move Next" }
maps.n["<leader>tp"] = { "<cmd>BufferLineMovePrev<cr>", desc = "Buffer Move Previous" }
maps.n["<leader>to"] = { "<cmd>BufferLineCloseLeft<cr><cmd>BufferLineCloseRight<cr>", desc = "Buffer Close Others" }
maps.n["<leader>tc"] = { "<cmd>BufferLinePickClose<cr>", desc = "Buffer Close Pick" }
maps.n["<leader>tcl"] = { "<cmd>BufferLineCloseLeft<cr>", desc = "Buffer Close Left" }
maps.n["<leader>tcr"] = { "<cmd>BufferLineCloseRight<cr>", desc = "Buffer Close Right" }
-- maps.n["<c-q>"] = { "<cmd>bdelete<cr>", desc = "Buffer Close" }

-- markdown
maps.n["<leader>tm"] = { "<cmd>TableModeToggle<cr>", desc = "Table Mode Toggle" }
maps.n["<leader>tm"] = { "<cmd>TableModeToggle<cr>", desc = "Table Mode Toggle" }
maps.n["<leader>mc"] = { "<cmd>CheckSwitch<cr>", desc = "Checkbox Switch" }
maps.v["<leader>mc"] = { "<cmd>CheckSwitch<cr>gv", desc = "Checkbox Switch" }
-- maps.v["<leader>"] = { "<cmd>CheckSwitch<cr>gv", desc = "Checkbox Switch" }
maps.n["<leader>md"] = {"<cmd>ObsidianToday<cr>", desc = "goto daily task"}
-- maps.n["gf"] = { function()
--   if require("obsidian").util.cursor_on_markdown_link() then
--     return "<cmd>ObsidianFollowLink<CR>"
--   else
--     return "gf"
--   end
-- end,
--   desc = "goto file",
-- }


-- hop
maps.n[";w"] = { "<cmd>HopWord<cr>", desc = "Hop Word" }
maps.n[";a"] = { "<cmd>HopAnywhere<cr>", desc = "Hop Anywhere" }
maps.n[";s"] = { "<cmd>HopChar2<cr>", desc = "Hop search" }
maps.n[";l"] = { "<cmd>HopWordCurrentLineAC<cr>", desc = "Hop line right" }
maps.n[";h"] = { "<cmd>HopWordCurrentLineBC<cr>", desc = "Hop line left" }
maps.n[";k"] = { "<cmd>HopLineBC<cr>", desc = "Hop line down" }
maps.n[";j"] = { "<cmd>HopLineAC<cr>", desc = "Hop line up" }

-- git
maps.n["<leader>gg"] = { "<cmd>LazyGit<cr>", desc = "LazyGit" }
maps.n["<leader>gh"] = { "<cmd>LazyGitFilterCurrentFile<cr>", desc = "Current file history" }
maps.n["<leader>gf"] = { "<cmd>GitGutterFold<cr>", desc = "git fold" }
maps.n["<leader>gp"] = { "<cmd>GitGutterPrevHunk<cr>", desc = "git prev hunk" }
maps.n["<leader>gn"] = { "<cmd>GitGutterNextHunk<cr>", desc = "git next hunk" }
maps.n["<leader>gu"] = { "<cmd>GitGutterUndoHunk<cr>", desc = "git reset" }
maps.n["<leader>gd"] = { "<cmd>GitGutterPreviewHunk<cr>", desc = "git review hunk" }
-- maps.n["<leader>gd"] = { "<cmd>GitGutterDiffOrig<cr>", desc = "git diff" }
maps.n["<leader>gb"] = { "<cmd>Git blame<cr>", desc = "git blame" }

maps.n["<M-W>"] = { function()
  local view = require("diffview.lib").get_current_view()
  if view then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen ")
  end
end, desc = "git diff" }

-- task manager
-- maps.n["<leader>tn"] = { "<cmd>ToDoTxtCapture<cr>", desc= "New Todo"}
maps.n["<M-2>"] = { "<cmd>ToDoTxtTasksToggle<cr>", desc= "Toggle TodoBoard"}

my.set_mappings(maps)
