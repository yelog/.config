# Task Workflow Implementation Plan

**Goal:** 在 OpenCode V2 中一键执行 Astra 分析与计划、Luna 实施与合并。

**Architecture:** 本地插件注册 task、task-status、task-resume 命令。使用同一会话保留上下文，插件持久化阶段并检查阶段产物，在 worktree 阶段移动会话目录。

**Tech Stack:** OpenCode V2.0.3 Plugin API、TypeScript、Git。

## Tasks
1. 核对真实模型 ID、插件类型及会话 API。
2. 实现串行阶段、完成回执、目录定位、持久化和恢复。
3. 实现 Git 起点、worktree 和合并结果检查。
4. 运行类型检查与插件加载检查，编写中文使用文档。
