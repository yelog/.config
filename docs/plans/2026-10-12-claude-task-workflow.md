# Claude Code /task 工作流迁移实施计划

> **For Claude:** 按任务顺序实施，每完成一项检查其验收标准。若执行环境提供 `superpowers:executing-plans` 可使用它；没有该技能时按本计划逐项执行。不得默认创建子 Agent、提交、推送或启用全局插件。

**Goal:** 在 Claude Code 中提供可恢复的 `/task` 自动开发工作流，并复用独立核心提高状态、验证和 Git 集成的可靠性。

**Architecture:** 用普通 TypeScript/Node CLI 管理状态、锁、回执、验证及 Git 操作；Claude Mod 负责命令、模型路由、事件调度与界面；阶段 Skill 提供执行规范。保留单会话和四个用户可见执行阶段，内部把集成拆成可恢复步骤。先验证 Claude 适配，再迁移 OpenCode；旧任务不自动接管。

**Tech Stack:** TypeScript、Node.js、Git、Bun 测试、Claude Code Mods；现有 OpenCode V2 插件作为兼容适配器。第一版不增加 MCP 服务、常驻 daemon 或 Agent SDK。

---

## 约束与已知事实

- 当前插件：`opencode/plugins/task-workflow/`，约 591 行服务端实现及独立 workspace/progress/RPC/TUI 文件。
- 当前 Claude Code：2.1.296；官方 Mods 文档最低终端版本为 2.1.287。本计划以本机生成的类型声明为最终 API 依据。
- 已运行原插件回归：12 pass、0 fail、185 assertions；模型端为模拟实现，真实模型端到端仍需验证。
- 分析/规划和实施分别配置 `planner`、`executor` 角色；角色不绑定厂商或模型名称。
- 当前 Sol/Luna 是否能通过 Claude 所用网关执行完整工具循环未验证，不作为首版成功的前提。
- `/task` 的授权语义应在安装说明及第一次使用时明确。只有记录了本任务提交/合并授权，核心才执行相应操作；不推送。
- 工作流的普通权限继续经过宿主检查，不启用 bypassPermissions，不设置全局工具自动允许。
- 原插件和用户配置保持可恢复；切换上线前不覆盖已运行的旧任务。
- 本计划只定义实施，不授权现在执行实现、Git 提交或全局启用。

## 文件布局

所有路径相对本配置仓库 `/Users/yelog/.config`，标注外部目录的除外。

```text
task-workflow/
  package.json
  tsconfig.json
  README.md
  src/
    cli.ts
    protocol.ts
    state.ts
    storage.ts
    locks.ts
    git.ts
    workspace.ts
    artifacts.ts
    receipts.ts
    validation.ts
    progress.ts
    integration.ts
    engine.ts
    config.ts
    prompts.ts
  tests/
    fixtures.ts
    protocol.test.ts
    storage.test.ts
    locks.test.ts
    workspace.test.ts
    artifacts.test.ts
    receipts.test.ts
    validation.test.ts
    progress.test.ts
    integration.test.ts
    engine.test.ts
    cli.test.ts
  adapters/claude/
    .claude-plugin/plugin.json
    hooks/hooks.json
    hooks/register.ts
    skills/task-analyze/SKILL.md
    skills/task-plan/SKILL.md
    skills/task-implement/SKILL.md
    skills/task-review/SKILL.md
    tests/commands.test.ts
    tests/scheduler.test.ts
    tests/worktree.test.ts
    tests/ui.test.ts
```

独立核心由 `npm run build` 编译，入口为 `task-workflow/dist/cli.js`。Mod 不导入核心 Node 模块，通过 `$.process.run` 调用这个入口。正式打包时把已构建核心放到插件的 `bin/` 下，保证插件离开本仓库仍能运行；开发态使用明确配置的绝对入口。

任务数据建议保存为 `<git-common-dir>/task-workflow/tasks/<task-id>/`，会话绑定保存为宿主及 session ID 到 task ID 的映射。任务 ID 使用随机 UUID，与宿主 session ID 分离。原 `<git-common-dir>/opencode-tasks/` 不搬迁、不改写。

## 核心协议与状态设计

