local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

vim.opt.rtp:append(vim.fn.expand("~/.local/share/nvim/lazy/nui.nvim"))

local loaded_pom
package.preload["custom.maven_profiles"] = function()
  return {
    find_nearest_pom = function() return "/workspace/demo/module/pom.xml" end,
  }
end
package.preload["maven.sources"] = function()
  return {
    load_project_dependencies = function(pom, _, callback)
      loaded_pom = pom
      callback("SUCCEED", {
        { id = "root", group_id = "org.demo", artifact_id = "root", version = "1.0", scope = "compile" },
        { id = "framework", parent_id = "root", group_id = "org.demo", artifact_id = "framework-core", version = "1.0", scope = "compile" },
        { id = "fastjson", parent_id = "framework", group_id = "com.alibaba", artifact_id = "fastjson", version = "2.0", scope = "compile" },
      })
    end,
  }
end
package.preload["maven.utils"] = function()
  return { SUCCEED_STATE = "SUCCEED", humanize_size = function() return nil end }
end

local analyzer = require("custom.maven_dependency_analyzer")
analyzer.setup()

assert(vim.fn.exists(":MavenDependencies") == 2, "dependency analyzer command should be registered without loading NUI")
analyzer.open()
assert(vim.wait(100, function() return #vim.api.nvim_list_wins() > 1 end),
  "dependency analyzer should mount a NUI popup after Maven resolution")
assert(loaded_pom == "/workspace/demo/module/pom.xml", "analyzer should load the nearest module POM")

local popup_win = vim.tbl_filter(function(win)
  return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "maven_dependencies"
end, vim.api.nvim_list_wins())[1]
assert(popup_win, "dependency analyzer should expose its popup window")
local underlying_win = vim.tbl_filter(function(win) return win ~= popup_win end, vim.api.nvim_list_wins())[1]
assert(underlying_win, "dependency analyzer should preserve the originating window")

vim.ui.input = function(_, callback)
  vim.api.nvim_set_current_win(underlying_win)
  callback("fastjson")
end
vim.api.nvim_set_current_win(popup_win)
vim.cmd("normal /")

assert(vim.api.nvim_get_current_win() == popup_win, "search completion should return focus to the dependency popup")
local rendered = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(popup_win), 0, -1, false), "\n")
assert(rendered:find("com.alibaba:fastjson", 1, true), "search results should expand every ancestor path to matching dependencies")
print("maven-dependency-analyzer-tests: ok")
