local M = {}

M.enabled = true
M.color = { red = 0, green = 0.78, blue = 1, alpha = 0.8 }
M.frameWidth = 3
M.cornerRadius = 6
M.fadeInDuration = 0.08
M.fadeOutDuration = 0.12
M.flashDuration = 0.5

M.excludedApps = {
  "Hammerspoon",
}

return M