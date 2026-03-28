local config = require("config.highlight")
local M = {}

local highlightCanvas = nil
local flashTimer = nil
local fadeOutTimers = {}
local currentWindow = nil

local function createHighlightFrame(win)
  if not win or not win:isStandard() then return nil end

  local f = win:frame()
  local fw = config.frameWidth

  local canvas = hs.canvas.new({
    x = f.x,
    y = f.y,
    w = f.w,
    h = f.h,
  })

  if not canvas then return nil end

  canvas:insertElement({
    type = "rectangle",
    roundedRectRadii = { xRadius = config.cornerRadius, yRadius = config.cornerRadius },
    strokeColor = { red = config.color.red, green = config.color.green, blue = config.color.blue, alpha = 0 },
    strokeWidth = fw,
    fillColor = { alpha = 0 },
    frame = { x = fw / 2, y = fw / 2, w = f.w - fw, h = f.h - fw },
  }, 1)

  canvas:level(hs.canvas.windowLevels.cursor)
  canvas:show()

  return canvas
end

local function fadeIn(canvas)
  local steps = 6
  local stepDuration = config.fadeInDuration / steps
  local targetAlpha = config.color.alpha

  for i = 1, steps do
    hs.timer.doAfter(stepDuration * i, function()
      if canvas and highlightCanvas == canvas then
        canvas:elementAttribute(1, "strokeColor", {
          red = config.color.red,
          green = config.color.green,
          blue = config.color.blue,
          alpha = targetAlpha * (i / steps),
        })
      end
    end)
  end
end

local function clearFadeOutTimers()
  for _, timer in ipairs(fadeOutTimers) do
    timer:stop()
  end
  fadeOutTimers = {}
end

local function fadeOutAndDelete(canvas)
  if not canvas then return end

  clearFadeOutTimers()

  local steps = 4
  local stepDuration = config.fadeOutDuration / steps
  local targetAlpha = config.color.alpha

  for i = 1, steps do
    local timer = hs.timer.doAfter(stepDuration * i, function()
      if canvas then
        canvas:elementAttribute(1, "strokeColor", {
          red = config.color.red,
          green = config.color.green,
          blue = config.color.blue,
          alpha = targetAlpha * (1 - i / steps),
        })
        if i == steps then
          canvas:delete()
          if highlightCanvas == canvas then
            highlightCanvas = nil
            currentWindow = nil
          end
        end
      end
    end)
    table.insert(fadeOutTimers, timer)
  end
end

local function stopFlashTimer()
  if flashTimer then
    flashTimer:stop()
    flashTimer = nil
  end
end

local function startFlashTimer(canvas)
  stopFlashTimer()
  clearFadeOutTimers()
  flashTimer = hs.timer.doAfter(config.flashDuration, function()
    if canvas and highlightCanvas == canvas then
      fadeOutAndDelete(canvas)
    end
    flashTimer = nil
  end)
end

local function removeHighlightImmediately()
  stopFlashTimer()
  clearFadeOutTimers()
  if highlightCanvas then
    highlightCanvas:delete()
    highlightCanvas = nil
    currentWindow = nil
  end
end

local function updateHighlightPosition(canvas, win)
  if not canvas or not win then return end

  local f = win:frame()
  local fw = config.frameWidth
  canvas:frame({ x = f.x, y = f.y, w = f.w, h = f.h })
  canvas:elementAttribute(1, "frame", { x = fw / 2, y = fw / 2, w = f.w - fw, h = f.h - fw })
end

local function isExcludedApp(appName)
  for _, name in ipairs(config.excludedApps) do
    if name == appName then return true end
  end
  return false
end

local function onWindowFocused(win, appName)
  if not config.enabled then return end
  if isExcludedApp(appName) then return end
  if not win or not win:isStandard() then return end

  removeHighlightImmediately()

  currentWindow = win
  highlightCanvas = createHighlightFrame(win)

  if highlightCanvas then
    fadeIn(highlightCanvas)
    startFlashTimer(highlightCanvas)
  end
end

local function onWindowUnfocused(win, appName)
  removeHighlightImmediately()
end

local function onWindowMoved(win, appName)
  if highlightCanvas and currentWindow and win and win:id() == currentWindow:id() then
    updateHighlightPosition(highlightCanvas, win)
  end
end

function M.start()
  local wf = hs.window.filter.default
  wf:subscribe(hs.window.filter.windowFocused, onWindowFocused)
  wf:subscribe(hs.window.filter.windowUnfocused, onWindowUnfocused)
  wf:subscribe(hs.window.filter.windowMoved, onWindowMoved)
end

function M.stop()
  removeHighlightImmediately()
end

function M.toggle()
  config.enabled = not config.enabled
  if config.enabled then
    hs.alert.show("Window Highlight: ON")
    local win = hs.window.focusedWindow()
    if win then
      local app = win:application()
      if app then
        onWindowFocused(win, app:name())
      end
    end
  else
    M.stop()
    hs.alert.show("Window Highlight: OFF")
  end
end

M.start()

return M