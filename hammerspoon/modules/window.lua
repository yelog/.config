-- 窗口管理

require("modules.key-map")

-- 关闭动画持续时间
hs.window.animationDuration = 0.125

-- 窗口枚举
local AUTO_LAYOUT_TYPE = {
  -- 网格式布局
  GRID = "GRID",
  -- 水平或垂直评分
  HORIZONTAL_OR_VERTICAL = "HORIZONTAL_OR_VERTICAL",
}

-- 记录上次激活的窗口和前一个窗口
local lastWindow = nil
local previousWindow = nil

-- 定义一个窗口激活的回调函数
hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function(window)
  if lastWindow and lastWindow ~= window then
    previousWindow = lastWindow
  end
  lastWindow = window
end)

-- 当前激活应用窗口和上一个激活的应用窗口进行左右分屏
if windows.last_application_left_right_layout ~= nil then
  hs.hotkey.bind(
    windows.last_application_left_right_layout.prefix,
    windows.last_application_left_right_layout.key,
    windows.last_application_left_right_layout.message,
    function()
      local currentWindow = hs.window.focusedWindow()
      if currentWindow and previousWindow and currentWindow ~= previousWindow then
        local screenFrame = currentWindow:screen():frame()
        local currentFrame = currentWindow:frame()
        local previousFrame = previousWindow:frame()

        if currentFrame.x == screenFrame.x and currentFrame.w == screenFrame.w / 2 and
            previousFrame.x == screenFrame.x + screenFrame.w / 2 and previousFrame.w == screenFrame.w / 2 then
          -- 交换位置
          currentWindow:setFrame(hs.geometry.rect(screenFrame.x + screenFrame.w / 2, screenFrame.y, screenFrame.w / 2,
            screenFrame.h))
          previousWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w / 2, screenFrame.h))
        else
          -- 设置当前窗口在屏幕的左半边
          currentWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w / 2, screenFrame.h))
          -- 设置上次激活的窗口在屏幕的右半边
          previousWindow:setFrame(hs.geometry.rect(screenFrame.x + screenFrame.w / 2, screenFrame.y, screenFrame.w / 2,
            screenFrame.h))
        end
        print('last_application_layout success')
      else
        print('last_application_layout failed')
      end
    end
  )
end

-- 同一应用的所有窗口自动网格式布局
if windows.same_application_auto_layout_grid ~= nil then
  hs.hotkey.bind(
    windows.same_application_auto_layout_grid.prefix,
    windows.same_application_auto_layout_grid.key,
    windows.same_application_auto_layout_grid.message,
    function()
      same_application(AUTO_LAYOUT_TYPE.GRID)
    end
  )
end

-- 同一应用的所有窗口自动水平均分或垂直均分
-- if windows.same_application_auto_layout_horizontal_or_vertical ~= nil then
--   hs.hotkey.bind(
--     windows.same_application_auto_layout_horizontal_or_vertical.prefix,
--     windows.same_application_auto_layout_horizontal_or_vertical.key,
--     windows.same_application_auto_layout_horizontal_or_vertical.message,
--     function()
--       same_application(AUTO_LAYOUT_TYPE.HORIZONTAL_OR_VERTICAL)
--     end
--   )
-- end

-- 同一工作空间下的所有窗口自动网格式布局
if windows.same_space_auto_layout_grid ~= nil then
  hs.hotkey.bind(
    windows.same_space_auto_layout_grid.prefix,
    windows.same_space_auto_layout_grid.key,
    windows.same_space_auto_layout_grid.message,
    function()
      same_space(AUTO_LAYOUT_TYPE.GRID)
    end
  )
end

-- 同一工作空间下的所有窗口自动水平均分或垂直均分
if windows.same_space_auto_layout_horizontal_or_vertical ~= nil then
  hs.hotkey.bind(
    windows.same_space_auto_layout_horizontal_or_vertical.prefix,
    windows.same_space_auto_layout_horizontal_or_vertical.key,
    windows.same_space_auto_layout_horizontal_or_vertical.message,
    function()
      same_space(AUTO_LAYOUT_TYPE.HORIZONTAL_OR_VERTICAL)
    end
  )
