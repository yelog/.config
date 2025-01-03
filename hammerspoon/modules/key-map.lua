local supperKey = { "shift", "alt", "cmd" }

-- 重载配置
hs.hotkey.bind(supperKey, "R", "Reload Configuration", function()
  hs.reload()
end)
-- Toggle Stage Manager
hs.hotkey.bind(supperKey, ".", "Toggle Stage Manager", function()
  toggleStageManager()
end)

-- 窗口管理快捷键配置
_G.windows = {
  -- 同一应用的所有窗口自动网格式布局
  -- same_application_auto_layout_grid = { prefix = supperKey, key = "9", message = "" },
  -- 同一应用的所有窗口自动水平均分或垂直均分
  -- same_space_auto_layout_grid = { prefix = supperKey, key = "9", message = "" },
  -- 同一工作空间下的所有窗口自动水平均分或垂直均分
  -- same_space_auto_layout_horizontal_or_vertical = { prefix = supperKey, key = "9", message = "" },
  -- 左半屏
  left = { prefix = supperKey, key = "A", message = "Left Half" },
  -- 右半屏
  right = { prefix = supperKey, key = "D", message = "Right Half" },
  -- 上半屏
  up = { prefix = supperKey, key = "W", message = "Up Half" },
  -- 下半屏
  down = { prefix = supperKey, key = "X", message = "Down Half" },
  -- 左上角
  top_left = { prefix = supperKey, key = "Q", message = "Top Left" },
  -- 右上角
  top_right = { prefix = supperKey, key = "E", message = "Top Right" },
  -- 左下角
  left_bottom = { prefix = supperKey, key = "Z", message = "Left Bottom" },
  -- 右下角
  right_bottom = { prefix = supperKey, key = "C", message = "Right Bottom" },
  -- 跟上一个应用进行左右分屏
  last_application_left_right_layout = { prefix = supperKey, key = "0", message = "Left and right split screen" },
  -- 1/9
  one = { prefix = supperKey, key = "1", message = "1/9" },
  -- 2/9
  two = { prefix = supperKey, key = "2", message = "2/9" },
  -- 3/9
  three = { prefix = supperKey, key = "3", message = "3/9" },
  -- 4/9
  four = { prefix = supperKey, key = "4", message = "4/9" },
  -- 5/9
  five = { prefix = supperKey, key = "5", message = "5/9" },
  -- 6/9
  six = { prefix = supperKey, key = "6", message = "6/9" },
  -- 7/9
  seven = { prefix = supperKey, key = "7", message = "7/9" },
  -- 8/9
  eight = { prefix = supperKey, key = "8", message = "8/9" },
  -- 9/9
  nine = { prefix = supperKey, key = "9", message = "9/9" },
  -- 左 1/3（横屏）或上 1/3（竖屏）
  -- left_1_3 = {
  --   prefix = supperKey,
  --   key = "9",
  --   message = "Left 1/3(Horizontal screen) Or Top 1/3(Vertical screen)",
  -- },
  -- 中 1/3
  -- middle = { prefix = supperKey, key = "9", message = "Middle 1/3" },
  -- 右 1/3（横屏）或下 1/3（竖屏）
  -- right_1_3 = {
  --   prefix = supperKey,
  --   key = "9",
  --   message = "Right 1/3(Horizontal screen)Or Bottom 1/3(Vertical screen)",
  -- },
  -- 左 2/3（横屏）或上 2/3（竖屏）
  -- left_2_3 = {
  --   prefix = supperKey,
  --   key = "9",
  --   message = "Left 2/3(Horizontal screen) Or Top 2/3(Vertical screen)",
  -- },
  -- 右 2/3（横屏）或下 2/3（竖屏）
  -- right_2_3 = {
  --   prefix = supperKey,
  --   key = "9",
  --   message = "Right 2/3(Horizontal screen)Or Bottom 2/3(Vertical screen)",
  -- },
  -- 居中50% 或 全屏
  center_or_fullscreen = { prefix = supperKey, key = "S", message = "Center Or FullScreen" },
  -- 等比例放大窗口
  zoom = { prefix = supperKey, key = "=", message = "Zoom Window" },
  -- 等比例缩小窗口
  narrow = { prefix = supperKey, key = "-", message = "Narrow Window" },
  -- 将窗口移动到下一个屏幕
  switchNextScreen = { prefix = supperKey, key = "Return", message = "Next Screen" },
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
  { prefix = supperKey, key = "V", message = "WeChat",        bundleId = "com.tencent.xinWeChat" },
  { prefix = supperKey, key = "N", message = "QQ",            bundleId = "com.tencent.qq" },
  --{prefix = supperKey, key = "V", message="VSCode", bundleId="com.microsoft.VSCode"},
  { prefix = supperKey, key = "F", message = "Finder",        bundleId = "com.apple.finder" },
  -- { prefix = supperKey, key = "B", message = "Browser",        bundleId = "com.google.Chrome" },
  { prefix = supperKey, key = "B", message = "Browser",       bundleId = "company.thebrowser.Browser" },
  { prefix = supperKey, key = "I", message = "IntelliJ IDEA", bundleId = "com.jetbrains.intellij" },
  -- {prefix = supperKey, key = "I", message="IntelliJ IDEA", bundleId="com.jetbrains.intellij-EAP"}, { prefix = supperKey, key = "I", message = "IntelliJ IDEA", bundleId = "com.todesktop.230313mzl4w4u92" },
  -- { prefix = supperKey, key = "O", message = "Obsidian",      bundleId = "md.obsidian" },
  { prefix = supperKey, key = "Y", message = "discord",       bundleId = "com.hnc.Discord" },
  {
    prefix = supperKey,
    key = "N",
    message = "Redis Desktop Manager",
    bundleId = "me.qii404.another-redis-desktop-manager",
  },
  --{prefix = supperKey, key = "D", message="DataGrip", bundleId="com.jetbrains.datagrip"},
  { prefix = supperKey, key = "O", message = "Apifox",   bundleId = "cn.apifox.app" },
  -- { prefix = supperKey, key = "C", message = "Xcode", bundleId = "com.apple.dt.Xcode" },
  -- { prefix = supperKey, key = "T", message = "Terminal", bundleId = "org.alacritty" },
  -- { prefix = supperKey, key = "T", message = "Terminal", bundleId = "com.github.wez.wezterm" },
  { prefix = supperKey, key = "T", message = "Terminal", bundleId = "net.kovidgoyal.kitty" },
  -- { prefix = supperKey, key = "T", message = "Terminal", bundleId = "com.mitchellh.ghostty" },
  { prefix = supperKey, key = "U", message = "Teams",    bundleId = "com.microsoft.teams2" },
  { prefix = supperKey, key = "M", message = "Mail",     bundleId = "com.apple.mail" },
  { prefix = supperKey, key = ";", message = "ChatGPT",  bundleId = "com.openai.chat" },
  --{prefix = supperKey, key = "P", message="Postman", bundleId="com.postmanlabs.mac"},
  --{prefix = supperKey, key = "O", message="Word", bundleId="com.microsoft.Word"},
  --{prefix = supperKey, key = "Y", message="PyCharm", bundleId="com.jetbrains.pycharm"},
  --{prefix = supperKey, key = "R", message="Redis Desktop", bundleId="me.qii404.another-redis-desktop-manager"}
  --> Recent app
  { prefix = supperKey, key = "P", message = "PDF",      bundleId = "net.sourceforge.skim-app.skim" },
  -- { prefix = supperKey, key = ",", message = "腾讯会议", bundleId = "com.tencent.meeting" },
  -- { prefix = supperKey, key = ".", message = "zoom会议", bundleId = "us.zoom.xos" },
}
