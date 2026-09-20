import { test, expect } from 'bun:test'
import { mkdtemp, readFile, writeFile, rm, realpath, mkdir } from 'node:fs/promises'
import { execFileSync } from 'node:child_process'
import path from 'node:path'
import plugin, { parseName, settingsFor, taskDirectory } from './index'
import { needsCompletionReview, validCompletionReview, receiptFrom } from './progress'
import { isTerminalTaskStatus, progressLines, terminalNotification, type TaskView } from './rpc'
import { parseScope, dirtyPaths, workspaceCheck, overlaps } from './workspace'

test('progress distinguishes execution, review, blocked, stale, cleanup and completion', () => {
  const task: TaskView = { sessionID: 'ses_test', name: 'demo', step: 2, status: 'running', running: true, review: false, model: 'luna', rounds: 3, next: 'save edits' }
  expect(progressLines(task)[0]).toBe('✓ 分析 → ✓ 计划 → ● 实施 → ○ 集成 → ○ 清理')
  expect(progressLines({ ...task, review: true })[1]).toContain('收尾审查')
  expect(progressLines({ ...task, running: false })[1]).toContain('已中断，可恢复')
  expect(progressLines({ ...task, running: false, status: 'blocked', error: 'failed\n\x1b' })[1]).not.toContain('\x1b')
  expect(progressLines(task, '等待授权')[1]).toContain('等待授权')
  expect(progressLines({ ...task, step: 4, status: 'cleaning' })[0]).toContain('● 清理')
  expect(progressLines({ ...task, step: 4, status: 'done', running: false })[0]).toBe('✓ 分析 → ✓ 计划 → ✓ 实施 → ✓ 集成 → ✓ 清理')
})

test('notifications are terminal-only and use task-specific messages', () => {
  expect(isTerminalTaskStatus('running')).toBe(false)
  expect(isTerminalTaskStatus('cleaning')).toBe(false)
  expect(isTerminalTaskStatus('done')).toBe(true)
  expect(isTerminalTaskStatus('blocked')).toBe(true)
  const task: TaskView = { sessionID: 'ses_test', name: 'demo', step: 4, status: 'done', running: false, review: false, model: 'luna', rounds: 0, next: '' }
  expect(terminalNotification(task).message).toContain('已完成')
  expect(terminalNotification({ ...task, status: 'blocked', error: '需要权限' }).message).toContain('需要权限')
})

test('completion review triggers and evidence guard reject premature completion', () => {
  expect(needsCompletionReview('Run manual TUI acceptance', 0, 1)).toBe(true)
  expect(needsCompletionReview('implement next unit', 0, 6)).toBe(true)
  expect(needsCompletionReview('implement next unit', 2, 2)).toBe(true)
  expect(needsCompletionReview('implement next unit', 0, 1)).toBe(false)
  const valid = { reviewed: true, requirements: [{ requirement: 'save edits', status: 'passed', evidence: 'src/save.rs + save test' }], remainingRequired: [], deferredChecks: [{ check: 'manual TUI', required: false, reason: 'PTY unavailable; reducer/render integration tests passed' }] }
  expect(validCompletionReview(valid)).toBe(true)
  expect(validCompletionReview({ ...valid, remainingRequired: ['save path missing'] })).toBe(false)
  expect(validCompletionReview({ ...valid, requirements: [] })).toBe(false)
  expect(validCompletionReview({ ...valid, deferredChecks: [{ check: 'user-required manual acceptance', required: true, reason: 'unavailable' }] })).toBe(false)
  expect(receiptFrom('{"token":"old","stage":"implement","status":"completed"}', 'current', 'implement')).toBeUndefined()
})

test('name parsing tolerates wrappers without accepting arbitrary prose or paths', () => {
  for (const value of ['redis-pane', '`redis-pane`', '```text\nredis-pane\n```', '{"name":"redis-pane"}', 'task/redis-pane']) expect(parseName(value)).toBe('redis-pane')
  for (const value of ['请使用 redis-pane', '../redis-pane', '', '{"name":42}']) expect(parseName(value)).toBeUndefined()
})

