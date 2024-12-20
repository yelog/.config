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
-- "ExtraLight"
-- "Light"
-- "DemiLight"
-- "Book"
-- "Regular"
-- "Medium"
-- "DemiBold"
-- "Bold"
-- "ExtraBold"
-- "Black"
-- "ExtraBlack".
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

-- config.macos_window_background_blur = 40
-- config.window_background_opacity = 0.9
-- 设置背景图
config.window_background_image = "/Users/yelog/Documents/image/Genshin Impact/官方宣传图系列壁纸/璃月概念组图/南天门-1920x1080.png"
config.window_background_image_hsb = {
  -- 可以设置图像的透明度、亮度等属性
  brightness = 0.05, -- 调整亮度
  saturation = 1,    -- 饱和度
  hue = 1.0,         -- 色调
}

-- config.color_scheme = 'Batman'
config.color_scheme = 'Tokyo Night'

----------------------------- Set Tab start -----------------------------
-- config.enable_tab_bar = false
config.use_fancy_tab_bar = false
config.debug_key_events = true
-- set tab to bottom
config.tab_bar_at_bottom = true
config.tab_max_width = 60
config.switch_to_last_active_tab_when_closing_tab = true

local function get_current_working_dir(tab)
  local current_dir = tab.active_pane and tab.active_pane.current_working_dir or { file_path = '' }
  local HOME_DIR = string.format('file://%s', os.getenv('HOME'))

  return current_dir == HOME_DIR and '.'
      or string.gsub(current_dir.file_path, '(.*[/\\])(.*)', '%2')
end

-- Set tab title to the one that was set via `tab:set_title()`
-- or fall back to the current working directory as a title
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local index = tonumber(tab.tab_index) + 1
  local custom_title = tab.tab_title
  local title = get_current_working_dir(tab)

  if custom_title and #custom_title > 0 then
    title = custom_title
  end

  return string.format('  %s•%s  ', index, title)
end)
----------------------------- Set Tab End -----------------------------

-- https://wezfurlong.org/wezterm/config/lua/config/window_decorations.html?h=decorations
config.window_decorations = "RESIZE"
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

-- config.enable_kitty_keyboard = true
-- config.enable_csi_u_key_encoding = false

config.adjust_window_size_when_changing_font_size = false
config.skip_close_confirmation_for_processes_named = { 'bash', 'sh', 'zsh', 'fish', 'tmux' }
config.keys = {
  {
    key = 'Enter',
    mods = 'CMD',
    action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
  },
  {
    key = 'h',
    mods = 'CMD|CTRL',
    action = act.ActivatePaneDirection('Prev'),
  },
  -- { key = "i", mods = "CMD",        action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
  -- { key = "n", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
  {
    key = "Enter",
    mods = "OPT",
    action = wezterm.action.SendKey { key = 'Enter', mods = 'OPT' },
  },
  {
    key = "Enter",
    mods = "OPT|SHIFT",
    action = wezterm.action.SendKey { key = 'Enter', mods = 'OPT|SHIFT' },
  },
  -- Case-insensitive search
  {
    key = 'f',
    mods = 'CMD',
    action = act.Search({ CaseInSensitiveString = '' }),
  },
  {
    key = "l",
    mods = "CMD",
    action = wezterm.action.SendKey { key = 'l', mods = 'OPT' },
  },
  {
    key = "RightArrow",
    mods = "CMD",
    action = wezterm.action.SendKey {
      key = "RightArrow",
      mods = "OPT"
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
    action = wezterm.action.SendKey { key = 'z', mods = 'OPT' },
  },
  {
    key = 'k',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SendKey { key = 'z', mods = 'OPT|SHIFT' },
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
  { key = ';', mods = "CMD|CTRL", action = "ActivateCopyMode", },
  {
    key = 'n',
    mods = 'CMD|CTRL',
    action = wezterm.action.SendKey { key = 'n', mods = 'OPT|SHIFT' },
  },
  {
    key = 'p',
    mods = 'CMD|CTRL',
    action = wezterm.action.SendKey { key = 'p', mods = 'OPT|SHIFT' },
  },
  {
    key = 'h',
    mods = 'CMD|CTRL',
    action = wezterm.action.SendKey { key = 'h', mods = 'OPT' },
  },
  {
    key = 'j',
    mods = 'CMD|CTRL',
    action = wezterm.action.SendKey { key = 'j', mods = 'OPT' },
  },
  {
    key = 'k',
    mods = 'CMD|CTRL',
    action = wezterm.action.SendKey { key = 'k', mods = 'OPT' },
  },
  {
    key = 'l',
    mods = 'CMD|CTRL',
    action = wezterm.action.SendKey { key = 'l', mods = 'OPT' },
  },
  {
    key = 'r',
    mods = 'CMD|CTRL',
    action = wezterm.action.SendKey { key = 'r', mods = 'OPT|SHIFT' },
  },
  {
    key = '1',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTab(0)
  },
  {
    key = '2',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTab(1)
  },
  {
    key = '3',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTab(2)
  },
  {
    key = '4',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTab(3)
  },
  {
    key = '5',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTab(4)
  },
  {
    key = '6',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTab(5)
  },
  {
    key = '7',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTab(6)
  },
  {
    key = '8',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTab(7)
  },
  {
    key = '9',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTab(8)
  },
  {
    key = 'n',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTabRelative(1)
  },
  {
    key = 'p',
    mods = "CMD|CTRL",
    action = wezterm.action.ActivateTabRelative(-1)
  },
}


-- and finally, return the configuration to wezterm
return config