end

-- 记录上次激活的窗口和前一个窗口
local lastWindow = nil
local previousWindow = nil

-- 定义一个窗口激活的回调函数
-- 使用 pcall 保护，避免 hs.spaces 错误导致整个配置加载失败
pcall(function()
  hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function(window)
    if lastWindow and lastWindow ~= window then
      previousWindow = lastWindow
    end
    lastWindow = window
  end)
end)
-- 当前激活应用窗口和上一个激活的应用窗口进行左右分屏
function last_application_layout()
  -- -- 创建一个窗口过滤器
  -- local wf = hs.window.filter.default
  --
  -- -- 获取当前窗口
  -- local currentWindow = hs.window.focusedWindow()
  --
  -- -- 获取上次激活的窗口
  -- local lastWindow = nil
  -- local windows = wf:getWindows(hs.window.filter.sortByFocusedLast)
  --
  -- if #windows > 1 then
  --   lastWindow = windows[2]
  -- end
  --
  -- if currentWindow and lastWindow then
  --   -- 获取屏幕框架
  --   local screenFrame = currentWindow:screen():frame()
  --
  --   -- 设置当前窗口在屏幕的左半边
  --   currentWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w / 2, screenFrame.h))
  --
  --   -- 设置上次激活的窗口在屏幕的右半边
  --   lastWindow:setFrame(hs.geometry.rect(screenFrame.x + screenFrame.w / 2, screenFrame.y, screenFrame.w / 2,
  --     screenFrame.h))
  --   print('last_application_layout ssuccess')
  -- else
  --   print('last_application_layout failed')
  -- end
  local currentWindow = hs.window.focusedWindow()

  if currentWindow and previousWindow and currentWindow ~= previousWindow then
    -- 获取屏幕框架
    local screenFrame = currentWindow:screen():frame()

    -- 设置当前窗口在屏幕的左半边
    currentWindow:setFrame(hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w / 2, screenFrame.h))

    -- 设置上次激活的窗口在屏幕的右半边
    previousWindow:setFrame(hs.geometry.rect(screenFrame.x + screenFrame.w / 2, screenFrame.y, screenFrame.w / 2,
      screenFrame.h))
    print('last_application_layout ssuccess')
  else
    print('last_application_layout failed')
  end
end

function same_application(auto_layout_type)
  local focusedWindow = hs.window.focusedWindow()
  local application = focusedWindow:application()
  -- 当前屏幕
  local focusedScreen = focusedWindow:screen()
  -- 同一应用的所有窗口
  local visibleWindows = application:visibleWindows()
  for k, visibleWindow in ipairs(visibleWindows) do
    -- 关于 Standard window 可参考：http://www.hammerspoon.org/docs/hs.window.html#isStandard
    -- 例如打开 Finder 就一定会存在一个非标准窗口，这种窗口需要排除
    if not visibleWindow:isStandard() then
      table.remove(visibleWindows, k)
    end
    if visibleWindow ~= focusedWindow then
      -- 将同一应用的其他窗口移动到当前屏幕
      visibleWindow:moveToScreen(focusedScreen)
    end
  end
  layout_auto(visibleWindows, auto_layout_type)
end

function same_space(auto_layout_type)
  -- 使用 pcall 保护 hs.spaces 调用
  local success, spaceId = pcall(function()
    return hs.spaces.focusedSpace()
  end)
  
  if not success or spaceId == nil then
    hs.alert.show("hs.spaces 不可用，无法执行此操作")
    return
  end
  
  -- 该空间下的所有 window 的 id，注意这里的 window 概念和 Hammerspoon 的 window 概念并不同，详请参考：http://www.hammerspoon.org/docs/hs.spaces.html#windowsForSpace
  local windowIds = hs.spaces.windowsForSpace(spaceId)
  local windows = {}
  for k, windowId in ipairs(windowIds) do
    local window = hs.window.get(windowId)
    if window ~= nil then
      table.insert(windows, window)
    end
  end
  layout_auto(windows, auto_layout_type)