CLI 的 stdout 只返回一个 JSON 对象，诊断写 stderr。参数使用 argv，禁止生成 shell 拼接命令。返回 envelope：`{protocolVersion:1,ok:true,data:...}` 或 `{protocolVersion:1,ok:false,error:{code,message,retryable}}`。

初始命令接口：

- `init --request <绝对请求文件>`：校验需求、仓库、模型角色、授权，创建任务。
- `status --task <id> --repo <path>`：只读状态及展示摘要，不续做。
- `next --task <id> --repo <path>`：在锁内分配一次执行 attempt，返回阶段、角色、提示词、回执路径、token。
- `complete --request <绝对请求文件>`：携带 task ID、attempt ID、turn ID、完成原因，校验当前回执并推进。
- `pause --task <id> --repo <path> --reason <reason>`：记录用户暂停，取消已排队的续做授权。
- `resume --task <id> --repo <path>`：核对遗留 attempt、任务实际状态和 worktree，重新允许续做。
- `cleanup --repo <path>`：只读列举；明确传 `--apply` 才删除通过校验的残留。

长需求、完成事件和配置使用请求文件，避免 argv 长度和转义问题。request 文件位于任务专属目录；核心读取后校验 schema，不接受任意状态覆盖。

关键状态字段：`schemaVersion/revision/taskId/bindings/requirement/root/targetBranch/initialBase/base/taskBranch/worktree/stage/integrationStep/status/authorization/modelPolicy/attempt/budgets/artifacts/validation/reviewedCommit/lastError`。

状态枚举至少包含 `pending/running/waiting_input/paused/blocked/recoverable/done`。阶段为 `analyze/plan/implement/integrate/cleanup`；集成步骤为 `verify/commit/merge/verify_target/cleanup`。主会话结束、中断、模型失败、业务阻塞分别记录，不折叠成相同错误。

一次 attempt 记录 `attemptId/token/stage/turnId/expectedRevision/startedAt/receiptPath`；重复完成通知幂等，旧 attempt 和旧 token 拒绝。实现结束一律进入需求审查，审查通过才能进入集成。

## 任务 1：验证 Claude Mods 的实际能力边界

**文件：** 新建 Claude adapter manifest、hooks 配置、`register.ts` 和 `tests/commands.test.ts`；生成类型目录仅用于开发，是否提交由仓库约定决定。

1. 建立最小 Mod，只注册临时 `task-probe` 命令和只读状态显示，不注册正式 `/task`。
2. 用 `claude plugin validate task-workflow/adapters/claude --strict` 验证；预期通过并列出实际事件与调用。
3. 在可信临时 Git 仓库用 `claude --plugin-dir /Users/yelog/.config/task-workflow/adapters/claude` 启动交互会话，获取本构建类型声明。
4. 从声明确认 `command.run`、`turn.complete`、`turn.step`、计时器、worktree 工具调用、提示词提交和 UI band 的精确输入/输出。不要根据文档猜签名。
5. 用 `claude plugin test task-workflow/adapters/claude` 验证命令注册、立即只读命令和一个完成事件；不调用真实模型。
6. 以一次明确的微小真实任务确认模型路由及中断事件；保留日志摘要，不保存凭据。

**验收：** 形成 README 能力表；证明下一轮可安全调度，确认中断不会触发继续。若 Mod 无法可靠调用 Enter/ExitWorktree，先选“明确的工具阶段提示词 + 实际 cwd 核对”，不要改用未验证的 cwd setter。

## 任务 2：建立核心包与 JSON 协议

**文件：** package.json、tsconfig.json、src/cli.ts、src/protocol.ts、tests/protocol.test.ts、tests/cli.test.ts。

1. 定义请求与响应判别联合类型和运行时字段校验；新增协议版本拒绝、无效参数、stdout 污染测试。
2. 执行 `bun test task-workflow/tests/protocol.test.ts task-workflow/tests/cli.test.ts`，确认测试因实现缺失失败。
3. 实现 CLI 分发、stderr 诊断、JSON envelope 和退出码；先只支持只读探测及未知命令拒绝。
4. 在核心目录执行 `npm run check`、`npm run build` 并重跑定向测试；用 `node task-workflow/dist/cli.js` 验证编译产物能启动。

