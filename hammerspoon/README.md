# hammerspoon 配置

主要分为两个方面, 窗口和应用快捷键, 分为四个文件
1. `init.lua` 加载其他模块
2. `modules/key-map.lua` 定义快捷键
3. `modules/window.lua` 窗口操作逻辑
4. `modules/app.lua` 应用操作逻辑

快捷键修改和在 `./modules/key-map.lua`

> 如下 `supperKey` 默认为 `cmd+shift+alt`, 同样可以在 `key-map.lua` 中修改, 并且如果需要更多快捷键, 推荐窗口和应用使用不同的 `supperKey`

> 我的 `supperKey + hjkl` 通过 `Karabiner-Elements` 全局改为方向键了, 所以没有在如下使用, 如果没有占用, 可以绑定其他常用的应用

- 应用快捷键
    * `supperKey + V` 打开 `WeChat`
    * `supperKey + Q` 打开 `QQ`
    * `supperKey + F` 打开 `Finder`
    * `supperKey + I` 打开 `IntelliJ IDEA`
    * `supperKey + Y` 打开 `Discord`
    * `supperKey + T` 打开 `Terminal`
    * `supperKey + O` 打开 `Apifox`
    * `supperKey + U` 打开 `Teams`
    * `supperKey + M` 打开 `Mail`
    * `supperKey + ;` 打开 `ChatGPT`
    * `supperKey + P` 打开 `PDF`
- 窗口快捷键
    * `supperKey + A` 当前窗口左半屏
    * `supperKey + D` 当前窗口右半屏
    * `supperKey + W` 当前窗口上半屏
    * `supperKey + X` 当前窗口下半屏
    * `supperKey + S` 当前窗口居中/全屏
    * `supperKey + Q` 当前窗口左上角
    * `supperKey + E` 当前窗口右上角
    * `supperKey + Z` 当前窗口左下角
    * `supperKey + C` 当前窗口右下角
    * `supperKey + 1` 当前窗口9宫格1
    * `supperKey + 2` 当前窗口9宫格2
    * `supperKey + 3` 当前窗口9宫格3
    * `supperKey + 4` 当前窗口9宫格4
    * `supperKey + 5` 当前窗口9宫格5
    * `supperKey + 6` 当前窗口9宫格6
    * `supperKey + 7` 当前窗口9宫格7
    * `supperKey + 8` 当前窗口9宫格8
    * `supperKey + 9` 当前窗口9宫格9
    * `supperKey + 0` 当前窗口和上一个窗口左右分屏/交换位置
    * `supperKey + =` 当前窗口等比例放大
    * `supperKey + -` 当前窗口等比例缩小
    * `supperKey + Enter` 将当前窗口移动到下一个显示屏(鼠标也会跟随)


# 致谢

- https://github.com/KURANADO2/hammerspoon-kuranado