end

function layout_auto(windows, auto_layout_type)
  if AUTO_LAYOUT_TYPE.GRID == auto_layout_type then
    layout_grid(windows)
  elseif AUTO_LAYOUT_TYPE.HORIZONTAL_OR_VERTICAL == auto_layout_type then
    layout_horizontal_or_vertical(windows)
  end
end

-- 平铺模式-网格均分
function layout_grid(windows)
  local focusedScreen = hs.screen.mainScreen()
  -- TODO-JING num = 3、5、7、8、10、11、13、14、15
  -- TODO-JING せめて num = 3 の問題を消して

  local layout = {
    {
      num = 1,
      row = 0,
      column = 0,
    },
    {
      num = 2,
      row = 0,
      column = 1,
    },
    {
      num = 4,
      row = 1,
      column = 1,
    },
    {
      num = 6,
      row = 1,
      column = 2,
    },
    {
      num = 9,
      row = 2,
      column = 2,
    },
    {
      num = 12,
      row = 2,
      column = 3,
    },
    {
      num = 16,
      row = 3,
      column = 3,
    },
  }

  local windowNum = #windows
  local focusedScreenFrame = focusedScreen:frame()
  for _k, item in ipairs(layout) do
    if windowNum <= item.num then
      local column = item.column
      local row = item.row
      if isVerticalScreen(focusedScreen) then
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
          -- 已没有可用窗口
          if nth > windowNum then
            break
          end
          local window = windows[nth]
          local windowFrame = window:frame()
          windowFrame.x = focusedScreenFrame.x + i * widthForPerWindow
          windowFrame.y = focusedScreenFrame.y + j * heightForPerWindow
          windowFrame.w = widthForPerWindow
          windowFrame.h = heightForPerWindow
          window:setFrame(windowFrame)
          -- 让窗口获取焦点以将窗口置前
          window:focus()
          nth = nth + 1
        end
      end
      break
    end
  end
end

-- 平铺模式 - 水平（竖屏）或垂直（横屏）均分
function layout_horizontal_or_vertical(windows)
  local focusedScreen = hs.screen.mainScreen()
  local focusedScreenFrame = focusedScreen:frame()
  -- 如果是竖屏，就水平均分，否则垂直均分
  if isVerticalScreen(focusedScreen) then
    layout_horizontal(windows, focusedScreenFrame)
  else
    layout_vertical(windows, focusedScreenFrame)
  end
end

-- 平铺模式 - 水平均分
function layout_horizontal(windows, focusedScreenFrame)
  local windowNum = #windows
  local heightForPerWindow = focusedScreenFrame.h / windowNum
  for i, window in ipairs(windows) do
    local windowFrame = window:frame()
    windowFrame.x = focusedScreenFrame.x
    windowFrame.y = focusedScreenFrame.y + heightForPerWindow * (i - 1)
    windowFrame.w = focusedScreenFrame.w
    windowFrame.h = heightForPerWindow
    window:setFrame(windowFrame)
    window:focus()
  end
end

-- 平铺模式 - 垂直均分
function layout_vertical(windows, focusedScreenFrame)
  local windowNum = #windows
  local widthForPerWindow = focusedScreenFrame.w / windowNum
  for i, window in ipairs(windows) do
    local windowFrame = window:frame()
    windowFrame.x = focusedScreenFrame.x + widthForPerWindow * (i - 1)
    windowFrame.y = focusedScreenFrame.y
    windowFrame.w = widthForPerWindow
    windowFrame.h = focusedScreenFrame.h
    window:setFrame(windowFrame)
    window:focus()
  end
end

-- 左半屏
hs.hotkey.bind(windows.left.prefix, windows.left.key, windows.left.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end)

-- 右半屏
hs.hotkey.bind(windows.right.prefix, windows.right.key, windows.right.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 2)
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end)

-- 上半屏
hs.hotkey.bind(windows.up.prefix, windows.up.key, windows.up.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w
  f.h = max.h / 2
  win:setFrame(f)
end)

