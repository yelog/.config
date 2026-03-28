local config = require("config.highlight")
local M = {}

local highlightCanvas = nil
local allTimers = {}
local currentWindow = nil
local currentPrimaryAlpha = 0
local currentGlowAlpha = 0
local breathingDirection = 1

local GLOW_INDEX = 1
local PRIMARY_INDEX = 2

local function stopAllTimers()
  for _, timer in ipairs(allTimers) do
    if timer then
      timer:stop()
    end
  end
  allTimers = {}
end

local function addTimer(timer)
  table.insert(allTimers, timer)
  return timer
end

local function createHighlightCanvas(win)
  if not win or not win:isStandard() then return nil end

  local f = win:frame()
  local canvas = hs.canvas.new({
    x = f.x,
    y = f.y,
    w = f.w,
    h = f.h,
  })

  if not canvas then return nil end

  local pw = config.primaryWidth
  local gw = config.glowWidth

  canvas:insertElement({
    type = "rectangle",
    roundedRectRadii = { xRadius = config.cornerRadius, yRadius = config.cornerRadius },
    strokeColor = { red = config.glowColor.red, green = config.glowColor.green, blue = config.glowColor.blue, alpha = 0 },
    strokeWidth = gw,
    fillColor = { alpha = 0 },
    frame = { x = gw / 2, y = gw / 2, w = f.w - gw, h = f.h - gw },
  }, GLOW_INDEX)

  canvas:insertElement({
    type = "rectangle",
    roundedRectRadii = { xRadius = config.cornerRadius, yRadius = config.cornerRadius },
    strokeColor = { red = config.primaryColor.red, green = config.primaryColor.green, blue = config.primaryColor.blue, alpha = 0 },
    strokeWidth = pw,
    fillColor = { alpha = 0 },
    frame = { x = pw / 2, y = pw / 2, w = f.w - pw, h = f.h - pw },
  }, PRIMARY_INDEX)

  canvas:level(hs.canvas.windowLevels.cursor)
  canvas:show()

  currentPrimaryAlpha = 0
  currentGlowAlpha = 0

  return canvas
end

local function fadeIn(canvas)
  local steps = 8
  local stepDuration = config.fadeInDuration / steps
  local targetPrimaryAlpha = config.primaryColor.alpha
  local targetGlowAlpha = config.glowColor.alpha

  for i = 1, steps do
    addTimer(hs.timer.doAfter(stepDuration * i, function()
      if canvas and highlightCanvas == canvas then
        local progress = i / steps
        currentPrimaryAlpha = targetPrimaryAlpha * progress
        currentGlowAlpha = targetGlowAlpha * progress

        canvas:elementAttribute(PRIMARY_INDEX, "strokeColor", {
          red = config.primaryColor.red,
          green = config.primaryColor.green,
          blue = config.primaryColor.blue,
          alpha = currentPrimaryAlpha,
        })

        canvas:elementAttribute(GLOW_INDEX, "strokeColor", {
          red = config.glowColor.red,
          green = config.glowColor.green,
          blue = config.glowColor.blue,
          alpha = currentGlowAlpha,
        })
      end
    end))
  end
end

local function startBreathing(canvas)
  local period = 0.08
  breathingDirection = 1

  addTimer(hs.timer.doWhile(function()
    return canvas and highlightCanvas == canvas
  end, function()
    if not canvas or highlightCanvas ~= canvas then return end

    local step = (config.breathingMaxAlpha - config.breathingMinAlpha) * 0.15
    currentPrimaryAlpha = currentPrimaryAlpha + step * breathingDirection

    if currentPrimaryAlpha >= config.breathingMaxAlpha then
      breathingDirection = -1
      currentPrimaryAlpha = config.breathingMaxAlpha
    elseif currentPrimaryAlpha <= config.breathingMinAlpha then
      breathingDirection = 1
      currentPrimaryAlpha = config.breathingMinAlpha
    end

    currentGlowAlpha = currentPrimaryAlpha * (config.glowColor.alpha / config.primaryColor.alpha)

    canvas:elementAttribute(PRIMARY_INDEX, "strokeColor", {
      red = config.primaryColor.red,
      green = config.primaryColor.green,
      blue = config.primaryColor.blue,
      alpha = currentPrimaryAlpha,
    })

    canvas:elementAttribute(GLOW_INDEX, "strokeColor", {
      red = config.glowColor.red,
      green = config.glowColor.green,
      blue = config.glowColor.blue,
      alpha = currentGlowAlpha,
    })
  end, period))
end

local function fadeOut(canvas)
  if not canvas then return end

  local steps = 6
  local stepDuration = config.fadeOutDuration / steps
  local startPrimaryAlpha = currentPrimaryAlpha
  local startGlowAlpha = currentGlowAlpha

  for i = 1, steps do
    addTimer(hs.timer.doAfter(stepDuration * i, function()
      if canvas then
        local progress = i / steps
        local primaryAlpha = startPrimaryAlpha * (1 - progress)
        local glowAlpha = startGlowAlpha * (1 - progress)

        canvas:elementAttribute(PRIMARY_INDEX, "strokeColor", {
          red = config.primaryColor.red,
          green = config.primaryColor.green,
          blue = config.primaryColor.blue,
          alpha = primaryAlpha,
        })

        canvas:elementAttribute(GLOW_INDEX, "strokeColor", {
          red = config.glowColor.red,
          green = config.glowColor.green,
          blue = config.glowColor.blue,
          alpha = glowAlpha,
        })

        if i == steps then
          canvas:delete()
          if highlightCanvas == canvas then
            highlightCanvas = nil
            currentWindow = nil
          end
        end
      end
    end))
  end
end

local function removeHighlightImmediately()
  stopAllTimers()
  if highlightCanvas then
    highlightCanvas:delete()
    highlightCanvas = nil
    currentWindow = nil
  end
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
  highlightCanvas = createHighlightCanvas(win)

  if highlightCanvas then
    fadeIn(highlightCanvas)
    addTimer(hs.timer.doAfter(config.fadeInDuration, function()
      if highlightCanvas then
        startBreathing(highlightCanvas)
      end
    end))
    addTimer(hs.timer.doAfter(config.fadeInDuration + config.stableDuration, function()
      if highlightCanvas then
        fadeOut(highlightCanvas)
      end
    end))
  end
end

local function onWindowUnfocused(win, appName)
  removeHighlightImmediately()
end

local function onWindowMoved(win, appName)
  if highlightCanvas and currentWindow and win and win:id() == currentWindow:id() then
    local f = win:frame()
    local pw = config.primaryWidth
    local gw = config.glowWidth

    highlightCanvas:frame({ x = f.x, y = f.y, w = f.w, h = f.h })

    highlightCanvas:elementAttribute(GLOW_INDEX, "frame", {
      x = gw / 2,
      y = gw / 2,
      w = f.w - gw,
      h = f.h - gw,
    })

    highlightCanvas:elementAttribute(PRIMARY_INDEX, "frame", {
      x = pw / 2,
      y = pw / 2,
      w = f.w - pw,
      h = f.h - pw,
    })
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