local keys = require("config.keys")

local M = {}

M.left = { prefix = keys.hyper, key = "A", message = "Left Half" }
M.right = { prefix = keys.hyper, key = "D", message = "Right Half" }
M.up = { prefix = keys.hyper, key = "W", message = "Up Half" }
M.down = { prefix = keys.hyper, key = "X", message = "Down Half" }

M.top_left = { prefix = keys.hyper, key = "Q", message = "Top Left" }
M.top_right = { prefix = keys.hyper, key = "E", message = "Top Right" }
M.left_bottom = { prefix = keys.hyper, key = "Z", message = "Left Bottom" }
M.right_bottom = { prefix = keys.hyper, key = "C", message = "Right Bottom" }

M.last_application_left_right_layout = { prefix = keys.hyper, key = "\\", message = "Left and right split screen" }
M.last_application_up_down_layout = { prefix = keys.hyper, key = "/", message = "Up and down split screen" }
M.split_boundary_shrink = { prefix = keys.hyper, key = "[", message = "Shrink split boundary" }
M.split_boundary_expand = { prefix = keys.hyper, key = "]", message = "Expand split boundary" }

M.one = { prefix = keys.hyper, key = "1", message = "1/9" }
M.two = { prefix = keys.hyper, key = "2", message = "2/9" }
M.three = { prefix = keys.hyper, key = "3", message = "3/9" }
M.four = { prefix = keys.hyper, key = "4", message = "4/9" }
M.five = { prefix = keys.hyper, key = "5", message = "5/9" }
M.six = { prefix = keys.hyper, key = "6", message = "6/9" }
M.seven = { prefix = keys.hyper, key = "7", message = "7/9" }
M.eight = { prefix = keys.hyper, key = "8", message = "8/9" }
M.nine = { prefix = keys.hyper, key = "9", message = "9/9" }

M.center_or_fullscreen = { prefix = keys.hyper, key = "S", message = "Center Or FullScreen" }
M.zoom = { prefix = keys.hyper, key = "=", message = "Zoom Window" }
M.narrow = { prefix = keys.hyper, key = "-", message = "Narrow Window" }
M.switchNextScreen = { prefix = keys.hyper, key = "Return", message = "Next Screen" }

M.same_application_auto_layout_grid = nil
M.same_space_auto_layout_grid = nil
M.same_space_auto_layout_horizontal_or_vertical = nil

return M