# Astra → Luna 自动开发工作流

## 安装位置

- 插件：`~/.config/opencode-v2/plugins/task-workflow/index.ts`
- 启用配置：`~/.config/opencode-v2/opencode.json` 的 `plugins`
- 模型：Astra = `xrouter/gpt-6-astra`，Luna = `xrouter/gpt-5.6-luna`
- 当前适配：OpenCode V2.0.3

这是 opencode2 的全局插件，可以在不同 Git 项目中使用。新任务默认集中放在主 checkout 旁的 `<仓库名>-worktree/<任务名称>`，例如 `../my-api-worktree/add-cache`、`../lazydb-worktree/add-cache`。仓库名取自 Git 主 checkout，即使从已有 worktree 启动，也使用同一个默认父目录。

## 项目级配置（可选）

在启动 checkout 根目录创建 `.opencode/task-workflow.json`（严格 JSON，不含注释）：

```json
{
  "prefix": "my-api",
  "parent": "../my-api-worktree",
  "planDirectory": "docs/plans",
  "models": {
    "astra": { "providerID": "xrouter", "id": "gpt-6-astra" },
    "luna": { "providerID": "xrouter", "id": "gpt-5.6-luna" }
  }
}
```

所有字段均可省略。prefix 默认主 checkout 目录名，仅用于构造默认父目录 `<prefix>-worktree`；任务子目录不再重复此前缀。parent 默认主 checkout 旁的 `<prefix>-worktree`，显式设置时覆盖默认父目录；相对路径从启动 checkout 根目录解析，也支持绝对路径。planDirectory 默认 `docs/plans`，必须是仓库内相对路径。模型可以只覆盖一个角色，但该角色需要完整 providerID 和 id。astra/luna 是阶段角色名称，允许替换成其他可用模型。

配置及目录布局只在 `/task` 启动时读取，随后保存到任务状态。修改项目配置不会改变已有任务的模型、目录和计划路径；旧版配置快照继续使用 `<prefix>-<任务名称>` 布局，没有配置快照的旧任务仍按原 lazydb 前缀恢复。现有 worktree 不搬迁。已有项目若显式设置 parent，新任务仍尊重该父目录，但子目录改为任务名称。

从已有 worktree 启动时，以该 checkout 为起点，并合并回它启动时的分支；不会自动切换到主 checkout。请从你希望最终接收合并的 checkout 启动。项目仍需要 Git、可用的模型及 writing-plans/git-commit Skills。非 Git 目录不支持。

## 开始使用

1. 退出并重新启动 opencode2，让新进程加载插件。
2. 在 `/Users/yelog/workspace/tui/lazydb` 打开一个新会话。
3. 检查主工作空间当前分支：它就是最终合并目标，不会强制切到 main。
4. 输入：

```text
/task 优化 Redis 上下文帮助
```

命令后面的全部文本都是需求，无需提供任务名称。Astra 完成计划后，Luna 根据会话上下文、需求和完整计划生成英文名称。插件检查本地分支、目录（包括符号链接）及 Git worktree 登记；重名时自动尝试 `-2`、`-3` 等后缀，并通过独占创建目录和 Git 分支创建再次防止并发冲突。一个会话承载一个任务；新任务使用新会话。

插件自动执行：

| 阶段 | 模型 | 行为 |
| --- | --- | --- |
| analyze | Astra | 分析现有实现、根因、方案取舍，写 analysis.md |
| plan | Astra | 调用 writing-plans，写完整 plan.md |
| implement | Luna | 创建 worktree、移动会话、逐项实施及复核、写 implementation.md |
| integrate | Luna | 验证、调用 git-commit、提交、合并、写 integration.md |

例如 Luna 生成 `redis-context-help`，会创建分支 `task/redis-context-help`，目录 `/Users/yelog/workspace/tui/lazydb-worktree/redis-context-help`；若重名则使用可用后缀。起点是启动任务时工作空间的 HEAD。实际名称会显示在会话和 `/task-status` 中。

计划会复制到新 worktree 的 `docs/plans/redis-context-help.md`，随任务提交。合并和验证通过后，会话先返回原工作空间，插件再执行 `git worktree remove` 和 `git branch -d`，删除本任务的 worktree 及分支。不会自动 push。公共父目录与 Git common directory 下的任务报告保留。