-- 下半屏
hs.hotkey.bind(windows.down.prefix, windows.down.key, windows.down.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y + (max.h / 2)
  f.w = max.w
  f.h = max.h / 2
  win:setFrame(f)
end)

-- 左上角
if windows.top_left then
  hs.hotkey.bind(windows.top_left.prefix, windows.top_left.key, windows.top_left.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    f.x = max.x
    f.y = max.y
    f.w = max.w / 2
    f.h = max.h / 2
    win:setFrame(f)
  end)
end

-- 右上角
if windows.top_right then
  hs.hotkey.bind(windows.top_right.prefix, windows.top_right.key, windows.top_right.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    f.x = max.x + (max.w / 2)
    f.y = max.y
    f.w = max.w / 2
    f.h = max.h / 2
    win:setFrame(f)
  end)
end

-- 左下角
if windows.left_bottom ~= nil then
  hs.hotkey.bind(windows.left_bottom.prefix, windows.left_bottom.key, windows.left_bottom.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    f.x = max.x
    f.y = max.y + (max.h / 2)
    f.w = max.w / 2
    f.h = max.h / 2
    win:setFrame(f)
  end)
end

-- 右下角
if windows.right_bottom ~= nil then
  hs.hotkey.bind(windows.right_bottom.prefix, windows.right_bottom.key, windows.right_bottom.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    f.x = max.x + (max.w / 2)
    f.y = max.y + (max.h / 2)
    f.w = max.w / 2
    f.h = max.h / 2
    win:setFrame(f)
  end)
end

-- 1/9
if windows.one then
  hs.hotkey.bind(windows.one.prefix, windows.one.key, windows.one.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    f.x = max.x
    f.y = max.y
    f.w = max.w / 3
    f.h = max.h / 3
    win:setFrame(f)
  end)
end

-- 2/9
hs.hotkey.bind(windows.two.prefix, windows.two.key, windows.two.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 3)
  f.y = max.y
  f.w = max.w / 3
  f.h = max.h / 3
  win:setFrame(f)
end)

-- 3/9
hs.hotkey.bind(windows.three.prefix, windows.three.key, windows.three.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 3) * 2
  f.y = max.y
  f.w = max.w / 3
  f.h = max.h / 3
  win:setFrame(f)
end)

-- 4/9
hs.hotkey.bind(windows.four.prefix, windows.four.key, windows.four.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y + (max.h / 3)
  f.w = max.w / 3
  f.h = max.h / 3
  win:setFrame(f)
end)

-- 5/9
hs.hotkey.bind(windows.five.prefix, windows.five.key, windows.five.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 3)
  f.y = max.y + (max.h / 3)
  f.w = max.w / 3
  f.h = max.h / 3
  win:setFrame(f)
end)

-- 6/9
hs.hotkey.bind(windows.six.prefix, windows.six.key, windows.six.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 3) * 2
  f.y = max.y + (max.h / 3)
  f.w = max.w / 3
  f.h = max.h / 3
  win:setFrame(f)
end)

-- 7/9
hs.hotkey.bind(windows.seven.prefix, windows.seven.key, windows.seven.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y + (max.h / 3) * 2
  f.w = max.w / 3
  f.h = max.h / 3
  win:setFrame(f)
end)

-- 8/9
hs.hotkey.bind(windows.eight.prefix, windows.eight.key, windows.eight.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 3)
  f.y = max.y + (max.h / 3) * 2
  f.w = max.w / 3
  f.h = max.h / 3
  win:setFrame(f)
end)

-- 9/9
hs.hotkey.bind(windows.nine.prefix, windows.nine.key, windows.nine.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 3) * 2
  f.y = max.y + (max.h / 3) * 2
  f.w = max.w / 3
  f.h = max.h / 3
  win:setFrame(f)
end)

-- 左 1/3（横屏）或上 1/3（竖屏）
if windows.left_1_3 ~= nil then
  hs.hotkey.bind(windows.left_1_3.prefix, windows.left_1_3.key, windows.left_1_3.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()
    -- 如果为竖屏
    if isVerticalScreen(screen) then
      f.x = max.x
      f.y = max.y
      f.w = max.w
      f.h = max.h / 3
      -- 如果为横屏
    else
      f.x = max.x
      f.y = max.y
      f.w = max.w / 3
      f.h = max.h
    end
    win:setFrame(f)
  end)