test('automatic continuation, Astra correction, worktree integration and cleanup recovery', async () => {
  const temp = await realpath(await mkdtemp('/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/task-workflow-test-'))
  const git = (cwd: string, ...args: string[]) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: 'pipe' }).trim()
  git(temp, 'init', '-b', 'main'); git(temp, 'config', 'user.name', 'Workflow Test'); git(temp, 'config', 'user.email', 'test@example.invalid')
  await writeFile(path.join(temp, 'README.md'), 'base\n')
  git(temp, 'add', '.'); git(temp, 'commit', '-m', 'initial')
  await writeFile(path.join(temp, 'README.md'), 'unrelated local edits\n')
  const stem = path.basename(temp).toLowerCase()
  const prefix = path.basename(temp)
  const parent = path.join(path.dirname(temp), `${prefix}-worktree`)
  const occupied = path.join(parent, `${stem}-2`)
  git(temp, 'branch', `task/${stem}`)
  await mkdir(occupied, { recursive: true })
  let directory = temp, block = 2, corrections = 0
  let namingCalls = 0
  let implementationCalls = 0, reviewCalls = 0
  const commands = new Map<string, any>(), selected: string[] = []
  const sessionID = `ses_test_${Date.now()}`
  const folder = path.join(temp, '.git/opencode-tasks', sessionID)
  let resolveNote: (text: string) => void = () => {}
  const notification = () => new Promise<string>(resolve => { resolveNote = resolve })
  const ctx: any = {
    rpc: { register: async (_definition: any, handlers: any) => {
      commands.set('rpc-status', handlers.status)
      return { events: { emit: async (_type: string, input: any) => {
        const persisted = JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8'))
        expect(input.sessionID).toBe(persisted.sessionID)
      } } }
    } },
    generate: { text: async ({ prompt, model }: any) => {
      if (model.id === 'gpt-6-astra') {
        corrections++
        return { text: JSON.stringify({ needsUser: false, next: '完成当前分析并写入回执，不重复检查。' }) }
      }
      namingCalls++
      expect(model.id).toBe('gpt-5.6-luna')
      expect(prompt).toContain('test requirement')
      expect(prompt).toContain('# verified')
      return { text: namingCalls === 1 ? '需要先运行 /task-resume' : JSON.stringify({ name: stem }) }
    } },
    command: { transform: async (f: any) => f({ add: (c: any) => commands.set(c.name, c) }) },
    session: {
      get: async () => ({ location: { directory }, outcome: 'succeeded' }),
      move: async (i: any) => { directory = i.directory },
      wait: async () => {}, switchAgent: async () => {},
      switchModel: async (i: any) => { selected.push(i.model.id) },
      generate: async ({ prompt }: any) => {
        expect(prompt).toContain('test requirement')
        expect(prompt).toContain('# verified')
        return { text: stem }
      },
      synthetic: async ({ text }: any) => { if (text.includes('工作流暂停') || text.includes('已完成并合并')) resolveNote(text) },
      prompt: async ({ text }: any) => {
        if (block > 0) { block--; return }
        const match = /内容为 (\{[^\n]+?\})。未完成/.exec(text)!
        const receipt = JSON.parse(match[1])
        const file = /最后写入回执 ([^\n]+)，内容为/.exec(text)![1]
        const artifact: any = { analyze: 'analysis.md', plan: 'plan.md', implement: 'implementation.md', integrate: 'integration.md' }
        await writeFile(path.join(folder, artifact[receipt.stage]), '# verified\n')
        if (receipt.stage === 'plan') await writeFile(path.join(folder, 'change-scope.json'), JSON.stringify({ files: ['feature.txt'] }))
        if (receipt.stage === 'implement') {
          if (text.includes('本轮是 Luna 收尾审查')) {
            reviewCalls++
            expect(selected.at(-1)).toBe('gpt-5.6-luna')
            Object.assign(receipt, { reviewed: true, requirements: [{ requirement: 'test requirement', status: 'passed', evidence: 'feature.txt + test verification' }], remainingRequired: [], deferredChecks: [{ check: 'manual TUI', required: false, reason: 'PTY unavailable, automated behavior tests passed' }] })
          } else if (implementationCalls++ === 0) {
            Object.assign(receipt, { status: 'progress', next: 'Run manual TUI acceptance in an interactive terminal', completedItems: ['feature implemented'], checks: ['automated tests passed'] })
          }
          expect((await settingsFor(directory)).parent).toBe(parent)
          expect((await settingsFor(directory)).prefix).toBe(prefix)
          await writeFile(path.join(directory, 'feature.txt'), 'implemented\n')
        }
        if (receipt.stage === 'integrate') {
          git(directory, 'add', '.'); git(directory, 'commit', '-m', 'feat: test task')
          git(temp, 'merge', '--no-edit', `task/${stem}-3`)
        }
        await writeFile(file, JSON.stringify(receipt))
      },
    },
  }
  try {
    await plugin.setup(ctx)
    let done = notification()
    await commands.get('task').execute({ sessionID, prompt: { text: 'test requirement' } })
    expect(await done).toContain('已完成并合并')
    expect(selected).toEqual(['gpt-6-astra', 'gpt-6-astra', 'gpt-6-astra', 'gpt-6-astra', 'gpt-5.6-luna', 'gpt-5.6-luna', 'gpt-5.6-luna', 'gpt-5.6-luna'])
    expect(reviewCalls).toBe(1)
    expect(JSON.parse(await readFile(path.join(folder, 'completion-decision.json'), 'utf8')).deferredChecks[0].check).toBe('manual TUI')
    expect(corrections).toBe(1)
    expect(directory).toBe(temp)
    const tree = path.join(parent, `${stem}-3`)
    expect(JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8')).tree).toBe(tree)
    expect(git(temp, 'branch', '--list', `task/${stem}-3`)).toBe('')
    expect(git(temp, 'worktree', 'list', '--porcelain')).not.toContain(tree)
    expect(await Bun.file(path.join(tree, '.git')).exists()).toBe(false)
    expect(await readFile(path.join(temp, 'feature.txt'), 'utf8')).toBe('implemented\n')
    expect(await readFile(path.join(temp, 'README.md'), 'utf8')).toBe('unrelated local edits\n')
    expect(JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8')).status).toBe('done')
    expect(namingCalls).toBe(2)
    const view = await commands.get('rpc-status')({ sessionID })
    expect(view.task.status).toBe('done')
    expect(view.task.running).toBe(false)
    expect((await commands.get('rpc-status')({ sessionID: 'ses_no_task' })).task).toBeNull()
    // Reproduce the user's partial manual repair: branch/tree exist but flags/name were omitted.
    git(temp, 'worktree', 'add', '-b', `task/${stem}-3`, tree, 'HEAD')
    const repaired = JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8'))
    repaired.step = 2; repaired.status = 'running'; repaired.name = '待 Luna 命名'; delete repaired.worktreeCreated
    await writeFile(path.join(folder, 'state.json'), JSON.stringify(repaired))
    const originalPrompt = ctx.session.prompt
    ctx.session.prompt = async (input: any) => {
      if (input.text.includes('阶段 integrate。')) {
        const file = /最后写入回执 ([^\n]+)，内容为/.exec(input.text)![1]
        await writeFile(file, /内容为 (\{[^\n]+\})。未完成/.exec(input.text)![1])
      } else await originalPrompt(input)
    }
    done = notification()
    await commands.get('task-resume').execute({ sessionID })
    expect(await done).toContain('已完成并合并')
    expect(namingCalls).toBe(2)
    expect(JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8')).name).toBe(`${stem}-3`)
    // Failed cleanup resumes without another model request or integration.
    git(temp, 'worktree', 'add', '-b', `task/${stem}-3`, tree, 'HEAD')
    await writeFile(path.join(tree, 'local.txt'), 'preserve me')
    const cleanup = JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8'))
    cleanup.status = 'blocked'
    await writeFile(path.join(folder, 'state.json'), JSON.stringify(cleanup))
    const calls = selected.length
    done = notification()
    await commands.get('task-resume').execute({ sessionID })
    expect(await done).toContain('未提交文件')
    expect(await readFile(path.join(tree, 'local.txt'), 'utf8')).toBe('preserve me')
    await rm(path.join(tree, 'local.txt'))
    done = notification()
    await commands.get('task-resume').execute({ sessionID })
    expect(await done).toContain('已完成并合并')
    expect(selected.length).toBe(calls)
    expect(git(temp, 'branch', '--list', `task/${stem}-3`)).toBe('')
  } finally {
    try { git(temp, 'worktree', 'remove', '--force', path.join(parent, `${stem}-3`)) } catch {}
    await rm(parent, { recursive: true, force: true })
    await rm(temp, { recursive: true, force: true })
  }
}, 30000)

test('dirty path matching handles staged renames, spaces, untracked files, deletes and directory conflicts', async () => {
  const root = await mkdtemp('/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/dirty-paths-')
  const git = (...args: string[]) => execFileSync('git', args, { cwd: root, stdio: 'pipe' })
  try {
    git('init'); git('config', 'user.name', 'Test'); git('config', 'user.email', 'test@example.invalid')
    await writeFile(path.join(root, 'old name.txt'), 'base')
    await writeFile(path.join(root, 'deleted.txt'), 'base')
    git('add', '.'); git('commit', '-m', 'initial')
    git('mv', 'old name.txt', '新 name.txt'); await rm(path.join(root, 'deleted.txt'))
    await mkdir(path.join(root, 'new')); await writeFile(path.join(root, 'new/file.txt'), 'local')
    expect(new Set(dirtyPaths(root))).toEqual(new Set(['old name.txt', '新 name.txt', 'deleted.txt', 'new/file.txt']))
    expect(workspaceCheck(root, ['old name.txt']).conflicts).toEqual(['old name.txt'])
    expect(workspaceCheck(root, ['new']).conflicts).toEqual(['new/file.txt'])
    expect(workspaceCheck(root, ['other.txt']).conflicts).toEqual([])
    expect(overlaps(['src/app.rs'], ['src'])).toEqual(['src'])
    expect(overlaps(['src/app.rs'], ['SRC/App.rs'], true)).toEqual(['SRC/App.rs'])
    expect(parseScope('{"files":["./src/app.rs","src/app.rs","tests/"]}')).toEqual(['src/app.rs', 'tests'])
    expect(() => parseScope('{"files":["../outside"]}')).toThrow()
    expect(() => parseScope('{"files":["src/**/*.rs"]}')).toThrow()
  } finally { await rm(root, { recursive: true, force: true }) }
})

test('overlapping edits block only after plan; resume uses committed changes as worktree base', async () => {
  const root = await realpath(await mkdtemp('/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/overlap-flow-'))
  const git = (...args: string[]) => execFileSync('git', args, { cwd: root, encoding: 'utf8', stdio: 'pipe' }).trim()
  const sessionID = `ses_overlap_${Date.now()}`, folder = path.join(root, '.git/opencode-tasks', sessionID)
  const tree = path.join(path.dirname(root), `${path.basename(root)}-worktree`, 'edit-feature')
  const commands = new Map<string, any>(), stages: string[] = []
  let directory = root, outcome = 'succeeded', finish!: (text: string) => void, bases: string[] = [], complete = false
  const notification = () => new Promise<string>(resolve => { finish = resolve })
  try {
    git('init', '-b', 'main'); git('config', 'user.name', 'Test'); git('config', 'user.email', 'test@example.invalid')
    await writeFile(path.join(root, 'feature.txt'), 'base')
    git('add', '.'); git('commit', '-m', 'initial')
    await writeFile(path.join(root, 'feature.txt'), 'user change')
    await plugin.setup({
      rpc: { register: async () => ({ events: { emit: async () => {} } }) },
      command: { transform: async (f: any) => f({ add: (c: any) => commands.set(c.name, c) }) },
      generate: { text: async () => ({ text: '{"name":"edit-feature"}' }) },
      session: {
        get: async () => ({ location: { directory }, outcome }), move: async (input: any) => { directory = input.directory },
        wait: async () => {}, switchAgent: async () => {}, switchModel: async () => {},
        synthetic: async ({ text }: any) => { if (text.includes('工作流暂停')) finish(text) },
        prompt: async () => {
          const state = JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8'))
          const { token, stage, path: receipt } = state.activeReceipt
          stages.push(stage)
          if (stage === 'implement') {
            bases.push(state.base)
            expect(await readFile(path.join(directory, 'feature.txt'), 'utf8')).toBe('user change')
            if (complete) {
              await writeFile(path.join(directory, 'feature.txt'), 'task implementation')
              // User starts editing the same file after the implementation preflight.
              await writeFile(path.join(root, 'feature.txt'), 'new user edits during implementation')
              await writeFile(path.join(folder, 'implementation.md'), 'implemented')
              await writeFile(receipt, JSON.stringify({ token, stage, status: 'completed' }))
              return
            }
            outcome = 'interrupted'; return
          }
          await writeFile(path.join(folder, `${stage === 'analyze' ? 'analysis' : stage}.md`), 'plan to edit feature.txt')
          if (stage === 'plan') await writeFile(path.join(folder, 'change-scope.json'), '{"files":["feature.txt"]}')
          await writeFile(receipt, JSON.stringify({ token, stage, status: 'completed' }))
        },
      },
    } as any)
    let done = notification()
    await commands.get('task').execute({ sessionID, prompt: { text: 'edit feature' } })
    expect(await done).toContain('feature.txt')
    expect(stages).toEqual(['analyze', 'plan'])
    expect(git('branch', '--list', 'task/*')).toBe('')
    expect(JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8')).step).toBe(2)
    git('add', 'feature.txt'); git('commit', '-m', 'user changes')
    const newBase = git('rev-parse', 'HEAD')
    done = notification()
    await commands.get('task-resume').execute({ sessionID })
    expect(await done).toContain('interrupted')
    expect(stages).toEqual(['analyze', 'plan', 'implement'])
    expect(bases).toEqual([newBase])
    // The synthetic notification resolves before run() reaches its finally cleanup.
    await new Promise<void>(resolve => setImmediate(resolve))
    complete = true; outcome = 'succeeded'; done = notification()
    await commands.get('task-resume').execute({ sessionID })
    expect(await done).toContain('feature.txt')
    expect(stages).not.toContain('integrate')
    expect(JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8')).step).toBe(3)
    expect(JSON.parse(await readFile(path.join(folder, 'workspace-check.json'), 'utf8')).phase).toBe('before-integration')
    expect(await readFile(path.join(root, 'feature.txt'), 'utf8')).toBe('new user edits during implementation')
    expect(git('rev-parse', 'HEAD')).toBe(newBase)
  } finally {
    try { git('worktree', 'remove', '--force', tree) } catch {}
    await rm(path.dirname(tree), { recursive: true, force: true })
    await rm(root, { recursive: true, force: true })
  }
}, 30000)

test('plan document created during the plan stage is committed with the task, not left untracked', async () => {
  const root = await realpath(await mkdtemp('/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/plan-doc-'))
  const git = (...args: string[]) => execFileSync('git', args, { cwd: root, encoding: 'utf8', stdio: 'pipe' }).trim()
  const gitAt = (cwd: string, ...args: string[]) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: 'pipe' }).trim()
  const sessionID = `ses_plan_${Date.now()}`
  const folder = path.join(root, '.git/opencode-tasks', sessionID)
  const doc = 'docs/plans/2026-01-01-demo-implementation.md'
  const tree = path.join(path.dirname(root), `${path.basename(root)}-worktree`, 'demo')
  const commands = new Map<string, any>()
  let directory = root, finish!: (text: string) => void, sawInWorktree = false, sawInMain = true
  const notification = () => new Promise<string>(resolve => { finish = resolve })
  try {
    git('init', '-b', 'main'); git('config', 'user.name', 'Test'); git('config', 'user.email', 'test@example.invalid')
    await writeFile(path.join(root, 'feature.txt'), 'base'); git('add', '.'); git('commit', '-m', 'initial')
    await plugin.setup({
      rpc: { register: async () => ({ events: { emit: async () => {} } }) },
      command: { transform: async (f: any) => f({ add: (c: any) => commands.set(c.name, c) }) },
      generate: { text: async () => ({ text: '{"name":"demo"}' }) },
      session: {
        get: async () => ({ location: { directory }, outcome: 'succeeded' }), move: async (i: any) => { directory = i.directory },
        wait: async () => {}, switchAgent: async () => {}, switchModel: async () => {},
        synthetic: async ({ text }: any) => { if (text.includes('已完成并合并') || text.includes('工作流暂停')) finish(text) },
        prompt: async ({ text }: any) => {
          const state = JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8'))
          const { token, stage, path: receipt } = state.activeReceipt
          const artifact: any = { analyze: 'analysis.md', plan: 'plan.md', implement: 'implementation.md', integrate: 'integration.md' }
          await writeFile(path.join(folder, artifact[stage]), '# content\n')
          if (stage === 'plan') {
            await writeFile(path.join(folder, 'change-scope.json'), '{"files":["feature.txt"]}')
            // The model follows the writing-plans convention and writes into the repo.
            await mkdir(path.join(root, 'docs/plans'), { recursive: true })
            await writeFile(path.join(root, doc), '# demo implementation\n')
          }
          if (stage === 'implement') {
            expect(state.planDoc).toBe(doc)
            sawInWorktree = await Bun.file(path.join(directory, doc)).exists()
            sawInMain = await Bun.file(path.join(root, doc)).exists()
            await writeFile(path.join(directory, 'feature.txt'), 'implemented\n')
          }
          if (stage === 'integrate') {
            gitAt(directory, 'add', '.'); gitAt(directory, 'commit', '-m', 'feat: demo task')
            git('merge', '--no-edit', 'task/demo')
          }
          await writeFile(receipt, JSON.stringify({ token, stage, status: 'completed' }))
        },
      },
    } as any)
    const done = notification()
    await commands.get('task').execute({ sessionID, prompt: { text: 'demo requirement' } })
    expect(await done).toContain('已完成并合并')
    expect(sawInWorktree).toBe(true)
    expect(sawInMain).toBe(false)
    // The document travels with the task and lands tracked in main.
    expect(git('ls-files', doc)).toBe(doc)
    expect(git('status', '--porcelain')).toBe('')
    expect(await readFile(path.join(root, doc), 'utf8')).toBe('# demo implementation\n')
    expect(git('branch', '--list', 'task/demo')).toBe('')
  } finally {
    try { git('worktree', 'remove', '--force', tree) } catch {}
    await rm(path.join(path.dirname(root), `${path.basename(root)}-worktree`), { recursive: true, force: true })
    await rm(root, { recursive: true, force: true })
  }
}, 30000)

test('task-cleanup removes merged leftovers and refuses unmerged or dirty ones', async () => {
  const root = await realpath(await mkdtemp('/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/cleanup-'))
  const git = (...args: string[]) => execFileSync('git', args, { cwd: root, encoding: 'utf8', stdio: 'pipe' }).trim()
  const sessionID = `ses_cleanup_${Date.now()}`
  const tasks = path.join(root, '.git/opencode-tasks')
  const commands = new Map<string, any>()
  let notes: string[] = []
  const write = async (sid: string, state: any) => {
    await mkdir(path.join(tasks, sid), { recursive: true })
    await writeFile(path.join(tasks, sid, 'state.json'), JSON.stringify({ sessionID: sid, name: sid, requirement: 'r', root, target: 'main', base: '', folder: path.join(tasks, sid), step: 4, status: 'done', ...state }))
  }
  try {
    git('init', '-b', 'main'); git('config', 'user.name', 'Test'); git('config', 'user.email', 'test@example.invalid')
    await writeFile(path.join(root, 'a.txt'), 'base'); git('add', '.'); git('commit', '-m', 'initial')
    // Merged leftover, worktree already gone: only the branch remains.
    git('branch', 'task/merged-leftover')
    const merged = git('rev-parse', 'task/merged-leftover')
    await write('ses_merged', { branch: 'task/merged-leftover', tree: path.join(root, 'gone'), commit: merged })
    // Branch whose commit never reached main.
    git('checkout', '-q', '-b', 'tmp-unmerged')
    await writeFile(path.join(root, 'b.txt'), 'x'); git('add', '.'); git('commit', '-m', 'only on branch')
    const unmerged = git('rev-parse', 'HEAD')
    git('branch', 'task/unmerged', unmerged); git('checkout', '-q', 'main')
    await write('ses_unmerged', { branch: 'task/unmerged', tree: path.join(root, 'gone2'), commit: unmerged })
    // Merged but its worktree still holds uncommitted work.
    const dirtyTree = path.join(path.dirname(root), `${path.basename(root)}-worktree`, 'dirty')
    git('worktree', 'add', '-b', 'task/dirty', dirtyTree)
    await writeFile(path.join(dirtyTree, 'wip.txt'), 'uncommitted')
    await write('ses_dirty', { branch: 'task/dirty', tree: dirtyTree, commit: git('rev-parse', 'task/dirty') })
    await plugin.setup({
      rpc: { register: async () => ({ events: { emit: async () => {} } }) },
      command: { transform: async (f: any) => f({ add: (c: any) => commands.set(c.name, c) }) },
      session: {
        get: async () => ({ location: { directory: root }, outcome: 'succeeded' }),
        synthetic: async ({ text }: any) => { notes.push(text) },
      },
    } as any)
    await commands.get('task-cleanup').execute({ sessionID, prompt: { text: '' } })
    expect(notes.at(-1)).toContain('可清理 分支 task/merged-leftover')
    expect(notes.at(-1)).toContain('提交未合并到 main')
    expect(notes.at(-1)).toContain('工作树有未提交文件')
    expect(notes.at(-1)).not.toContain('已完成清理')
    expect(git('branch', '--list', 'task/merged-leftover')).not.toBe('')
    await commands.get('task-cleanup').execute({ sessionID, prompt: { text: 'remove' } })
    expect(notes.at(-1)).toContain('已清理')
    expect(git('branch', '--list', 'task/merged-leftover')).toBe('')
    // Unmerged, dirty and running work is preserved.
    expect(git('branch', '--list', 'task/unmerged')).not.toBe('')
    expect(git('worktree', 'list', '--porcelain')).toContain(dirtyTree)
    expect(await readFile(path.join(dirtyTree, 'wip.txt'), 'utf8')).toBe('uncommitted')
    // Idempotent: the cleaned task is no longer offered, skipped ones stay listed.
    await commands.get('task-cleanup').execute({ sessionID, prompt: { text: '' } })
    expect(notes.at(-1)).not.toContain('可清理')
    expect(notes.at(-1)).toContain('提交未合并到 main')
  } finally {
    try { git('worktree', 'remove', '--force', path.join(path.dirname(root), `${path.basename(root)}-worktree`, 'dirty')) } catch {}
    await rm(path.join(path.dirname(root), `${path.basename(root)}-worktree`), { recursive: true, force: true })
    await rm(root, { recursive: true, force: true })
  }
}, 30000)

test('project settings default to repository name and support validated overrides', async () => {
  const root = await mkdtemp('/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/project-settings-')
  try {
    execFileSync('git', ['init', '-b', 'main'], { cwd: root, stdio: 'pipe' })
    expect((await settingsFor(root)).prefix).toBe(path.basename(root))
    expect((await settingsFor(root)).parent).toBe(path.join(path.dirname(root), `${path.basename(root)}-worktree`))
    await mkdir(path.join(root, '.opencode'))
    const file = path.join(root, '.opencode/task-workflow.json')
    await writeFile(file, JSON.stringify({ prefix: 'api', parent: '../trees', planDirectory: 'design/plans', models: { luna: { providerID: 'custom', id: 'coder' } } }))
    const settings = await settingsFor(root)
    expect(settings.parent).toBe(path.resolve(root, '../trees'))
    expect(settings.models.luna.id).toBe('coder')
    expect(settings.models.astra.id).toBe('gpt-6-astra')
    expect(settings.planDirectory).toBe('design/plans')
    expect(taskDirectory(settings, 'add-cache')).toBe(path.join(settings.parent, 'add-cache'))
    const { layout, ...legacy } = settings
    expect(taskDirectory(legacy, 'add-cache')).toBe(path.join(settings.parent, 'api-add-cache'))
    await writeFile(file, '{"planDirectory":"../outside"}')
    await expect(settingsFor(root)).rejects.toThrow('planDirectory')
    await writeFile(file, '{"prefix":"../outside"}')
    await expect(settingsFor(root)).rejects.toThrow('prefix')
    await writeFile(file, '{"models":{"luna":{"id":"coder"}}}')
    await expect(settingsFor(root)).rejects.toThrow('providerID')
  } finally { await rm(root, { recursive: true, force: true }) }
})

test('legacy stalled task resumes into review; incomplete review cannot finish and user interrupt stays stopped', async () => {
  const root = await realpath(await mkdtemp('/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/review-recovery-'))
  const git = (...args: string[]) => execFileSync('git', args, { cwd: root, encoding: 'utf8', stdio: 'pipe' }).trim()
  const tree = `${root}-tree`, sessionID = `ses_review_${Date.now()}`
  let outcome = 'succeeded', directory = root, calls = 0
  const selected: string[] = [], commands = new Map<string, any>()
  let finish!: (text: string) => void
  const finished = new Promise<string>(resolve => { finish = resolve })
  try {
    git('init', '-b', 'main'); git('config', 'user.name', 'Test'); git('config', 'user.email', 'test@example.invalid')
    await writeFile(path.join(root, 'feature.txt'), 'base')
    git('add', '.'); git('commit', '-m', 'initial')
    const base = git('rev-parse', 'HEAD')
    git('worktree', 'add', '-b', 'task/review', tree)
    const folder = path.join(root, '.git/opencode-tasks', sessionID)
    await mkdir(folder, { recursive: true })
    await writeFile(path.join(folder, 'plan.md'), 'Complete save flow')
    await writeFile(path.join(folder, 'state.json'), JSON.stringify({ sessionID, name: 'review', requirement: 'save flow', root, target: 'main', base, branch: 'task/review', tree, folder, step: 2, status: 'running', worktreeCreated: true,
      continuation: { step: 2, rounds: 15, stalled: 1, corrections: 0, failures: 0, next: 'Run manual TUI acceptance' } }))
    await plugin.setup({
      rpc: { register: async () => ({ events: { emit: async () => {} } }) },
      command: { transform: async (f: any) => f({ add: (command: any) => commands.set(command.name, command) }) },
      session: {
        get: async () => ({ location: { directory }, outcome }),
        move: async (input: any) => { directory = input.directory },
        wait: async () => {}, switchAgent: async () => {},
        switchModel: async (input: any) => { selected.push(input.model.id) },
        synthetic: async ({ text }: any) => { if (text.includes('工作流暂停')) finish(text) },
        prompt: async ({ text }: any) => {
          calls++
          const state = JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8'))
          const { token, stage, path: file } = state.activeReceipt
          if (calls === 1) {
            expect(text).toContain('本轮是 Luna 收尾审查')
            // The old completion marker alone must not approve a review.
            await writeFile(file, JSON.stringify({ token, stage, status: 'completed' }))
          } else if (calls === 2) {
            expect(text).toContain('本轮是 Luna 收尾审查')
            await writeFile(file, JSON.stringify({ token, stage, status: 'progress', remainingRequired: ['save mutation missing'], next: 'Implement save mutation in feature.txt and run save test' }))
          } else {
            expect(text).toContain('save mutation missing')
            outcome = 'interrupted'
          }
        },
      },
    } as any)
    await commands.get('task-resume').execute({ sessionID })
    expect(await finished).toContain('interrupted')
    expect(selected).toEqual(['gpt-5.6-luna', 'gpt-5.6-luna', 'gpt-5.6-luna'])
    expect(calls).toBe(3)
    const state = JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8'))
    expect(state.step).toBe(2)
    expect(state.status).toBe('blocked')
    expect(git('rev-parse', 'HEAD')).toBe(base)
  } finally {
    try { git('worktree', 'remove', '--force', tree) } catch {}
    await rm(root, { recursive: true, force: true })
  }
}, 30000)
