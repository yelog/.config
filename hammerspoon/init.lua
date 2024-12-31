require("modules.app")
require("modules.window")

-- 获取当前激活窗口所在的屏幕
function getCurrentScreen()
  local win = hs.window.focusedWindow()
  if win then
    return win:screen()
  else
    return nil
  end
end

-- 设置鼠标到当前激活窗口所在的屏幕
function _G.setMousePos()
  local currentScreen = getCurrentScreen()
  if currentScreen then
    -- 可以优化为设置在屏幕中间
    hs.mouse.setRelativePosition({ x = 40, y = 40 }, currentScreen)
  end
end
