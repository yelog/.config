local helper = require("utils.helper")
local keys = require("config.keys")

local M = {}

hs.hotkey.bind(keys.super, "R", "Reload Configuration", function()
  hs.alert.show("Configuration Reload", 1.5)
  hs.timer.doAfter(0.1, hs.reload)
end)

hs.hotkey.bind(keys.hyper, ".", "Toggle Stage Manager", function()
  helper.toggleStageManager()
end)

return M
