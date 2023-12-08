-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action

-- This table will hold the configuration.
local config = {}


-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 16
-- config.color_scheme = 'Batman'
config.color_scheme = 'Github Dark'
config.enable_tab_bar = false
config.debug_key_events = true
-- https://wezfurlong.org/wezterm/config/lua/config/window_decorations.html?h=decorations
config.window_decorations = "RESIZE"

config.keys = {
  { key = "i", mods = "CMD",        action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
  { key = "n", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
  { key = ";", mods = "CMD|CTRL",   action = "ActivateCopyMode", },
  {
    key = "l",
    mods = "CMD",
    action = wezterm.action.SendKey { key = 'l', mods = 'OPT' },
  },
  {
    key = "m",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendKey { key = 'm', mods = 'OPT|SHIFT' },
  },
  {
    key = "o",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendKey { key = 'o', mods = 'OPT|SHIFT' },
  },
  {
    key = '1',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = '1', mods = 'OPT' },
  },
  {
    key = '2',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = '2', mods = 'OPT' },
  },
  {
    key = '3',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = '3', mods = 'OPT' },
  },
}


-- and finally, return the configuration to wezterm
return config
