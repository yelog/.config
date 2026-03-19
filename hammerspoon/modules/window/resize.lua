local helper = require("utils.helper")
local config = require("config.windows")

local M = {}

if config.center_or_fullscreen ~= nil then
  hs.hotkey.bind(
    config.center_or_fullscreen.prefix,
    config.center_or_fullscreen.key,
    config.center_or_fullscreen.message,
    function()
      local win = hs.window.focusedWindow()
      if not win then return end
      local f = win:frame()
      local screen = win:screen()
      local max = screen:frame()

      if helper.isStageManager() then
        local stageWidth = 170
        if f.w == max.w and f.h == max.h then
          f.x = max.x + stageWidth
          f.y = max.y
          f.w = max.w - stageWidth
          f.h = max.h
          win:setFrame(f)
        else
          win:maximize()
        end
      else
        if f.w == max.w and f.h == max.h then
          f.x = max.x + max.w / 4
          f.y = max.y + max.h / 4
          f.w = max.w / 2
          f.h = max.h / 2
          win:setFrame(f)
        else
          win:maximize()
        end
      end
    end
  )
end

hs.hotkey.bind(config.zoom.prefix, config.zoom.key, config.zoom.message, function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.w = f.w + 40
  f.h = f.h + 40
  f.x = f.x - 20
  f.y = f.y - 20
  if f.x < max.x then f.x = max.x end
  if f.y < max.y then f.y = max.y end
  if f.w > max.w then f.w = max.w end
  if f.h > max.h then f.h = max.h end
  win:setFrame(f)
end)

hs.hotkey.bind(config.narrow.prefix, config.narrow.key, config.narrow.message, function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local f = win:frame()
  f.w = f.w - 40
  f.h = f.h - 40
  f.x = f.x + 20
  f.y = f.y + 20
  win:setFrame(f)
end)

return M