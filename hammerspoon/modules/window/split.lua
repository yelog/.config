local helper = require("utils.helper")
local config = require("config.windows")
local windowState = require("modules.window.init")

local M = {}

if config.last_application_left_right_layout ~= nil then
  hs.hotkey.bind(
    config.last_application_left_right_layout.prefix,
    config.last_application_left_right_layout.key,
    config.last_application_left_right_layout.message,
    function()
      local currentWindow = hs.window.focusedWindow()
      if currentWindow and windowState.previousWindow and currentWindow ~= windowState.previousWindow then
        local screenFrame = currentWindow:screen():frame()
        local currentFrame = currentWindow:frame()
        local previousFrame = windowState.previousWindow:frame()

        if currentFrame.x == screenFrame.x and currentFrame.w == screenFrame.w / 2 and
            previousFrame.x == screenFrame.x + screenFrame.w / 2 and previousFrame.w == screenFrame.w / 2 then
          currentWindow:setFrame(hs.geometry.rect(screenFrame.x + screenFrame.w / 2, screenFrame.y, screenFrame.w / 2,
            screenFrame.h))
          windowState.previousWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w / 2, screenFrame.h))
        else
          currentWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w / 2, screenFrame.h))
          windowState.previousWindow:setFrame(hs.geometry.rect(screenFrame.x + screenFrame.w / 2, screenFrame.y, screenFrame.w / 2,
            screenFrame.h))
        end
      end
    end
  )
end

if config.last_application_up_down_layout ~= nil then
  hs.hotkey.bind(
    config.last_application_up_down_layout.prefix,
    config.last_application_up_down_layout.key,
    config.last_application_up_down_layout.message,
    function()
      local currentWindow = hs.window.focusedWindow()
      if currentWindow and windowState.previousWindow and currentWindow ~= windowState.previousWindow then
        local screenFrame = currentWindow:screen():frame()
        local currentFrame = currentWindow:frame()
        local previousFrame = windowState.previousWindow:frame()

        if currentFrame.y == screenFrame.y and currentFrame.h == screenFrame.h / 2 and
            previousFrame.y == screenFrame.y + screenFrame.h / 2 and previousFrame.h == screenFrame.h / 2 then
          currentWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y + screenFrame.h / 2, screenFrame.w,
            screenFrame.h / 2))
          windowState.previousWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w, screenFrame.h / 2))
        else
          currentWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w, screenFrame.h / 2))
          windowState.previousWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y + screenFrame.h / 2, screenFrame.w,
            screenFrame.h / 2))
        end
      end
    end
  )
end

local function findSplitPair(win)
  if not win then return nil, nil end

  local winFrame = win:frame()
  local screen = win:screen()
  local allWindows = hs.window.filter.default:getWindows(hs.window.filter.sortByFocusedLast)

  for _, otherWin in ipairs(allWindows) do
    if otherWin ~= win and otherWin:isStandard() and otherWin:screen() == screen then
      local otherFrame = otherWin:frame()

      if math.abs(winFrame.y - otherFrame.y) < 10 and math.abs(winFrame.h - otherFrame.h) < 10 then
        if winFrame.x < otherFrame.x and math.abs(winFrame.x + winFrame.w - otherFrame.x) < 10 then
          return "left_right", otherWin
        end
        if otherFrame.x < winFrame.x and math.abs(otherFrame.x + otherFrame.w - winFrame.x) < 10 then
          return "left_right", otherWin
        end
      end

      if math.abs(winFrame.x - otherFrame.x) < 10 and math.abs(winFrame.w - otherFrame.w) < 10 then
        if winFrame.y < otherFrame.y and math.abs(winFrame.y + winFrame.h - otherFrame.y) < 10 then
          return "up_down", otherWin
        end
        if otherFrame.y < winFrame.y and math.abs(otherFrame.y + otherFrame.h - winFrame.y) < 10 then
          return "up_down", otherWin
        end
      end
    end
  end

  return nil, nil
end

local function adjustSplitBoundary(direction)
  local win = hs.window.focusedWindow()
  if not win then return end

  local splitType, otherWin = findSplitPair(win)
  if not splitType or not otherWin then
    hs.alert.show("No split window found")
    return
  end

  local screenFrame = win:screen():frame()
  local winFrame = win:frame()
  local otherFrame = otherWin:frame()
  local step = math.min(screenFrame.w, screenFrame.h) * 0.05
  local minSize = math.min(screenFrame.w, screenFrame.h) * 0.25

  if splitType == "left_right" then
    local leftWin, rightWin, leftFrame, rightFrame
    if winFrame.x < otherFrame.x then
      leftWin, rightWin = win, otherWin
      leftFrame, rightFrame = winFrame, otherFrame
    else
      leftWin, rightWin = otherWin, win
      leftFrame, rightFrame = otherFrame, winFrame
    end

    local newWidth = leftFrame.w + (direction == "shrink" and -step or step)
    if newWidth < minSize or (screenFrame.w - newWidth) < minSize then
      return
    end

    local commonY = screenFrame.y
    local commonH = screenFrame.h
    leftWin:setFrame(hs.geometry.rect(screenFrame.x, commonY, newWidth, commonH))
    rightWin:setFrame(hs.geometry.rect(screenFrame.x + newWidth, commonY, screenFrame.w - newWidth, commonH))
  elseif splitType == "up_down" then
    local topWin, bottomWin, topFrame, bottomFrame
    if winFrame.y < otherFrame.y then
      topWin, bottomWin = win, otherWin
      topFrame, bottomFrame = winFrame, otherFrame
    else
      topWin, bottomWin = otherWin, win
      topFrame, bottomFrame = otherFrame, winFrame
    end

    local newHeight = topFrame.h + (direction == "shrink" and -step or step)
    if newHeight < minSize or (screenFrame.h - newHeight) < minSize then
      return
    end

    local commonX = screenFrame.x
    local commonW = screenFrame.w
    topWin:setFrame(hs.geometry.rect(commonX, screenFrame.y, commonW, newHeight))
    bottomWin:setFrame(hs.geometry.rect(commonX, screenFrame.y + newHeight, commonW, screenFrame.h - newHeight))
  end
end

local function shrinkSplitBoundary()
  adjustSplitBoundary("shrink")
end

local function expandSplitBoundary()
  adjustSplitBoundary("expand")
end

if config.split_boundary_shrink ~= nil then
  hs.hotkey.bind(
    config.split_boundary_shrink.prefix,
    config.split_boundary_shrink.key,
    config.split_boundary_shrink.message,
    shrinkSplitBoundary,
    nil,
    shrinkSplitBoundary
  )
end

if config.split_boundary_expand ~= nil then
  hs.hotkey.bind(
    config.split_boundary_expand.prefix,
    config.split_boundary_expand.key,
    config.split_boundary_expand.message,
    expandSplitBoundary,
    nil,
    expandSplitBoundary
  )
end

return M