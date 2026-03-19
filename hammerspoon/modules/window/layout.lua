local helper = require("utils.helper")

local M = {}

local AUTO_LAYOUT_TYPE = {
  GRID = "GRID",
  HORIZONTAL_OR_VERTICAL = "HORIZONTAL_OR_VERTICAL",
}

local function layout_grid(windows)
  local focusedScreen = hs.screen.mainScreen()
  local layout = {
    { num = 1, row = 0, column = 0 },
    { num = 2, row = 0, column = 1 },
    { num = 4, row = 1, column = 1 },
    { num = 6, row = 1, column = 2 },
    { num = 9, row = 2, column = 2 },
    { num = 12, row = 2, column = 3 },
    { num = 16, row = 3, column = 3 },
  }

  local windowNum = #windows
  local focusedScreenFrame = focusedScreen:frame()
  for _, item in ipairs(layout) do
    if windowNum <= item.num then
      local column = item.column
      local row = item.row
      if helper.isVerticalScreen(focusedScreen) then
        if item.column > item.row then
          column = item.row
          row = item.column
        end
      end
      local widthForPerWindow = focusedScreenFrame.w / (column + 1)
      local heightForPerWindow = focusedScreenFrame.h / (row + 1)
      local nth = 1

      for i = 0, column, 1 do
        for j = 0, row, 1 do
          if nth > windowNum then
            break
          end
          local win = windows[nth]
          local windowFrame = win:frame()
          windowFrame.x = focusedScreenFrame.x + i * widthForPerWindow
          windowFrame.y = focusedScreenFrame.y + j * heightForPerWindow
          windowFrame.w = widthForPerWindow
          windowFrame.h = heightForPerWindow
          win:setFrame(windowFrame)
          win:focus()
          nth = nth + 1
        end
      end
      break
    end
  end
end

local function layout_horizontal(windows, focusedScreenFrame)
  local windowNum = #windows
  local heightForPerWindow = focusedScreenFrame.h / windowNum
  for i, win in ipairs(windows) do
    local windowFrame = win:frame()
    windowFrame.x = focusedScreenFrame.x
    windowFrame.y = focusedScreenFrame.y + heightForPerWindow * (i - 1)
    windowFrame.w = focusedScreenFrame.w
    windowFrame.h = heightForPerWindow
    win:setFrame(windowFrame)
    win:focus()
  end
end

local function layout_vertical(windows, focusedScreenFrame)
  local windowNum = #windows
  local widthForPerWindow = focusedScreenFrame.w / windowNum
  for i, win in ipairs(windows) do
    local windowFrame = win:frame()
    windowFrame.x = focusedScreenFrame.x + widthForPerWindow * (i - 1)
    windowFrame.y = focusedScreenFrame.y
    windowFrame.w = widthForPerWindow
    windowFrame.h = focusedScreenFrame.h
    win:setFrame(windowFrame)
    win:focus()
  end
end

local function layout_horizontal_or_vertical(windows)
  local focusedScreen = hs.screen.mainScreen()
  local focusedScreenFrame = focusedScreen:frame()
  if helper.isVerticalScreen(focusedScreen) then
    layout_horizontal(windows, focusedScreenFrame)
  else
    layout_vertical(windows, focusedScreenFrame)
  end
end

local function layout_auto(windows, auto_layout_type)
  if AUTO_LAYOUT_TYPE.GRID == auto_layout_type then
    layout_grid(windows)
  elseif AUTO_LAYOUT_TYPE.HORIZONTAL_OR_VERTICAL == auto_layout_type then
    layout_horizontal_or_vertical(windows)
  end
end

local function same_application(auto_layout_type)
  local focusedWindow = hs.window.focusedWindow()
  local application = focusedWindow:application()
  local focusedScreen = focusedWindow:screen()
  local visibleWindows = application:visibleWindows()
  for k, visibleWindow in ipairs(visibleWindows) do
    if not visibleWindow:isStandard() then
      table.remove(visibleWindows, k)
    end
    if visibleWindow ~= focusedWindow then
      visibleWindow:moveToScreen(focusedScreen)
    end
  end
  layout_auto(visibleWindows, auto_layout_type)
end

local function same_space(auto_layout_type)
  local success, spaceId = pcall(function()
    return hs.spaces.focusedSpace()
  end)

  if not success or spaceId == nil then
    hs.alert.show("hs.spaces 不可用，无法执行此操作")
    return
  end

  local windowIds = hs.spaces.windowsForSpace(spaceId)
  local windows = {}
  for _, windowId in ipairs(windowIds) do
    local win = hs.window.get(windowId)
    if win ~= nil then
      table.insert(windows, win)
    end
  end
  layout_auto(windows, auto_layout_type)
end

local config = require("config.windows")

if config.same_application_auto_layout_grid ~= nil then
  hs.hotkey.bind(
    config.same_application_auto_layout_grid.prefix,
    config.same_application_auto_layout_grid.key,
    config.same_application_auto_layout_grid.message,
    function()
      same_application(AUTO_LAYOUT_TYPE.GRID)
    end
  )
end

if config.same_space_auto_layout_grid ~= nil then
  hs.hotkey.bind(
    config.same_space_auto_layout_grid.prefix,
    config.same_space_auto_layout_grid.key,
    config.same_space_auto_layout_grid.message,
    function()
      same_space(AUTO_LAYOUT_TYPE.GRID)
    end
  )
end

if config.same_space_auto_layout_horizontal_or_vertical ~= nil then
  hs.hotkey.bind(
    config.same_space_auto_layout_horizontal_or_vertical.prefix,
    config.same_space_auto_layout_horizontal_or_vertical.key,
    config.same_space_auto_layout_horizontal_or_vertical.message,
    function()
      same_space(AUTO_LAYOUT_TYPE.HORIZONTAL_OR_VERTICAL)
    end
  )
end

return M