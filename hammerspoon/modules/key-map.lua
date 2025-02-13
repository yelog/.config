_G.hyperKey = { "shift", "alt", "cmd" }
_G.superKey = { "shift", "alt", "cmd", "ctrl" }

-- 重载配置
hs.hotkey.bind(hyperKey, "R", "Reload Configuration", function()
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
  last_application_left_right_layout = { prefix = hyperKey, key = "0", message = "Left and right split screen" },
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

-- 应用切换快捷键配置, 可以通过此命令获取bundleId: osascript -e 'id of app "Apifox"'
_G.applications = {
  { prefix = hyperKey, key = "V", message = "WeChat",        bundleId = "com.tencent.xinWeChat" },
  -- { prefix = hyperKey, key = "N", message = "QQ",            bundleId = "com.tencent.qq" },
  --{prefix = hyperKey, key = "V", message="VSCode", bundleId="com.microsoft.VSCode"},
  { prefix = hyperKey, key = "F", message = "Finder",        bundleId = "com.apple.finder" },
  -- { prefix = hyperKey, key = "B", message = "Browser",        bundleId = "com.google.Chrome" },
  { prefix = hyperKey, key = "B", message = "Browser",       bundleId = "company.thebrowser.Browser" },
  { prefix = hyperKey, key = "I", message = "IntelliJ IDEA", bundleId = "com.jetbrains.intellij" },
  -- {prefix = hyperKey, key = "I", message="IntelliJ IDEA", bundleId="com.jetbrains.intellij-EAP"}, { prefix = hyperKey, key = "I", message = "IntelliJ IDEA", bundleId = "com.todesktop.230313mzl4w4u92" },
  -- { prefix = hyperKey, key = "O", message = "Obsidian",      bundleId = "md.obsidian" },
  { prefix = hyperKey, key = "Y", message = "discord",       bundleId = "com.hnc.Discord" },
  -- {
  --   prefix = hyperKey,
  --   key = "N",
  --   message = "Redis Desktop Manager",
  --   bundleId = "me.qii404.another-redis-desktop-manager",
  -- },
  --{prefix = hyperKey, key = "D", message="DataGrip", bundleId="com.jetbrains.datagrip"},
  { prefix = hyperKey, key = "O", message = "Apifox",   bundleId = "cn.apifox.app" },
  -- { prefix = hyperKey, key = "C", message = "Xcode", bundleId = "com.apple.dt.Xcode" },
  -- { prefix = hyperKey, key = "T", message = "Terminal", bundleId = "org.alacritty" },
  -- { prefix = hyperKey, key = "T", message = "Terminal", bundleId = "com.github.wez.wezterm" },
  { prefix = hyperKey, key = "T", message = "Terminal", bundleId = "net.kovidgoyal.kitty" },
  -- { prefix = hyperKey, key = "T", message = "Terminal", bundleId = "com.mitchellh.ghostty" },
  { prefix = hyperKey, key = "U", message = "Teams",    bundleId = "com.microsoft.teams2" },
  { prefix = hyperKey, key = "M", message = "Mail",     bundleId = "com.apple.mail" },
  { prefix = hyperKey, key = ";", message = "ChatGPT",  bundleId = "com.openai.chat" },
  --{prefix = hyperKey, key = "P", message="Postman", bundleId="com.postmanlabs.mac"},
  --{prefix = hyperKey, key = "O", message="Word", bundleId="com.microsoft.Word"},
  --{prefix = hyperKey, key = "Y", message="PyCharm", bundleId="com.jetbrains.pycharm"},
  --{prefix = hyperKey, key = "R", message="Redis Desktop", bundleId="me.qii404.another-redis-desktop-manager"}
  --> Recent app
  -- { prefix = hyperKey, key = "P", message = "PDF",      bundleId = "net.sourceforge.skim-app.skim" },
  -- { prefix = hyperKey, key = ",", message = "腾讯会议", bundleId = "com.tencent.meeting" },
  -- { prefix = hyperKey, key = ".", message = "zoom会议", bundleId = "us.zoom.xos" },
}

_G.time = {
  currentTime = { prefix = hyperKey, key = "space", message = "Current Time" },
}