**验收：** 无需 Bun 即可运行编译后的 CLI；非法输入不给出可执行副作用。

## 任务 3：实现版本化状态与原子持久化

**文件：** src/state.ts、src/storage.ts、tests/storage.test.ts、tests/fixtures.ts。

1. 定义显式状态转换表及 schemaVersion，禁止任意字符串状态和任意跳阶段。
2. 添加截断状态文件、revision 冲突、重复完成、写入中崩溃测试。
3. 实现同目录临时文件写入、文件同步、原子 rename；必要时同步目录，清理自己创建的临时文件。
4. 将 revision 比较放在持有锁的写事务内；更新状态后才对外报告成功。
5. 执行 `bun test task-workflow/tests/storage.test.ts`。

**验收：** 读取只看见完整旧状态或完整新状态；损坏状态报告 recoverable 错误并保留原文件。

## 任务 4：实现跨进程锁和失效执行恢复

**文件：** src/locks.ts、tests/locks.test.ts、src/storage.ts。

1. 明确使用短事务锁而非覆盖整个模型轮次的锁；模型执行期间由持久化 attempt 占有执行权。
2. 用两个真实 Node 子进程测试同一 task 竞争、不同 task 并发、owner 崩溃和旧 owner 删除新锁。
3. 使用独占创建及随机 owner token；记录 PID、主机和创建时间，只有确认本机 owner 已退出才能自动回收。时间超时本身不证明 owner 死亡。
4. owner 无法确定时拒绝自动接管并给出明确恢复操作，不仅根据锁龄删除。
5. 集成锁按 canonical Git common directory 和目标 checkout 标识；检查到合并操作之间不能释放。
6. 执行 `bun test task-workflow/tests/locks.test.ts`。

**验收：** 同一任务不能分配两个 active attempt，同一目标 checkout 不会同时集成。

## 任务 5：抽取 Git 与工作区检查

**文件：** src/git.ts、src/workspace.ts、tests/workspace.test.ts；来源为现有 workspace.ts。

1. 迁入原 parseScope/dirtyPaths/changedPaths/overlaps 行为及相应真实 Git 测试。
2. Git 调用统一 argv、显式 cwd、超时、退出码、可取消进程，移除服务端同步阻塞调用。
3. 校验 checkout、common directory、目标分支、分支 HEAD、重命名两端、目录前缀、大小写配置和含空格路径。
4. 为符号链接及路径逃逸补充有意义的测试；区分路径归属检查与 shell 写入约束，不能声称实现完全沙箱。
5. 执行 `bun test task-workflow/tests/workspace.test.ts`。

**验收：** 无关脏文件继续允许，重叠文件暂停；不自动 stash、提交或覆盖用户改动。

## 任务 6：明确任务产物归属

**文件：** src/artifacts.ts、tests/artifacts.test.ts、src/prompts.ts。

1. 分析、计划、回执均只写任务专属目录；禁止扫描时间窗口内其他新增文件。
2. 创建 worktree 后，把明确登记的 plan.md 写到一个固定计划路径；目标同名且内容不同则暂停。
3. 记录源文件 hash、目标相对路径和迁入结果；恢复时相同内容操作幂等。
4. 测试用户同时新增计划文档、两任务并行计划、目标文件冲突及复制后崩溃。
5. 执行 `bun test task-workflow/tests/artifacts.test.ts`。

**验收：** 主 checkout 不产生本任务规划残留；用户新建的文档不会被移动或删除。

## 任务 7：回执和必经需求审查

**文件：** src/receipts.ts、tests/receipts.test.ts、src/prompts.ts、Claude 阶段 Skills。

1. 保留 token/stage 校验，增加 attempt ID、字段类型、大小上限和三个回执状态的必需字段。
2. completed 要求产物存在、非空，且对应阶段的核心门禁通过。
3. 实施 completed 转为 review_pending；所有任务至少一次审查，不仅在停滞时审查。
4. 审查需求清单以初始化/计划确认的需求 ID 为基准，不能让模型通过缩减清单声称全部完成。
5. 审查证据指向实际文件、差异或程序验证记录；结构校验与语义判断分开记录。
6. 添加旧 token、缺失需求、伪造验证 ID、required 检查延后、重复完成和审查后代码变化测试。
7. 执行 `bun test task-workflow/tests/receipts.test.ts`。

