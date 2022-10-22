local is_available = my.is_available

local maps = { i = {}, n = {}, v = {}, t = {}, [""] = {} }

maps[""]["<Space>"] = "<Nop>"

-- Telescope
maps.n["<leader>ff"] = { function() require("telescope.builtin").find_files() end, desc = "Search file" }
maps.n["<leader>fw"] = { function() require("telescope.builtin").live_grep() end, desc = "Search word" }
maps.n["<leader>fb"] = { function() require("telescope.builtin").buffers() end, desc = "Search buffers" }
maps.n["<leader>ft"] = { function() require("telescope.builtin").help_tags() end, desc = "Search tags" }
maps.n["<leader>fm"] = { function() require("telescope.builtin").marks() end, desc = "Search marks" }


my.set_mappings(maps)
