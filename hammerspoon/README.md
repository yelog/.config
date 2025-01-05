# hammerspoon 配置

这套窗口管理的操作逻辑指哪打哪, 一个快捷键到达目的地, 就可以进行摸鱼、记笔记、执行命令、写代码等

主要分为两个方面, 窗口和应用快捷键, 分为四个文件
1. `init.lua` 加载其他模块
2. `modules/key-map.lua` 定义快捷键
3. `modules/window.lua` 窗口操作逻辑
4. `modules/app.lua` 应用操作逻辑

快捷键修改和在 `./modules/key-map.lua`

> 如下 `hyperKey` 默认为 `cmd+shift+alt`, 同样可以在 `key-map.lua` 中修改, 并且如果需要更多快捷键, 推荐窗口和应用使用不同的 `hyperKey`

> 我的 hyperKey 是通过 `Karabiner-Elements` 将 `Caps` 的长按改为 `cmd+shift+alt`, 所以如下的所有的组合键都是两个按键的组合, 如果感兴趣, 可以查看当前仓库下的 `Karabiner-Elements` 配置 `../karabiner/assets/complex_modifications/yelog.json`

> 我的 `hyperKey + hjkl` 通过 `Karabiner-Elements` 全局改为方向键了, 所以没有在如下使用, 如果没有占用, 可以绑定其他常用的应用

- 应用快捷键
    * `hyperKey + V` 打开 `WeChat`
    * `hyperKey + Q` 打开 `QQ`
    * `hyperKey + F` 打开 `Finder`
    * `hyperKey + I` 打开 `IntelliJ IDEA`
    * `hyperKey + Y` 打开 `Discord`
    * `hyperKey + T` 打开 `Terminal`
    * `hyperKey + O` 打开 `Apifox`
    * `hyperKey + U` 打开 `Teams`
    * `hyperKey + M` 打开 `Mail`
    * `hyperKey + ;` 打开 `ChatGPT`
    * `hyperKey + P` 打开 `PDF`
- 窗口快捷键
    * `hyperKey + A` 当前窗口左半屏
    * `hyperKey + D` 当前窗口右半屏
    * `hyperKey + W` 当前窗口上半屏
    * `hyperKey + X` 当前窗口下半屏
    * `hyperKey + S` 当前窗口居中/全屏
    * `hyperKey + Q` 当前窗口左上角
    * `hyperKey + E` 当前窗口右上角
    * `hyperKey + Z` 当前窗口左下角
    * `hyperKey + C` 当前窗口右下角
    * `hyperKey + 1` 当前窗口9宫格1
    * `hyperKey + 2` 当前窗口9宫格2
    * `hyperKey + 3` 当前窗口9宫格3
    * `hyperKey + 4` 当前窗口9宫格4
    * `hyperKey + 5` 当前窗口9宫格5
    * `hyperKey + 6` 当前窗口9宫格6
    * `hyperKey + 7` 当前窗口9宫格7
    * `hyperKey + 8` 当前窗口9宫格8
    * `hyperKey + 9` 当前窗口9宫格9
    * `hyperKey + 0` 当前窗口和上一个窗口左右分屏/交换位置
    * `hyperKey + =` 当前窗口等比例放大
    * `hyperKey + -` 当前窗口等比例缩小
    * `hyperKey + Enter` 将当前窗口移动到下一个显示屏(鼠标也会跟随)


# 致谢

- [KURANADO2/hammerspoon-kuranado](https://github.com/KURANADO2/hammerspoon-kuranado)