end

-- 中 1/3
if windows.middle ~= nil then
  hs.hotkey.bind(windows.middle.prefix, windows.middle.key, windows.middle.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()
    -- 如果为竖屏
    if isVerticalScreen(screen) then
      f.x = max.x
      f.y = max.y + (max.h / 3)
      f.w = max.w
      f.h = max.h / 3
      -- 如果为横屏
    else
      f.x = max.x + (max.w / 3)
      f.y = max.y
      f.w = max.w / 3
      f.h = max.h
    end
    win:setFrame(f)
  end)
end

-- 右 1/3（横屏）或下 1/3（竖屏）
if windows.right_1_3 ~= nil then
  hs.hotkey.bind(windows.right_1_3.prefix, windows.right_1_3.key, windows.right_1_3.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()
    -- 如果为竖屏
    if isVerticalScreen(screen) then
      f.x = max.x
      f.y = max.y + (max.h / 3 * 2)
      f.w = max.w
      f.h = max.h / 3
      -- 如果为横屏
    else
      f.x = max.x + (max.w / 3 * 2)
      f.y = max.y
      f.w = max.w / 3
      f.h = max.h
    end
    win:setFrame(f)
  end)
end

-- 左 2/3（横屏）或上 2/3（竖屏）
if windows.left_2_3 ~= nil then
  hs.hotkey.bind(windows.left_2_3.prefix, windows.left_2_3.key, windows.left_2_3.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()
    -- 如果为竖屏
    if isVerticalScreen(screen) then
      f.x = max.x
      f.y = max.y
      f.w = max.w
      f.h = max.h / 3 * 2
      -- 如果为横屏
    else
      f.x = max.x
      f.y = max.y
      f.w = max.w / 3 * 2
      f.h = max.h
    end
    win:setFrame(f)
  end)
end

-- 右 2/3（横屏）或下 2/3（竖屏）
if windows.right_2_3 ~= nil then
  hs.hotkey.bind(windows.right_2_3.prefix, windows.right_2_3.key, windows.right_2_3.message, function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()
    -- 如果为竖屏
    if isVerticalScreen(screen) then
      f.x = max.x
      f.y = max.y + (max.h / 3)
      f.w = max.w
      f.h = max.h / 3 * 2
      -- 如果为横屏
    else
      f.x = max.x + (max.w / 3)
      f.y = max.y
      f.w = max.w / 3 * 2
      f.h = max.h
    end
    win:setFrame(f)
  end)
end

-- 判断指定屏幕是否为竖屏
function isVerticalScreen(screen)
  if screen:rotate() == 90 or screen:rotate() == 270 then
    return true
  else
    return false
  end
end

