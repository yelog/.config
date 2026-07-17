# Neovim 路径搜索优化设计

## 问题

`fzf-lua` 的 `path.filename_first` v1 会把 `moss-gateway/pom.xml` 格式化为“文件名 + 父目录”。fzf 按候选文本中的字符顺序匹配，因此查询 `gateway/pom.xml` 与重排后的文本顺序冲突，返回空结果。

## 设计

使用现有的 Snacks Picker 文件源与 matcher，并通过自定义 formatter 输出“文件名 + 目录”。formatter 将原始路径的匹配位置分别映射到文件名和目录两个可见区域，并动态计入文件图标宽度，因此可以同时满足文件名在左、目录在右、路径查询跨两个区域准确高亮。

曾评估 fzf-lua 的 dirname-first 和 filename-first v2：前者不能保持目标视觉层级，后者依靠隐藏路径匹配而无法将高亮映射到重排后的字段。最终方案不改写查询、不新增依赖，也不改变 Git ignore 或工作目录行为。

## 验证

- 配置回归测试确认文件快捷键使用 Snacks Picker、自定义 formatter，并保留可视选区初始查询。
- 使用与插件等价的候选文本验证 `gateway/pom.xml` 能命中 `moss-gateway/pom.xml`。
- 运行现有 Neovim 配置测试，防止影响其他快捷键和 picker。