**验收：** 未关闭的必需项不能进入集成；审查后相关代码变化使审查结论失效。

## 任务 8：程序采集验证证据

**文件：** src/validation.ts、src/config.ts、tests/validation.test.ts。

1. 项目验证配置使用 argv 数组、显式相对 cwd、required 标记、依赖文件范围、timeout 和环境依赖声明。
2. 配置来自可信项目并经过明确选择；不自动运行从任意报告提取的命令。
3. 核心执行配置检查，记录命令、退出码、输出日志路径、执行目录、代码指纹、工具版本及环境摘要。
4. 环境摘要不能包含原始凭据；涉及敏感配置用不可逆摘要或仅标记版本，并按项目需要确定。
5. 缓存 key 包含命令、cwd、依赖内容、工具及相关环境；依赖不明确的检查默认使用整个 checkout 指纹。
6. 测试相关代码变更失效、无关变更复用、环境变化、超时、取消、无验证配置和目标 checkout 验证。
7. 执行 `bun test task-workflow/tests/validation.test.ts`。

**验收：** failed/未执行检查不能标 passed；required 未通过停止集成。没有配置时明确报告验证覆盖限制，不虚构通用测试。

## 任务 9：改进进展判定和预算

**文件：** src/progress.ts、tests/progress.test.ts。

1. 分析/计划比较各自产物 hash；实施比较代码、有效验证记录和剩余需求，集成比较步骤推进。
2. 排除目录由配置决定，移除固定 docs/plans 假设；同一错误/下一步重复计数。
3. 区分 attempt、自动续做轮次、模型调用次数和重试次数；增加单次运行及累计预算。
4. resume 重置单次运行额度但保留累计轮次、重复失败和先前审查结论。
5. 对临时错误采用有上限退避，避免模型自身重试与工作流重复提交；完成原因不明确时先 reconcile。
6. 执行 `bun test task-workflow/tests/progress.test.ts`。

**验收：** 报告有实质进展不会被误判为代码停滞；反复 resume 不会抹掉循环证据。

## 任务 10：可恢复的提交、合并和清理

**文件：** src/integration.ts、tests/integration.test.ts。

1. 建立 verify/commit/merge/verify_target/cleanup 子步骤，执行前写 operation intent，执行后记录实际 Git 状态。
2. 只有任务授权允许且审查证据对应当前代码，才暂存明确任务路径并提交；提交说明由模型建议，核心执行。
3. 提交前检查已暂存文件，出现非任务内容则暂停；记录 reviewedCommit，核对任务 HEAD 未变化。
4. 持有目标集成锁后复查目标分支、脏文件及当前 HEAD。目标自审查以来前进时，先检查是否需更新/再验证，不盲目沿用旧结论。
5. 合并前记录 targetBefore、taskTip。合并后记录 targetAfter；恢复时读取 MERGE_HEAD、祖先关系和工作区状态判断是否已执行。
6. 冲突时保留现场并 blocked，不自动 reset/stash/abort；说明准确恢复步骤。
7. 合并后必要检查失败则保留任务和所有恢复信息，不自动撤销目标历史或清理。
8. 清理先确认宿主已离开 worktree，再验证任务分支尖端等于 reviewedCommit、已进入目标、worktree 干净以及无其他已知任务绑定。
9. worktree 和分支逐项删除，不用 force；遇到未知锁或活跃使用者保留并报告。
10. 在每个副作用之后注入崩溃，重启后验证不会重复提交/合并；执行 `bun test task-workflow/tests/integration.test.ts`。

**验收：** 任一子步骤失败都有准确恢复位置；cleanup 重试不运行模型或重复集成。

## 任务 11：组装工作流引擎与项目配置

**文件：** src/engine.ts、src/config.ts、src/prompts.ts、tests/engine.test.ts、src/cli.ts。

