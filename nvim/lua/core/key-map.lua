local is_available = my.is_available

local maps = { i = {}, n = {}, v = {}, t = {}, [""] = {} }

maps[""]["<Space>"] = "<Nop>"

-- Telescope
maps.n["<leader>ff"] = { function() require("telescope.builtin").find_files() end, desc = "Search file" }
maps.n["<leader>fw"] = { function() require("telescope.builtin").live_grep() end, desc = "Search word" }
maps.n["<leader>fb"] = { function() require("telescope.builtin").buffers() end, desc = "Search buffers" }
maps.n["<leader>ft"] = { function() require("telescope.builtin").help_tags() end, desc = "Search tags" }
maps.n["<leader>fm"] = { function() require("telescope.builtin").marks() end, desc = "Search marks" }

-- neo-tree
-- maps.n["<leader>e"] = { function() require("telescope.builtin").find_files() end, desc = "Search file" }
maps.n["<leader>e"] = { "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" }
maps.n["<M-1>"] = { "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" }
maps.n["<leader>o"] = { "<cmd>Neotree focus<cr>", desc = "Focus Explorer" }

-- bufferline
maps.n["<c-n>"] = { "<cmd>BufferLineCycleNext<cr>", desc = "Buffer Next" }
maps.n["<c-p>"] = { "<cmd>BufferLineCyclePrev<cr>", desc = "Buffer Previous" }
maps.n[">b"] = { "<cmd>BufferLineMoveNext<cr>", desc = "Buffer Move Next" }
maps.n["<b"] = { "<cmd>BufferLineMovePrev<cr>", desc = "Buffer Move Previous" }
maps.n["Q"] = { "<cmd>bdelete<cr>", desc = "Buffer Close" }

my.set_mappings(maps)
