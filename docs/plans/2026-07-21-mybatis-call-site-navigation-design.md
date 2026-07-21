# MyBatis 调用点导航设计

## 问题

现有导航器仅在当前 buffer 本身是 Mapper Java 或 Mapper XML 时处理 MyBatis 语义。Service 等调用点执行 `gD` 时会回退到 jdtls，因而只能跳到 Mapper Java 接口声明，不能跳到 XML statement。

## 决策

在任意 Java 调用点，优先向已附加的 LSP 请求 definition，使用返回的 Java Mapper 方法位置读取真实的 Mapper FQCN 和方法名；当该接口满足 MyBatis Mapper 规则时，以 `namespace + id` 跳转 XML。

## 原因

通过 jdtls 解析类型比文本推断更准确，支持字段/构造器/局部变量注入、跨模块引用和 `ServiceImpl<SysDeptMapper, ...>` 中 `baseMapper` 的泛型类型；不会把 Java 文本解析器扩展成不可靠的类型系统。

## 行为

- `gD` 在 Java 调用点请求 LSP definition。
- 返回位置属于 MyBatis Mapper 方法且存在 XML statement：直接跳转或多结果选择。
- definition 不属于 Mapper 或没有 XML statement：返回 `false`，调用方保持现有 Snacks implementation 回退。
- 原有 Mapper Java/XML 双向导航行为不变。

## 验证

用真实项目的 `sysDeptMapper.queryAllChildrenId(entity.getDeptId())` 和 `baseMapper.queryAllChildrenId(entity.getId())` 验证；另外覆盖 LSP 未附加、未返回 definition、非 Mapper definition 和缺失 XML 的安全回退。
