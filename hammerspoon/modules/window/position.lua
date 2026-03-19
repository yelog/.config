local helper = require("utils.helper")
local config = require("config.windows")

local M = {}

local function bindPosition(keyConfig, setFrameFunc)
  if keyConfig ~= nil then
    hs.hotkey.bind(keyConfig.prefix, keyConfig.key, keyConfig.message, function()
      local win = hs.window.focusedWindow()
      if not win then return end
      local f = win:frame()
      local screen = win:screen()
      local max = screen:frame()
      setFrameFunc(f, max, screen)
      win:setFrame(f)
    end)
  end
end

bindPosition(config.left, function(f, max, screen)
  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
end)

bindPosition(config.right, function(f, max, screen)
  f.x = max.x + (max.w / 2)
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
end)

bindPosition(config.up, function(f, max, screen)
  f.x = max.x
  f.y = max.y
  f.w = max.w
  f.h = max.h / 2
end)

bindPosition(config.down, function(f, max, screen)
  f.x = max.x
  f.y = max.y + (max.h / 2)
  f.w = max.w
  f.h = max.h / 2
end)

bindPosition(config.top_left, function(f, max, screen)
  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h / 2
end)

bindPosition(config.top_right, function(f, max, screen)
  f.x = max.x + (max.w / 2)
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h / 2
end)

bindPosition(config.left_bottom, function(f, max, screen)
  f.x = max.x
  f.y = max.y + (max.h / 2)
  f.w = max.w / 2
  f.h = max.h / 2
end)

bindPosition(config.right_bottom, function(f, max, screen)
  f.x = max.x + (max.w / 2)
  f.y = max.y + (max.h / 2)
  f.w = max.w / 2
  f.h = max.h / 2
end)

bindPosition(config.one, function(f, max, screen)
  f.x = max.x
  f.y = max.y
  f.w = max.w / 3
  f.h = max.h / 3
end)

bindPosition(config.two, function(f, max, screen)
  f.x = max.x + (max.w / 3)
  f.y = max.y
  f.w = max.w / 3
  f.h = max.h / 3
end)

bindPosition(config.three, function(f, max, screen)
  f.x = max.x + (max.w / 3) * 2
  f.y = max.y
  f.w = max.w / 3
  f.h = max.h / 3
end)

bindPosition(config.four, function(f, max, screen)
  f.x = max.x
  f.y = max.y + (max.h / 3)
  f.w = max.w / 3
  f.h = max.h / 3
end)

bindPosition(config.five, function(f, max, screen)
  f.x = max.x + (max.w / 3)
  f.y = max.y + (max.h / 3)
  f.w = max.w / 3
  f.h = max.h / 3
end)

bindPosition(config.six, function(f, max, screen)
  f.x = max.x + (max.w / 3) * 2
  f.y = max.y + (max.h / 3)
  f.w = max.w / 3
  f.h = max.h / 3
end)

bindPosition(config.seven, function(f, max, screen)
  f.x = max.x
  f.y = max.y + (max.h / 3) * 2
  f.w = max.w / 3
  f.h = max.h / 3
end)

bindPosition(config.eight, function(f, max, screen)
  f.x = max.x + (max.w / 3)
  f.y = max.y + (max.h / 3) * 2
  f.w = max.w / 3
  f.h = max.h / 3
end)

bindPosition(config.nine, function(f, max, screen)
  f.x = max.x + (max.w / 3) * 2
  f.y = max.y + (max.h / 3) * 2
  f.w = max.w / 3
  f.h = max.h / 3
end)

return M