-- 居中50% or 全屏
if windows.center_or_fullscreen ~= nil then
  hs.hotkey.bind(
    windows.center_or_fullscreen.prefix,
    windows.center_or_fullscreen.key,
    windows.center_or_fullscreen.message,
    function()
      local win = hs.window.focusedWindow()
      local f = win:frame()
      local screen = win:screen()
      local max = screen:frame()


      if isStageManager() then
        -- for stage mode
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

-- 最大化
--hs.hotkey.bind(windows.max.prefix, windows.max.key, windows.max.message, function()
--local win = hs.window.focusedWindow()
--win:maximize()
--end)

-- 等比例放大窗口
hs.hotkey.bind(windows.zoom.prefix, windows.zoom.key, windows.zoom.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.w = f.w + 40
  f.h = f.h + 40
  f.x = f.x - 20
  f.y = f.y - 20
  if f.x < max.x then
    f.x = max.x
  end
  if f.y < max.y then
    f.y = max.y
  end
  if f.w > max.w then
    f.w = max.w
  end
  if f.h > max.h then
    f.h = max.h
  end
  win:setFrame(f)
end)

-- 等比例缩小窗口
hs.hotkey.bind(windows.narrow.prefix, windows.narrow.key, windows.narrow.message, function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  f.w = f.w - 40
  f.h = f.h - 40
  f.x = f.x + 20
  f.y = f.y + 20
  win:setFrame(f)
end)

-- 将窗口移动到上方屏幕
if windows.to_up ~= nil then
  hs.hotkey.bind(windows.to_up.prefix, windows.to_up.key, windows.to_up.message, function()
    local win = hs.window.focusedWindow()
    if win then
      win:moveOneScreenNorth()
    end
  end)
end

-- 将窗口移动到下方屏幕
if windows.to_down ~= nil then
  hs.hotkey.bind(windows.to_down.prefix, windows.to_down.key, windows.to_down.message, function()
    local win = hs.window.focusedWindow()
    if win then
      win:moveOneScreenSouth()
    end
  end)
end

-- 将窗口移动到左侧屏幕
if windows.to_left ~= nil then
  hs.hotkey.bind(windows.to_left.prefix, windows.to_left.key, windows.to_left.message, function()
    local win = hs.window.focusedWindow()
    if win then
      win:moveOneScreenWest()
    end
  end)
end

-- 将窗口移动到右侧屏幕
if windows.to_right ~= nil then
  hs.hotkey.bind(windows.to_right.prefix, windows.to_right.key, windows.to_right.message, function()
    local win = hs.window.focusedWindow()
    if win then
      win:moveOneScreenEast()
    end
  end)
end

-- 将窗口移动到右侧屏幕
if windows.switchNextScreen ~= nil then
  hs.hotkey.bind(
    windows.switchNextScreen.prefix,
    windows.switchNextScreen.key,
    windows.switchNextScreen.message,
    function()
      -- get the focused window
      local win = hs.window.focusedWindow()
      -- get the screen where the focused window is displayed, a.k.a. current screen
      local screen = win:screen()
      local f = win:frame()
      local max = screen:frame()
      -- compute the unitRect of the focused window relative to the current screen
      -- and move the window to the next screen setting the same unitRect
      local isMax = f.w == max.w and f.h == max.h
      win:move(f:toUnitRect(screen:frame()), screen:next(), true, 0)
      if isMax then
        win:maximize()
      end
      setMousePos()
    end
  )
end
--
-- -- 保存当前激活窗口的边框对象
-- local activeAppBorder = nil
--
-- -- 边框样式设置
-- local borderWidth = 4
-- local borderColor = {["red"]=0, ["green"]=1, ["blue"]=0, ["alpha"]=0.8}
--
-- -- 移除现有的边框
-- local function removeBorder()
--     if activeAppBorder then
--         activeAppBorder:delete()
--         activeAppBorder = nil
--     end
-- end
--
-- -- 给当前激活的窗口添加绿色边框
-- local function addBorderToActiveWindow()
--     -- 移除旧边框
--     removeBorder()
--
--     -- 获取当前激活的窗口
--     local win = hs.window.focusedWindow()
--     if not win then return end
--
--     -- 获取窗口的边界框
--     local frame = win:frame()
--
--     -- 创建一个新的边框
--     activeAppBorder = hs.drawing.rectangle(frame)
--     activeAppBorder:setStrokeColor(borderColor)
--     activeAppBorder:setStrokeWidth(borderWidth)
--     activeAppBorder:setFill(false)
--     activeAppBorder:setLevel(hs.drawing.windowLevels.overlay)
--     activeAppBorder:setRoundedRectRadii(8, 8) -- 圆角矩形（可选）
--     activeAppBorder:show()
-- end
--
-- -- 监听窗口焦点变化
-- hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function()
--     addBorderToActiveWindow()
-- end)
--
-- -- 监听窗口失焦
-- hs.window.filter.default:subscribe(hs.window.filter.windowUnfocused, function()
--     removeBorder()
-- end)
--
-- -- 监听窗口大小或位置变化
-- hs.window.filter.default:subscribe(hs.window.filter.windowMoved, function()
--     addBorderToActiveWindow()
-- end)
--
-- -- 启动时给当前窗口加边框
-- addBorderToActiveWindow()
