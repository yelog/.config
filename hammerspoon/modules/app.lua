local helper = require("utils.helper")
local apps = require("config.apps")

local M = {}

local bundleIdCache = {}

local function resolveBundleId(appName)
  if bundleIdCache[appName] then
    return bundleIdCache[appName]
  end
  local output = hs.execute("osascript -e 'id of app \"" .. appName .. "\"' 2>/dev/null")
  if output and output ~= "" then
    local bundleId = output:gsub("%s+$", "")
    bundleIdCache[appName] = bundleId
    return bundleId
  end
  return nil
end

local cacheWins
local cacheApp

local function activateApp(bundleID)
  local app = hs.application.get(bundleID)
  local appWindows = (app == nil) and {} or app:allWindows()
  if cacheWins == nil or #cacheWins ~= #appWindows or app ~= cacheApp then
    cacheWins = appWindows
    cacheApp = app
  end

  if app == nil then
    hs.application.launchOrFocusByBundleID(bundleID)
  elseif not app:isFrontmost() then
    hs.application.launchOrFocusByBundleID(bundleID)
  else
    if #appWindows == 0 then
      hs.application.launchOrFocusByBundleID(bundleID)
    else
      local focusedWin = hs.window.focusedWindow()
      local activeIndex = 1
      if focusedWin then
        for i, win in ipairs(cacheWins) do
          if win:id() == focusedWin:id() then
            activeIndex = i
          end
        end
      end
      if activeIndex == #cacheWins then
        activeIndex = 1
      else
        activeIndex = activeIndex + 1
      end
      for i, win in ipairs(cacheWins) do
        if activeIndex == i then
          win:focus()
        end
      end
    end
  end
  helper.setMousePos()
end

hs.fnutils.each(apps, function(item)
  local bundleId = resolveBundleId(item.appName)
  if not bundleId then
    hs.printf("[app.lua] Warning: Cannot find bundleId for app '%s'", item.appName)
    return
  end
  hs.hotkey.bind(item.prefix, item.key, item.message, function()
    activateApp(bundleId)
  end)
end)

return M