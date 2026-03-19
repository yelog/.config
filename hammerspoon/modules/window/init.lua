local M = {}

M.lastWindow = nil
M.previousWindow = nil

hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function(window)
  if M.lastWindow and M.lastWindow ~= window then
    M.previousWindow = M.lastWindow
  end
  M.lastWindow = window
end)

return M