1. 将前述组件连接到 init/next/complete/pause/resume/cleanup 命令。
2. 项目配置采用 `.task-workflow.json`，只读取已知字段；planner/executor 角色使用宿主可解析的模型字符串。
3. 默认模型策略 pinned，follow 可显式启用；记录每轮实际模型，防止恢复时悄悄改变执行成本及能力。
4. 单会话仅绑定一个活跃任务；完成后可创建新 task ID，保留历史。
5. 测试完整模拟阶段循环、失效回执、用户暂停、累计预算、进程重启、无关脏文件及重复事件。
6. 执行 `bun test task-workflow/tests/engine.test.ts task-workflow/tests/cli.test.ts`，随后核心 `npm run check` 与 `npm run build`。

**验收：** 模拟模型配合真实 Git 仓库完成一条完整任务；核心不依赖 OpenCode SDK 或 Claude 模块。

## 任务 12：Claude 命令和事件调度

**文件：** adapters/claude/hooks/register.ts、tests/commands.test.ts、tests/scheduler.test.ts。

1. 注册 `/task`、`/task-status`、`/task-resume`、`/task-cleanup`；只读 status 可 immediate，修改命令串行处理。
2. 命令名占用时输出明确错误，不静默覆盖；status 不触发模型轮次。
3. session.start 只恢复展示及绑定，不自动继续 interrupted 任务；用户显式 resume 后启动。
4. 用核心 next 分配 attempt；turn.start 绑定实际 turn ID。用户普通消息和插件消息区分来源，不能把普通回答当阶段完成。
5. turn.step 仅对本任务主 Agent 请求路由模型，不改标题、其他 Agent 或无关请求。
6. turn.complete 匹配主 Agent、turn ID 和 attempt；中断先 pause，完成先调用核心 complete。
7. 在完成处理结束之后，后台计时器提交下一轮；不在正在阻塞当前 turn 的处理器内 await 下一轮启动。
8. 用户新消息先作 steering/需求修订，清除过期排队 generation；需求变化使计划、审查及验证按范围失效。
9. 测试完成事件重复、子 Agent 事件、非任务 turn、pause 与排队竞争、reload、提交返回但轮次未完成。
10. 执行 `claude plugin validate task-workflow/adapters/claude --strict` 与 `claude plugin test task-workflow/adapters/claude`。

**验收：** 无重复派发、无等待死锁、无停止后重启；核心错误转可见暂停。

## 任务 13：Claude worktree 生命周期

**文件：** register.ts、tests/worktree.test.ts、src/config.ts、src/integration.ts。

1. 默认使用 `.claude/worktrees/<task-name>`，显式从实施前当前 HEAD 建立基线，不依赖默认 fresh 行为。
2. 第一项探针确认后选择唯一创建 owner：优先核心创建明确分支和目录，宿主 EnterWorktree 负责采用；若本版本无法采用，使用原生创建并立即核对名称、分支和基线。
3. 进入后读取实际 cwd 和 Git identity 再允许实施；拒绝重复创建、错误仓库和错误分支。
4. 核心集成操作通过已记录授权执行；不要把被原生隔离禁止的 git -C 主 checkout 命令发给模型。
5. 合并及目标验证后 ExitWorktree 先保留目录和分支，再交核心清理；核实退出接口不会提前删除未确认产物。
6. 外部目录保留为显式可选模式，说明可能需要宿主批准；不得修改 bypassPermissions 绕过。
7. 测试进入失败、退出失败、worktree 锁、目录被用户删除、分支切换和恢复 cwd。

**验收：** 实施期间工具处于正确 worktree；清理失败留存代码；清理成功回原 checkout。

## 任务 14：进度界面、提醒和文档

**文件：** register.ts、tests/ui.test.ts、README.md、四个阶段 SKILL.md。

1. 显示五阶段、实际模型、暂停原因、轮次及下一步；无任务不占空间，不显示虚构百分比。
2. 持久化状态变化后更新内存展示；补读只恢复状态，不分配 attempt。
3. CLI/Desktop 使用 band；不支持绘制的宿主用只读文本 status 降级。
4. task 进入终态时以 task ID + transition revision 去重 toast；操作系统通知列为独立可选增强，不假设 toast 等于系统通知。
5. Skill 只包含阶段知识及产物约定，不要求自行改 state、创建 worktree、提交合并或启动子 Agent。
6. 文档覆盖授权语义、模型配置、验证配置、恢复、清理、版本要求与未验证限制。

