-- 应用切换

require("modules.shortcut")

hs.fnutils.each(applications, function(item)
  hs.hotkey.bind(item.prefix, item.key, item.message, function()
    -- toggleAppByBundleId(item.bundleId)
    -- switchApp(item.bundleId)
    activateApp(item.bundleId)
  end)
end)
local cacheWins
local cacheApp
function activateApp(bundleID)
  print(bundleID)
  local app = hs.application.get(bundleID)
  local appWindows = (app == nil) and {} or app:allWindows()
  if cacheWins == nil or #cacheWins ~= #appWindows or app ~= cacheApp then
    print('refresh cache')
    cacheWins = appWindows
    cacheApp = app
  end
  print('length ' .. #appWindows)
  -- local appWindowNumber = (bundleID == "com.apple.finder") and (#appWindows - 1) or #appWindows
  -- print("窗口数量", appWindowNumber)
  if app == nil then                -- 应用未启动
    hs.application.launchOrFocusByBundleID(bundleID)
  elseif not app:isFrontmost() then -- 应用未激活
    hs.application.launchOrFocusByBundleID(bundleID)
    -- app:activate()
  else -- 应用已激活
    if #appWindows == 0 then
      -- 应用激活时, 通过 cmd-w 关掉最后一个窗口时, 当前应用仍是激活状态, 所以需要启动
      hs.application.launchOrFocusByBundleID(bundleID)
    else
      local focusedWin = hs.window.focusedWindow()
      local activeIndex = 1
      for i, win in ipairs(cacheWins) do
        if win:id() == focusedWin:id() then
          activeIndex = i
        end
      end
      print('currentIndex ' .. activeIndex)
      if activeIndex == #cacheWins then
        activeIndex = 1
      else
        activeIndex = activeIndex + 1
      end
      print('nextIndex ' .. activeIndex)
      -- 不能通过下标获取, 所以再循环一遍
      for i, win in ipairs(cacheWins) do
        if activeIndex == i then
          win:focus()
        end
      end
    end
  end
  local currentScreen = getCurrentScreen()
  if currentScreen then
    -- 可以优化为设置在屏幕中间
    hs.mouse.setRelativePosition({ x = 40, y = 40 }, currentScreen)
  end
end

-- 获取当前鼠标所在的屏幕
function getCurrentScreen()
  local win = hs.window.focusedWindow()
  if win then
    return win:screen()
  else
    return nil
  end
end
