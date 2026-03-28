local M = {}

M.enabled = true

M.primaryColor = { red = 0, green = 0.78, blue = 1, alpha = 0.9 }
M.glowColor = { red = 0, green = 0.78, blue = 1, alpha = 0.2 }

M.primaryWidth = 4
M.glowWidth = 12
M.cornerRadius = 8

M.fadeInDuration = 0.1
M.stableDuration = 0.25
M.fadeOutDuration = 0.15

M.breathingMinAlpha = 0.7
M.breathingMaxAlpha = 1.0

M.excludedApps = {
  "Hammerspoon",
}

return M