-- 应用切换

require("modules.shortcut")

hs.fnutils.each(applications, function(item)
  hs.hotkey.bind(item.prefix, item.key, item.message, function()
    -- toggleAppByBundleId(item.bundleId)
    -- switchApp(item.bundleId)
    activateApp(item.bundleId)
  end)
end)

function activateApp(bundleID)
  local app = hs.application.get(bundleID)
  local appWindows = (app == nil) and {} or app:allWindows()
  -- local appWindowNumber = (bundleID == "com.apple.finder") and (#appWindows - 1) or #appWindows
  -- print("窗口数量", appWindowNumber)
  if app == nil then -- 应用未启动
    hs.application.launchOrFocusByBundleID(bundleID)
  elseif not app:isFrontmost() then -- 应用未激活
    hs.application.launchOrFocusByBundleID(bundleID)
    -- app:activate()
  else -- 应用已激活
    if #appWindows == 0 then
      -- 应用激活时, 通过 cmd-w 关掉最后一个窗口时, 当前应用仍是激活状态, 所以需要启动
      hs.application.launchOrFocusByBundleID(bundleID)
    else
      hs.eventtap.keyStroke({ "cmd" }, "`") -- 模拟按下 cmd+`
    end
  end
end

