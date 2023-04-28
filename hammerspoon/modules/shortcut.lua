-- 此文件为示例文件，用户请勿修改，如需自定义快捷键，请修改 shortcut.lua 文件，如不存在 shortcut.lua 文件，则执行命令 cp shortcut.lua.example shortcut.lua 创建一份即可
-- 快捷键配置版本号
shortcut_config = {
    version = 1.0
}
local applicationHyperKey = {'shift', 'alt', 'cmd'}
--local applicationHyperKey = {'shift', 'alt', 'ctrl', 'cmd'}
local windowHyperKey = {'shift', 'alt', 'cmd'}
--local windowHyperKey = {'shift', 'alt', 'ctrl', 'cmd'}


-- prefix：表示快捷键前缀，可选值：Ctrl、Option、Command
-- key：可选值 [A-Z]、[1-9]、Left、Right、Up、Down、-、=、/
-- message 表示提示信息

-- 窗口管理快捷键配置
windows = {
    -- 同一应用的所有窗口自动网格式布局 
    same_application_auto_layout_grid = { prefix = windowHyperKey, key = "0", message = "" },
    -- 同一应用的所有窗口自动水平均分或垂直均分 
    same_space_auto_layout_grid = { prefix = windowHyperKey, key = "0", message = "" },
    -- 同一工作空间下的所有窗口自动网格式布局
    same_application_auto_layout_horizontal_or_vertical = { prefix = windowHyperKey, key = "0", message = "" },
    -- 同一工作空间下的所有窗口自动水平均分或垂直均分 
    same_space_auto_layout_horizontal_or_vertical = { prefix = windowHyperKey, key = "0", message = "" },
    -- 左半屏
    left = {prefix = windowHyperKey, key = "A", message = "Left Half"},
    -- 右半屏
    right = {prefix = windowHyperKey, key = "D", message = "Right Half"},
    -- 上半屏
    up = {prefix = windowHyperKey, key = "W", message = "Up Half"},
    -- 下半屏
    down = {prefix = windowHyperKey, key = "X", message = "Down Half"},
    -- 左上角
    -- top_left = {prefix = windowHyperKey, key = "Q", message = "Top Left"},
    -- 右上角
    -- top_right = {prefix = windowHyperKey, key = "E", message = "Top Right"},
    -- 左下角
    left_bottom = {prefix = windowHyperKey, key = "Z", message = "Left Bottom"},
    -- 右下角
    right_bottom = {prefix = windowHyperKey, key = "C", message = "Right Bottom"},
    -- 1/9
    -- one = {prefix = windowHyperKey, key = "1", message = "1/9"},
    -- 2/9
    two = {prefix = windowHyperKey, key = "2", message = "2/9"},
    -- 3/9
    three = {prefix = windowHyperKey, key = "3", message = "3/9"},
    -- 4/9
    four = {prefix = windowHyperKey, key = "4", message = "4/9"},
    -- 5/9
    five = {prefix = windowHyperKey, key = "5", message = "5/9"},
    -- 6/9
    six = {prefix = windowHyperKey, key = "6", message = "6/9"},
    -- 7/9
    seven = {prefix = windowHyperKey, key = "7", message = "7/9"},
    -- 8/9
    eight = {prefix = windowHyperKey, key = "8", message = "8/9"},
    -- 9/9
    nine = {prefix = windowHyperKey, key = "9", message = "9/9"},
    -- 左 1/3（横屏）或上 1/3（竖屏）
    left_1_3 = {prefix = windowHyperKey, key = "0", message = "Left 1/3(Horizontal screen) Or Top 1/3(Vertical screen)"},
    -- 中 1/3
    middle = {prefix = windowHyperKey, key = "0", message = "Middle 1/3"},
    -- 右 1/3（横屏）或下 1/3（竖屏）
    right_1_3 = {prefix = windowHyperKey, key = "0", message = "Right 1/3(Horizontal screen)Or Bottom 1/3(Vertical screen)"},
    -- 左 2/3（横屏）或上 2/3（竖屏）
    left_2_3 = {prefix = windowHyperKey, key = "0", message = "Left 2/3(Horizontal screen) Or Top 2/3(Vertical screen)"},
    -- 右 2/3（横屏）或下 2/3（竖屏）
    right_2_3 = {prefix = windowHyperKey, key = "0", message = "Right 2/3(Horizontal screen)Or Bottom 2/3(Vertical screen)"},
    -- 居中50% 或 全屏
    center_or_fullscreen = {prefix = windowHyperKey, key = "S", message = "Center Or FullScreen"},
    -- 等比例放大窗口
    zoom = {prefix = windowHyperKey, key = "=", message = "Zoom Window"},
    -- 等比例缩小窗口
    narrow = {prefix = windowHyperKey, key = "-", message = "Narrow Window"},
    -- 将窗口移动到下一个屏幕
    switchNextScreen = {prefix = windowHyperKey, key = "Return", message = "Next Screen"},
    -- 将窗口移动到上方屏幕
    to_up = {prefix = {"Ctrl", "Option", "Command"}, key = "Up", message = "Move To Up Screen"},
    -- 将窗口移动到下方屏幕
    to_down = {prefix = {"Ctrl", "Option", "Command"}, key = "Down", message = "Move To Down Screen"},
    -- 将窗口移动到左侧屏幕
    to_left = {prefix = {"Ctrl", "Option", "Command"}, key = "Left", message = "Move To Left Screen"},
    -- 将窗口移动到右侧屏幕
    to_right = {prefix = {"Ctrl", "Option", "Command"}, key = "Right", message = "Move To Right Screen"}
}

