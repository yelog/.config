local helper = require("utils.helper")
local config = require("config.windows")

local M = {}

if config.switchNextScreen ~= nil then
  hs.hotkey.bind(
    config.switchNextScreen.prefix,
    config.switchNextScreen.key,
    config.switchNextScreen.message,
    function()
      local win = hs.window.focusedWindow()
      if not win then return end
      local screen = win:screen()
      local f = win:frame()
      local max = screen:frame()
      local isMax = f.w == max.w and f.h == max.h
      win:move(f:toUnitRect(screen:frame()), screen:next(), true, 0)
      if isMax then
        win:maximize()
      end
      helper.setMousePos()
    end
  )
end

return M