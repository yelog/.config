local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

vim.opt.rtp:append(vim.fn.expand("~/.local/share/nvim/lazy/nui.nvim"))

local loaded_pom
local loaded_args
local dependency_loads = 0
local command_builder = {}
local original_dependency_builder = function()
  return { cmd = "mvn", args = { "-B", "dependency:graph" } }
end
command_builder.build_mvn_dependencies_cmd = original_dependency_builder
package.preload["maven.utils.cmd_builder"] = function() return command_builder end
package.preload["custom.maven_profiles"] = function()
  return {
    find_nearest_pom = function()
      if dependency_loads == 0 then return "/workspace/demo/module/pom.xml" end
      return nil
    end,
  }
end
package.preload["maven.sources"] = function()
  return {
    load_project_dependencies = function(pom, _, callback)
      dependency_loads = dependency_loads + 1
      loaded_pom = pom
      loaded_args = command_builder.build_mvn_dependencies_cmd(pom, "/tmp", "dependencies.txt").args
      callback("SUCCEED", {
        { id = "root", group_id = "org.demo", artifact_id = "root", version = "1.0", scope = "compile", size = 2, conflict_version = "0.9" },
        { id = "framework", parent_id = "root", group_id = "org.demo", artifact_id = "framework-core", version = "1.0", scope = "compile", size = 4 },
        { id = "fastjson", parent_id = "framework", group_id = "com.alibaba", artifact_id = "fastjson", version = "2.0", scope = "compile", size = 10 },
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
assert(rendered:find("fastjson", 1, true), "search results should expand every ancestor path to matching dependencies")
assert(rendered:find("1 direct", 1, true), "workbench should show dependency summary")
assert(rendered:find("g group", 1, true), "workbench should advertise metadata controls")
assert(rendered:find("[! CONFLICT]", 1, true), "direct conflicts should retain an explicit conflict badge")
assert(rendered:find("active 1.0 <- omitted 0.9", 1, true), "conflicts should compare active and omitted versions")
vim.cmd("normal g")
rendered = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(popup_win), 0, -1, false), "\n")
assert(rendered:find("com.alibaba", 1, true), "group toggle should reveal groupId metadata")
vim.cmd("normal R")
assert(dependency_loads == 2, "remote refresh should resolve dependencies again from the panel POM")
assert(loaded_pom == "/workspace/demo/module/pom.xml", "remote refresh should reuse the panel POM")
assert(vim.tbl_contains(loaded_args, "-U"), "remote refresh should pass Maven -U to the dependency graph command")
assert(command_builder.build_mvn_dependencies_cmd == original_dependency_builder,
  "remote refresh should restore the dependency graph command builder")
print("maven-dependency-analyzer-tests: ok")