清理前核对目标分支、合并提交、任务 worktree 分支与 HEAD，以及未提交/未跟踪文件。不会使用强制删除；正常 Git worktree 删除也会移除该目录内被忽略的构建产物。若清理失败，任务停在清理阶段，处理原因后 `/task-resume` 只重试清理，不再调用模型重复实施或合并。已标记 done 的历史任务不会被批量清理；新版下继续执行的未完成任务会使用自动清理。

## 查看进度

```text
/task-status
```

显示当前阶段、状态、分支、worktree、报告目录和阻塞原因。模型和工具的实际执行过程仍显示在当前会话中。

## 暂停与继续

使用 OpenCode 当前配置的停止操作中断模型。缺少阶段完成回执、模型失败或中断都会让流程停在当前阶段。

处理问题或补充需求后，在原会话输入：

```text
/task-resume
```

恢复会重新执行当前未完成阶段，已完成阶段不会从头运行。实施阶段会检查已有 worktree 并继续使用它。若关闭或重启 OpenCode，也应重新打开原会话后运行此命令。

任务仍在执行时 resume 会拒绝重复启动。不要在多个 opencode2 进程中同时恢复同一个会话。

## 状态和报告

数据保存在 Git common directory 下：

```text
<git-common-dir>/opencode-tasks/<session-id>/
  state.json
  analysis.md
  plan.md
  implementation.md
  integration.md
  <stage>-<token>.json
```

正常主工作空间中就是 `.git/opencode-tasks/<session-id>/`。使用 `/task-status` 获取本任务准确路径。

阶段推进要求模型写入带本轮 token 的完成回执、对应报告非空，且会话未失败或中断。合并阶段额外检查任务 HEAD 已进入目标分支及任务 worktree 干净。验证结果内容由模型执行并报告，插件不会独立重跑任意项目的测试命令。

## 常见情况

- **自动命名**：Luna 使用独立文本请求，输入需求、分析及完整计划，避免会话内的执行指令干扰命名。接受纯 slug、JSON 和代码块等包装；无效结果自动重试，最多三次。原始返回保存为 `naming-1.txt` 等诊断文件。
- **branch/tree 为空**：分析和计划阶段这是正常状态，实施前才分配名称。不要让模型手动编辑 `state.json`。将状态改成 `running` 不会启动执行，必须使用 `/task-resume`。
- **手动创建过本任务 worktree**：恢复时插件核对已记录路径、分支、Git worktree 登记、仓库和基线，通过后补齐名称与创建标记，继续使用；不匹配则停止，不盲目接管。

- **找不到命令**：退出并重新启动 opencode2，确认使用的是 V2 的启动脚本。
- **主工作空间有已跟踪文件的未提交改动**：先自行提交或保存这些改动，再开始任务。已有未跟踪文件允许保留，不会自动带入 worktree。
- **同名分支或目录存在**：插件自动选择可用后缀，不会复用冲突的 worktree。已有任务应在原会话中 resume；已成功创建并记录的 worktree 会继续复用。旧版手动命名任务仍可恢复。
- **权限询问**：按 OpenCode 提示允许任务需要的操作，尤其是新 worktree 和 `.git/opencode-tasks` 的文件访问。插件没有更改全局工具权限。
- **需要补充需求**：先在原会话说明补充内容，处理完后 resume。
- **合并冲突或验证失败**：查看当前会话和报告，处理后 resume。插件不会把“模型停止输出”当作成功。
- **要修改模型**：在项目 `.opencode/task-workflow.json` 中覆盖 models，对之后启动的任务生效。全局默认值仍位于 `index.ts` 顶部 models。
- **禁用**：从 V2 配置的 `plugins` 中移除本插件路径，重启 opencode2。

## 验证与维护

在插件目录执行：

```sh
npm run check
bun test workflow.test.ts
```

测试用模拟模型和真实临时 Git 仓库验证：缺少完成回执会暂停、resume 恢复、模型顺序、worktree 创建、提交合并、目录返回。安装时另行验证了真实 V2 服务的插件 active 状态及三个命令注册成功。

没有在真实 LazyDB 仓库中启动付费模型完整任务；首次实际需求执行仍是模型端到端验证。
