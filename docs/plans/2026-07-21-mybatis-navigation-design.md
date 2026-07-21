# MyBatis 导航设计

## 目标

让 Neovim 能在 Mapper Java 接口和 MyBatis XML 之间进行双向定义、实现与用法导航；`gd`、`gD`、`gu` 优先处理 MyBatis 语义，未命中时保留既有 Snacks/FZF-LSP 行为。

## 决策

采用基于 MyBatis 语义的项目内导航，而不是按文件名匹配或引入外部 MyBatis LSP。

- 身份由 XML `namespace`（Mapper 全限定类名）和 statement `id`（方法名）共同确定。
- 唯一结果直接跳转；多个结果使用 `vim.ui.select` 选择。
- 检索范围限制在最近 Maven Reactor 根目录，兼容多模块工程和任意 XML 资源目录。
- `BaseMapper` 内置方法、注解 SQL 与非 Mapper 上下文不归导航器处理，调用方自动回退到原有 LSP 导航。

## 模块边界

新增 `nvim/lua/custom/mybatis_navigation.lua`，暴露：

- `definition()`：Mapper Java 方法与 XML statement 之间双向跳转。
- `implementation()`：Mapper Java 接口/方法与 XML mapper/statement 之间双向跳转。
- `usages()`：列出 Mapper 方法对应的 XML statement，以及 XML statement 的可识别引用。

每个方法返回布尔值，表示当前光标是否属于已处理的 MyBatis 上下文；调用方仅在 `false` 时执行原有的 Snacks/FZF-LSP 回退。

## 交互与错误处理

- Java -> XML：由当前 Java buffer 的 package、interface 与方法名生成 FQCN，再匹配 XML namespace 和 `id`。
- XML -> Java：解析当前 XML namespace 与 statement id，定位 Java Mapper 文件和方法。
- XML 中的 `<include refid>` 等可静态识别引用纳入 usages 结果。
- 对 MyBatis 上下文但找不到映射的情况，提示精确诊断并视为已处理，避免跳到不相关 LSP 结果。
- 对非 MyBatis 上下文返回 `false`，完全保留现有导航体验。

## 快捷键契约

- `gd`：优先 MyBatis definition，否则现有 `Snacks.picker.lsp_definitions()`。
- `gD`：优先 MyBatis implementation，否则现有 `Snacks.picker.lsp_implementations()`。
- `gu`：优先 MyBatis usages，否则现有 `fzf-lua` usages 及 i18n 特例。

## 验证

使用纯 Lua 单元测试覆盖 FQCN 提取、namespace/statement 匹配、唯一与多结果选择、MyBatis 未找到时不回退、非 MyBatis 时回退，并通过 headless Neovim 验证所有快捷键映射可加载。