-- 应用切换快捷键配置, 获取 bundleId: osascript -e 'id of app "Apifox"'
applications = {
    {prefix = applicationHyperKey, key = "Q", message="QQ", bundleId="com.tencent.qq"},
    {prefix = applicationHyperKey, key = "V", message="WeChat", bundleId="com.tencent.xinWeChat"},
    --{prefix = applicationHyperKey, key = "V", message="VSCode", bundleId="com.microsoft.VSCode"},
    {prefix = applicationHyperKey, key = "F", message="Finder", bundleId="com.apple.finder"},
    {prefix = applicationHyperKey, key = "B", message="Chrome", bundleId="com.google.Chrome"},
    {prefix = applicationHyperKey, key = "I", message="IntelliJ IDEA", bundleId="com.jetbrains.intellij"},
    {prefix = applicationHyperKey, key = "O", message="Obsidian", bundleId="md.obsidian"},
    --{prefix = applicationHyperKey, key = "N", message="WizNote", bundleId="cn.wiznote.desktop"},
    --{prefix = applicationHyperKey, key = "D", message="DataGrip", bundleId="com.jetbrains.datagrip"},
    {prefix = applicationHyperKey, key = "Z", message="Apifox", bundleId="cn.apifox.app"},
    {prefix = applicationHyperKey, key = "C", message="Calendar", bundleId="com.apple.iCal"},
    {prefix = applicationHyperKey, key = "T", message="Terminal", bundleId="org.alacritty"},
    {prefix = applicationHyperKey, key = "U", message="Teams", bundleId="com.microsoft.teams"},
    {prefix = applicationHyperKey, key = "M", message="Mail", bundleId="com.apple.mail"},
    --{prefix = applicationHyperKey, key = "P", message="Postman", bundleId="com.postmanlabs.mac"},
    --{prefix = applicationHyperKey, key = "O", message="Word", bundleId="com.microsoft.Word"},
    --{prefix = applicationHyperKey, key = "Y", message="PyCharm", bundleId="com.jetbrains.pycharm"},
    --{prefix = applicationHyperKey, key = "R", message="Redis Desktop", bundleId="me.qii404.another-redis-desktop-manager"}
    --> Recent app
    {prefix = applicationHyperKey, key = "1", message="PDF", bundleId="net.sourceforge.skim-app.skim"}
}

-- 输入法切换快捷键配置
input_methods = {
    abc = {prefix = {"Option"}, key = "J", message="ABC"},
    chinese = {prefix = {"Option"}, key = "K", message="简体拼音"}, 
    japanese = {prefix = {"Option"}, key = "L", message="Hiragana"}
}

-- 表情包搜索快捷键配置
emoji_search = {
    prefix = {
        "Option"
    },
    key = "E"
}

-- 密码粘贴快捷键配置
password_paste = {
    prefix = {
        "Ctrl", "Command"
    },
    key = "V", 
    message = "Password Paste"
}

-- 快捷键查看面板快捷键配置
hotkey = {
    prefix = applicationHyperKey,
    key = "/"
}
