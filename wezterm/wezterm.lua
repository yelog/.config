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
-- Example: This is 中文 平安 将来
-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'
-- config.font = wezterm.font 'JetBrains Mono'
-- config.font = wezterm.font 'JetBrainsMono Nerd Font'
-- config.font = wezterm.font_with_fallback { 'Menlo' }
-- config.font = wezterm.font_with_fallback { 'JetBrainsMono Nerd Font', 'Menlo' }
-- config.font = wezterm.font_with_fallback { 'Fira Code'}
-- config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Regular' })
-- config.font = wezterm.font 'Noto Mono'
-- config.font = wezterm.font_with_fallback {
--         "JetBrainsMono Nerd Font",
--         "FiraCode Nerd Font",
--
--         -- To avoid 'Chinese characters displayed as variant (Japanese) glyphs'
--         "Source Han Sans SC",
--         "Source Han Sans TC"
--       }

config.font = wezterm.font_with_fallback({
  { family = 'JetBrainsMono Nerd Font', weight = 'Regular', italic = false },
  { family = 'Source Han Sans HW SC',   weight = 'Regular', italic = false },
})

-- config.font_rules = {
--   {
--     intensity = 'Bold',
--     italic = false,
--     font = wezterm.font {
--       family = 'Lantinghei SC',
--       weight = 'Bold',
--     },
--   }
-- }

config.font_size = 16
config.line_height = 0.9

-- config.window_background_opacity = 0.9

-- config.color_scheme = 'Batman'
config.color_scheme = 'Github Dark'
config.enable_tab_bar = false
config.debug_key_events = true
-- https://wezfurlong.org/wezterm/config/lua/config/window_decorations.html?h=decorations
config.window_decorations = "RESIZE"
config.window_padding = {
  left = 2,
  right = 2,
  top = 2,
  bottom = 2,
}

config.keys = {
  { key = "i", mods = "CMD",        action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
  { key = "n", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
  { key = ";", mods = "CMD|CTRL",   action = "ActivateCopyMode", },
  { key = "1", mods = "CMD|CTRL",   action = wezterm.action.SendKey { key = '5', mods = 'OPT' } },
  { key = "1", mods = "CTRL",       action = wezterm.action.SendKey { key = '1', mods = 'CTRL' } },
  {
    key = "l",
    mods = "CMD",
    action = wezterm.action.SendKey { key = 'l', mods = 'OPT' },
  },
  -- {
  --   key = "k",
  --   mods = "CMD",
  --   action = wezterm.action.SendKey { key = 'k', mods = 'OPT' },
  -- },
  {
    key = "RightArrow",
    mods = "CMD",
    action = wezterm.action.SendKey {
      key = "RightArrow",
      mods = "ALT"
    },
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
    key = "f",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendKey { key = 'f', mods = 'OPT|SHIFT' },
  },
  {
    key = "r",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendKey { key = 'r', mods = 'OPT|SHIFT' },
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
  {
    key = 'e',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'e', mods = 'OPT' },
  },
  {
    key = 'h',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'h', mods = 'OPT' },
  },
  {
    key = 'j',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'j', mods = 'OPT' },
  },
  {
    key = 'k',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'K', mods = 'OPT' },
  },
  {
    key = 'l',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'L', mods = 'OPT' },
  },
  {
    key = 'p',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'p', mods = 'OPT' },
  },
  {
    key = 's',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 's', mods = 'OPT' },
  },
  {
    key = 'y',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'y', mods = 'OPT' },
  },
  {
    key = '/',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = '/', mods = 'OPT' },
  },
}


-- and finally, return the configuration to wezterm
return config
