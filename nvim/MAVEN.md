# Maven Dashboard

此配置使用 `oclay1st/maven.nvim` 提供 Maven 看板，并增加多模块 Reactor、项目级 Profile、参数和命令预设支持。

## 前提

- 安装 Maven，并确保 `mvn` 在 `PATH` 中。
- 在 Maven 项目的文件或目录中执行命令；看板会向上定位包含 `pom.xml`、`mvnw` 或 `.git` 的项目根。
- 插件浏览需要 `unzip`。依赖与插件分析会调用 Maven，并可能下载 Maven 插件或读取本地仓库。

## 快捷键

| 快捷键 | 功能 |
| --- | --- |
| `<leader>om` | 打开或关闭 Maven 项目看板 |
| `<leader>op` | 选择当前项目的 Maven Profile，可用 `Tab` 多选 |
| `<leader>ox` | 打开任意 Maven 命令执行窗口 |
| `<leader>of` | 搜索并运行收藏的 Maven 命令 |
| `<leader>oD` | 打开当前 Maven 项目的独立依赖分析器 |

## 用户命令

| 命令 | 功能 |
| --- | --- |
| `:Maven` | 打开或关闭项目看板 |
| `:MavenProfiles` | 选择 Maven Profile |
| `:MavenProfilesClear` | 清除当前项目的 Maven Profile |
| `:MavenExec` | 打开 Maven 命令执行窗口 |
| `:MavenFavorites` | 打开收藏命令窗口 |
| `:MavenInit` | 创建 Maven Archetype 项目 |
| `:MavenDependencies` | 分析当前 Maven 项目的完整依赖图 |
| `:MavenPresetAdd <名称> <Maven 参数...>` | 保存当前项目的命令预设 |
| `:MavenPresetRemove <名称>` | 删除当前项目的命令预设 |

例如：

```vim
:MavenPresetAdd verify-fast verify -DskipTests
:MavenPresetAdd package-local clean package -DskipTests
```

预设名称及参数按空格拆分，因此包含空格的参数值不适合通过该命令创建。保存后重新打开看板，在项目的 `Commands` 节点执行。

## 项目看板操作

在 `:Maven` 的项目树中：

| 按键 | 功能 |
| --- | --- |
| `Enter` | 展开或收起节点；在 lifecycle、命令和 plugin goal 上执行 |
| `a` | 分析当前项目的依赖关系 |
| `Ctrl-r` | 强制重新加载当前项目的依赖或插件 |
| `e` | 打开任意 Maven 命令执行窗口 |
| `f` | 打开当前项目或全部项目的收藏命令 |
| `F` | 收藏或取消收藏当前 lifecycle、预设或 plugin goal |
| `g` | 管理默认 Maven 参数 |
| `c` | 打开 Archetype 项目初始化向导 |
| `?` | 打开看板内帮助 |
| `q` / `Esc` | 关闭当前窗口 |

项目树会根据 POM 的 `<modules>` 重建层级。重复模块声明不会重复显示，循环声明会保留为顶层项目。

对有子模块的聚合项目执行 lifecycle，例如 `compile`、`test` 或 `install`，会执行完整 Maven Reactor。叶子模块仍保持非递归执行。

## Profile

Profile 选择保存在 `stdpath("state")/maven/profiles.json`，以规范化后的项目根目录隔离。选择 `dev` 和 `uat` 后，Maven 命令会收到：

```text
-Pdev,uat
```

服务面板与 Maven 看板使用同一份 Profile 选择。Spring Boot 服务只能接收一个 Profile，因此多选时使用排序后的第一个，例如 `dev,uat` 使用 `dev`。在服务面板重新选择 Profile 会将 Maven 选择改为该单一 Profile。

## 默认参数与预设

按 `g` 打开默认参数窗口，使用 `Enter` 或空格启用、禁用参数。退出参数窗口或切换项目目录时，用户设置会按项目保存；自动生成的 `-P...` 参数不会作为用户参数保存。

命令预设也保存到同一个状态文件。它们仅影响当前项目，并通过上游 Maven Console 执行，因此会自动带上当前 Profile 和启用的默认参数。

## 依赖、插件和输出

项目树中的 `a` 保留上游的简版依赖分析：左侧显示已解析依赖，右侧显示选中依赖的传递路径。冲突版本会标记为警告；可用 `/` 或 `s` 过滤，`on` 按名称排序，`os` 按 jar 大小排序，`i` 查看依赖详情。

## 独立依赖分析器

使用 `<leader>oD` 或 `:MavenDependencies` 打开当前 POM 的完整依赖分析器。它复用 Maven 的已解析依赖图、缓存与 Console 输出，不会只读取 `pom.xml` 中的直接依赖。

| 按键 | 功能 |
| --- | --- |
| `t` | 完整传递依赖树，保留搜索命中节点的父级路径 |
| `l` | 去重后的依赖列表，按 `groupId:artifactId` 聚合 |
| `c` | 只显示 Maven 标记为版本冲突的依赖 |
| `/` | 搜索 groupId、artifactId、版本或 scope |
| `T` | 隐藏或显示 `test` scope 及其子树 |
| `S` | 显示或隐藏本地 JAR 大小 |
| `r` | 强制重新执行 Maven 依赖解析，跳过缓存 |
| `p` | 显示当前坐标的全部传递引用路径 |
| `i` | 显示当前依赖的坐标、scope、大小、冲突与重复状态 |
| `Enter` | 在树模式展开或收起节点 |
| `q` / `Esc` | 关闭分析器 |

冲突行显示 Maven 实际采用的版本，以及被冲突调解排除的版本。JAR 大小取自本地 Maven 仓库；尚未下载的构件显示为 `-`。

展开 `Plugins` 可以从 Effective POM 查看插件；再展开插件可运行其 goals。依赖、插件和 Maven `--help` 参数会缓存。依赖或插件节点使用 `Ctrl-r` 可强制刷新。

所有看板命令经 Maven Console 串行执行，成功、警告和失败输出带高亮。自由命令窗口按空格切分参数，复杂引号或包含空格的参数建议在命令行或预设中避免使用。

依赖分析默认显示 Maven Console。若 `Dependencies` 节点加载失败，请查看其中 Maven 的完整错误；常见原因包括私服或 Central 访问被拒绝、父 POM 无法下载、未配置代理或镜像，以及项目本身的 POM 解析错误。