**验收：** 新会话/插件 reload 不重复提醒；所有展示从核心状态生成。

## 任务 15：OpenCode 兼容接入和旧任务策略

**文件：** 修改 opencode/plugins/task-workflow/index.ts、workspace.ts、progress.ts、rpc.ts、README.md、workflow.test.ts。

1. Claude 新任务通过验收后才切换 OpenCode 新任务到核心；维持现有 `/task` 等命令和 TUI RPC。
2. 旧任务识别原 opencode-tasks 状态，继续调用旧执行路径；不要直接套新 schema。
3. 如旧实现需保留，先抽为清晰 legacy 模块，避免在新核心中堆积旧行为分支。
4. 对旧配置 astra/luna 作适配映射，保留旧任务目录、模型策略和授权语义；新任务使用 planner/executor。
5. 修正文档中计划文档归属保证、测试缓存及审查证据的过度表述。
6. 执行原插件 `npm run check`、`bun test workflow.test.ts`，再运行核心定向兼容测试。

**验收：** 已有 12 项回归继续通过；原任务可恢复，新任务使用同一核心规则。

## 任务 16：端到端验收、发布和回退

**文件：** README.md、adapters/claude/.claude-plugin/plugin.json；若正式安装，安装配置改动单独列明。

1. 先执行核心 check/build/全套测试和 Mod validate/test，无真实模型费用。
2. 在临时仓库执行一个小型真实任务：分析、计划、实施、审查、提交、合并、目标验证及清理。事先只对该临时仓库明确授予提交合并权限。
3. 再验证一次实施中断后恢复、一次重叠脏文件暂停、一次清理失败恢复，不扩大测试业务范围。
4. 本机 Sol/Luna 网关用单独小型探针验证完整工具循环；失败时保持原 Claude 模型角色配置，并记录不兼容原因。
5. 发布包包含构建后的核心，README 标出实测 Claude 版本；用 --plugin-dir 试用后再配置全局安装。
6. 全局启用前给出文件清单、配置差异及回退方式；按照实际授权执行。没有安装授权时交付可验证插件目录。
7. 回退仅停用新适配器并恢复原插件入口；已运行新任务保留状态/worktree，不让旧插件接管新 schema。

**验收：** 真模型任务成功；恢复场景成功；用户未提交文件内容和 Git index 在无关场景中保持不变；未 push。

## 里程碑与依赖

| 里程碑 | 任务 | 放行条件 |
| --- | --- | --- |
| M0 API 可行性 | 1 | 本机声明及探针支持命令、调度、worktree 生命周期 |
| M1 可独立运行核心 | 2–6 | 协议、状态、锁、工作区与产物测试通过 |
| M2 可恢复自动开发 | 7–11 | 审查和验证门禁、集成崩溃恢复通过 |
| M3 Claude 本地试用 | 12–14 | Mod 测试通过、同会话流程和界面正常 |
| M4 两端共用及上线 | 15–16 | 原回归通过、真模型验收及回退验证完成 |

M0 是必须先完成的门禁。M1/M2 的实现按任务顺序推进；不默认委派并行 Agent。OpenCode 的切换依赖 Claude 验收，不与核心抽取同时上线。

## 完成定义

- `/task <需求>` 能从明确的启动分支完成四阶段及清理，不要求用户反复输入 resume。
- 用户中断后不自动继续；恢复复用已确认产物与仍有效的检查。
- 重复事件、跨进程恢复和任意集成步骤崩溃不会重复创建分支、提交或合并。
- 重叠用户改动暂停，无关改动保留；任务文档归属明确。
- 所有实施完成必须审查，必要验证由程序采集且通过，未验证项目明确列出。
- worktree 清理必须在宿主离开目录、提交已合并且没有新工作之后执行。
- 模型路由、费用预算、授权范围和错误原因可查；没有 push 或历史重写。
- 原 OpenCode 任务继续可恢复，关闭新插件即可停止新任务调度。

## 本次计划编制的验证范围

本次只新增计划文件。前轮已运行的原插件 12 项回归作为当前基线；此文档中的新核心、Mod 测试和真实模型验收均是未来实施步骤，尚未执行。
