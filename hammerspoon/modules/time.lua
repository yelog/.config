local keys = require("config.keys")

local M = {}

hs.hotkey.bind(keys.hyper, "space", function()
  hs.alert.show(os.date("%A              📅%B %d %Y              🕐%I:%M:%S %p"))
end)

return M