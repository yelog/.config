local M = {}

function M.isVerticalScreen(screen)
  if screen:rotate() == 90 or screen:rotate() == 270 then
    return true
  else
    return false
  end
end

function M.getCurrentScreen()
  local win = hs.window.focusedWindow()
  if win then
    return win:screen()
  else
    return nil
  end
end

function M.setMousePos()
  local currentScreen = M.getCurrentScreen()
  if currentScreen then
    hs.mouse.setRelativePosition({ x = 40, y = 40 }, currentScreen)
  end
end

function M.isStageManager()
  local output = hs.execute('/usr/bin/defaults read com.apple.WindowManager GloballyEnabled')
  return string.find(output, '1')
end

function M.toggleStageManager()
  local defaultsPath = '/usr/bin/defaults'
  local stageManagerDomain = 'com.apple.WindowManager'
  local stageEnabledKey = 'GloballyEnabled'

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

return M