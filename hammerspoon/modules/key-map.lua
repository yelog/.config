_G.hyperKey = { "shift", "alt", "cmd" }
_G.superKey = { "shift", "alt", "cmd", "ctrl" }

-- 重载配置
hs.hotkey.bind(superKey, "R", "Reload Configuration", function()
  hs.reload()
  hs.notify.new({ title = "Hammerspoon", informativeText = "Configuration Reload" }):send()
end)
-- Toggle Stage Manager
hs.hotkey.bind(hyperKey, ".", "Toggle Stage Manager", function()
  toggleStageManager()
end)

-- 窗口管理快捷键配置
_G.windows = {
  -- 同一应用的所有窗口自动网格式布局
  -- same_application_auto_layout_grid = { prefix = hyperKey, key = "9", message = "" },
  -- 同一应用的所有窗口自动水平均分或垂直均分
  -- same_space_auto_layout_grid = { prefix = hyperKey, key = "9", message = "" },
  -- 同一工作空间下的所有窗口自动水平均分或垂直均分
  -- same_space_auto_layout_horizontal_or_vertical = { prefix = hyperKey, key = "9", message = "" },
  -- 左半屏
  left = { prefix = hyperKey, key = "A", message = "Left Half" },
  -- 右半屏
  right = { prefix = hyperKey, key = "D", message = "Right Half" },
  -- 上半屏
  up = { prefix = hyperKey, key = "W", message = "Up Half" },
  -- 下半屏
  down = { prefix = hyperKey, key = "X", message = "Down Half" },
  -- 左上角
  top_left = { prefix = hyperKey, key = "Q", message = "Top Left" },
  -- 右上角
  top_right = { prefix = hyperKey, key = "E", message = "Top Right" },
  -- 左下角
  left_bottom = { prefix = hyperKey, key = "Z", message = "Left Bottom" },
  -- 右下角
  right_bottom = { prefix = hyperKey, key = "C", message = "Right Bottom" },
  -- 跟上一个应用进行左右分屏
  last_application_left_right_layout = { prefix = hyperKey, key = "\\", message = "Left and right split screen" },
  -- 跟上一个应用进行上下分屏
  last_application_up_down_layout = { prefix = hyperKey, key = "/", message = "Up and down split screen" },
  -- 1/9
  one = { prefix = hyperKey, key = "1", message = "1/9" },
  -- 2/9
  two = { prefix = hyperKey, key = "2", message = "2/9" },
  -- 3/9
  three = { prefix = hyperKey, key = "3", message = "3/9" },
  -- 4/9
  four = { prefix = hyperKey, key = "4", message = "4/9" },
  -- 5/9
  five = { prefix = hyperKey, key = "5", message = "5/9" },
  -- 6/9
  six = { prefix = hyperKey, key = "6", message = "6/9" },
  -- 7/9
  seven = { prefix = hyperKey, key = "7", message = "7/9" },
  -- 8/9
  eight = { prefix = hyperKey, key = "8", message = "8/9" },
  -- 9/9
  nine = { prefix = hyperKey, key = "9", message = "9/9" },
  -- 左 1/3（横屏）或上 1/3（竖屏）
  -- left_1_3 = {
  --   prefix = hyperKey,
  --   key = "9",
  --   message = "Left 1/3(Horizontal screen) Or Top 1/3(Vertical screen)",
  -- },
  -- 中 1/3
  -- middle = { prefix = hyperKey, key = "9", message = "Middle 1/3" },
  -- 右 1/3（横屏）或下 1/3（竖屏）
  -- right_1_3 = {
  --   prefix = hyperKey,
  --   key = "9",
  --   message = "Right 1/3(Horizontal screen)Or Bottom 1/3(Vertical screen)",
  -- },
  -- 左 2/3（横屏）或上 2/3（竖屏）
  -- left_2_3 = {
  --   prefix = hyperKey,
  --   key = "9",
  --   message = "Left 2/3(Horizontal screen) Or Top 2/3(Vertical screen)",
  -- },
  -- 右 2/3（横屏）或下 2/3（竖屏）
  -- right_2_3 = {
  --   prefix = hyperKey,
  --   key = "9",
  --   message = "Right 2/3(Horizontal screen)Or Bottom 2/3(Vertical screen)",
  -- },
  -- 居中50% 或 全屏
  center_or_fullscreen = { prefix = hyperKey, key = "S", message = "Center Or FullScreen" },
  -- 等比例放大窗口
  zoom = { prefix = hyperKey, key = "=", message = "Zoom Window" },
  -- 等比例缩小窗口
  narrow = { prefix = hyperKey, key = "-", message = "Narrow Window" },
  -- 将窗口移动到下一个屏幕
  switchNextScreen = { prefix = hyperKey, key = "Return", message = "Next Screen" },
  -- 将窗口移动到上方屏幕
  -- to_up = { prefix = { "Ctrl", "Option", "Command" }, key = "Up", message = "Move To Up Screen" },
  -- 将窗口移动到下方屏幕
  -- to_down = { prefix = { "Ctrl", "Option", "Command" }, key = "Down", message = "Move To Down Screen" },
  -- 将窗口移动到左侧屏幕
  -- to_left = { prefix = { "Ctrl", "Option", "Command" }, key = "Left", message = "Move To Left Screen" },
  -- 将窗口移动到右侧屏幕
  -- to_right = { prefix = { "Ctrl", "Option", "Command" }, key = "Right", message = "Move To Right Screen" },
}

