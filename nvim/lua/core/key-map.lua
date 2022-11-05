local is_available = my.is_available

local maps = { i = {}, n = {}, v = {}, t = {}, [""] = {} }

maps[""]["<Space>"] = "<Nop>"

-- Base
maps.n["Q"] = { "<cmd>wqa<cr>", desc = "Quit" }

-- Telescope
maps.n["<leader>ff"] = { function() require("telescope.builtin").find_files() end, desc = "Search file" }
maps.n["<leader>fb"] = { function() require("telescope.builtin").buffers() end, desc = "Search buffers" }
maps.n["<leader>fr"] = { function() require("telescope.builtin").lsp_references() end, desc = "Search references" }
maps.n["<leader>ft"] = { function() require("telescope.builtin").help_tags() end, desc = "Search tags" }
maps.n["<leader>fm"] = { function() require("telescope.builtin").marks() end, desc = "Search marks" }
maps.n["<leader>fh"] = { function() require("telescope.builtin").oldfiles() end, desc = "Search hisotry" }
maps.n["<leader>f;"] = { function() require("telescope.builtin").builtin() end, desc = "Search builtin" }
maps.n["<leader>fw"] = { function() require("telescope.builtin").live_grep() end, desc = "Search word" }
maps.n["<leader>fW"] = {
  function()
    require("telescope.builtin").live_grep {
      additional_args = function(args) return vim.list_extend(args, { "--hidden", "--no-ignore" }) end,
    }
  end,
  desc = "Search words in all files",
}

-- neo-tree
-- maps.n["<leader>e"] = { function() require("telescope.builtin").find_files() end, desc = "Search file" }
-- maps.n["<leader>e"] = { "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" }
maps.n["<M-1>"] = { "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" }
-- maps.n["<leader>o"] = { "<cmd>Neotree focus<cr>", desc = "Focus Explorer" }

-- bufferline
maps.n["<c-n>"] = { "<cmd>BufferLineCycleNext<cr>", desc = "Buffer Next" }
maps.n["<c-p>"] = { "<cmd>BufferLineCyclePrev<cr>", desc = "Buffer Previous" }
maps.n[">b"] = { "<cmd>BufferLineMoveNext<cr>", desc = "Buffer Move Next" }
maps.n["<b"] = { "<cmd>BufferLineMovePrev<cr>", desc = "Buffer Move Previous" }
maps.n["<c-q>"] = { "<cmd>bdelete<cr>", desc = "Buffer Close" }

my.set_mappings(maps)
