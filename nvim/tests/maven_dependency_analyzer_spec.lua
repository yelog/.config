local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

vim.opt.rtp:append(vim.fn.expand("~/.local/share/nvim/lazy/nui.nvim"))

package.preload["custom.maven_profiles"] = function()
  return { find_project_root = function() return "/workspace/demo" end }
end
package.preload["maven.sources"] = function()
  return {
    load_project_dependencies = function(_, _, callback)
      callback("SUCCEED", {
        { id = "root", group_id = "org.demo", artifact_id = "root", version = "1.0", scope = "compile" },
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
print("maven-dependency-analyzer-tests: ok")
