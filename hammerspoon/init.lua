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

-- todo 自动判断当前是否开启了 StatgeManager
function _G.isStageManager()
  -- 根据下面代码判断
  local output = hs.execute('/usr/bin/defaults read com.apple.WindowManager GloballyEnabled')
  return string.find(output, '1')
end

local defaultsPath = '/usr/bin/defaults'
local stageManagerDomain = 'com.apple.WindowManager'
local stageEnabledKey = 'GloballyEnabled'

-- 切换 StageManager
function _G.toggleStageManager()
  hs.task.new(
    defaultsPath,
    function(exitCode, stdOut, stdErr)
      hs.task.new(
        defaultsPath,
        nil,
        {
          'write',
          stageManagerDomain,
          stageEnabledKey,
          '-int',
          string.find(stdOut, '0') and '1' or '0'
        }
      ):start()
    end,
    {
      'read',
      stageManagerDomain,
      stageEnabledKey
    }
  ):start()
end