-- 应用切换快捷键配置
_G.applications = {
  { prefix = hyperKey, key = "V", message = "WeChat",        appName = "WeChat" },
  { prefix = hyperKey, key = "G", message = "QQ",             appName = "QQ" },
  --{prefix = hyperKey, key = "V", message="VSCode", appName="Visual Studio Code"},
  { prefix = hyperKey, key = "F", message = "Finder",         appName = "Finder" },
  -- { prefix = hyperKey, key = "B", message = "Browser",        appName = "Google Chrome" },
  { prefix = hyperKey, key = "B", message = "Browser",        appName = "Arc" },
  -- { prefix = hyperKey, key = "B", message = "Browser",        appName = "Browser" },
  { prefix = hyperKey, key = "I", message = "IntelliJ IDEA",  appName = "IntelliJ IDEA" },
  -- {prefix = hyperKey, key = "I", message="IntelliJ IDEA", appName="IntelliJ IDEA-EAP"}, { prefix = hyperKey, key = "I", message = "IntelliJ IDEA", appName = "com.todesktop.230313mzl4w4u92" },
  -- { prefix = hyperKey, key = "O", message = "Obsidian",       appName = "Obsidian" },
  { prefix = hyperKey, key = "Y", message = "Discord",        appName = "Discord" },
  {
    prefix = hyperKey,
    key = "R",
    message = "Redis Desktop Manager",
    appName = "Another Redis Desktop Manager",
  },
  --{prefix = hyperKey, key = "D", message="DataGrip", appName="DataGrip"},
  { prefix = hyperKey, key = "O", message = "Apifox", appName = "Apifox" },
  -- { prefix = hyperKey, key = "C", message = "Xcode", appName = "Xcode" },
  -- { prefix = hyperKey, key = "T", message = "Terminal", appName = "Alacritty" },
  -- { prefix = hyperKey, key = "T", message = "Terminal", appName = "WezTerm" },
  { prefix = hyperKey, key = "T", message = "Terminal", appName = "kitty" },
  -- { prefix = hyperKey, key = "T", message = "Terminal", appName = "Ghostty" },
  { prefix = hyperKey, key = "U", message = "Teams", appName = "Microsoft Teams" },
  -- { prefix = hyperKey, key = "M", message = "Mail",           appName = "Mail" },
  { prefix = hyperKey, key = "M", message = "Mail", appName = "Microsoft Outlook" },
  { prefix = hyperKey, key = ";", message = "ChatGPT", appName = "ChatGPT" },
  -- { prefix = hyperKey, key = ";", message = "Claude",   appName = "Claude" },
  -- { prefix = hyperKey, key = ";", message = "Ollama",   appName = "Ollama" },
  -- { prefix = hyperKey, key = ";", message = "ChatGPT",        appName = "com.tencent.yuanbao" },
  -- { prefix = hyperKey, key = ";", message = "Browser",        appName = "Google Chrome" },
  -- { prefix = hyperKey, key = "P", message = "iPhone Mirroring", appName = "iPhone Mirroring" },
  --{prefix = hyperKey, key = "O", message="Word", appName="Microsoft Word"},
  --{prefix = hyperKey, key = "Y", message="PyCharm", appName="PyCharm"},
  --{prefix = hyperKey, key = "R", message="Redis Desktop", appName="Another Redis Desktop Manager"}
  --> Recent app
  -- { prefix = hyperKey, key = "P", message = "PDF",       appName = "Skim" },
  -- { prefix = hyperKey, key = ",", message = "腾讯会议", appName = "腾讯会议" },
  { prefix = hyperKey, key = "N", message = "XCode", appName = "Xcode" },
  -- { prefix = hyperKey, key = ".", message = "zoom会议", appName = "zoom.us" },
  { prefix = hyperKey, key = ",", message = "Codex", appName = "Codex" },
}

_G.time = {
  currentTime = { prefix = hyperKey, key = "space", message = "Current Time" },
}
