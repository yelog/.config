import { test, expect } from 'bun:test'
import { mkdtemp, readFile, writeFile, rm, realpath, mkdir } from 'node:fs/promises'
import { execFileSync } from 'node:child_process'
import path from 'node:path'
import plugin, { parseName } from './index'

test('name parsing tolerates wrappers without accepting arbitrary prose or paths', () => {
  for (const value of ['redis-pane', '`redis-pane`', '```text\nredis-pane\n```', '{"name":"redis-pane"}', 'task/redis-pane']) expect(parseName(value)).toBe('redis-pane')
  for (const value of ['请使用 redis-pane', '../redis-pane', '', '{"name":42}']) expect(parseName(value)).toBeUndefined()
})

test('four stages switch models, create worktree, commit, merge and return; missing receipt pauses and resumes', async () => {
  const temp = await realpath(await mkdtemp('/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/task-workflow-test-'))
  const git = (cwd: string, ...args: string[]) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: 'pipe' }).trim()
  git(temp, 'init', '-b', 'main'); git(temp, 'config', 'user.name', 'Workflow Test'); git(temp, 'config', 'user.email', 'test@example.invalid')
  await writeFile(path.join(temp, 'README.md'), 'base\n')
  git(temp, 'add', '.'); git(temp, 'commit', '-m', 'initial')
  const stem = path.basename(temp).toLowerCase()
  const occupied = path.join(path.dirname(temp), `lazydb-${stem}-2`)
  git(temp, 'branch', `task/${stem}`)
  await mkdir(occupied)
  let directory = temp, block = true
  let namingCalls = 0
  const commands = new Map<string, any>(), selected: string[] = []
  const sessionID = `ses_test_${Date.now()}`
  const folder = path.join(temp, '.git/opencode-tasks', sessionID)
  let resolveNote: (text: string) => void = () => {}
  const notification = () => new Promise<string>(resolve => { resolveNote = resolve })
  const ctx: any = {
    generate: { text: async ({ prompt, model }: any) => {
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
        if (block) { block = false; return }
        const match = /内容为 (\{[^\n]+\})。未完成/.exec(text)!
        const receipt = JSON.parse(match[1])
        const file = /最后写入回执 ([^\n]+)，内容为/.exec(text)![1]
        const artifact: any = { analyze: 'analysis.md', plan: 'plan.md', implement: 'implementation.md', integrate: 'integration.md' }
        await writeFile(path.join(folder, artifact[receipt.stage]), '# verified\n')
        if (receipt.stage === 'implement') await writeFile(path.join(directory, 'feature.txt'), 'implemented\n')
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
    expect(await done).toContain('工作流暂停')
    expect(JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8')).step).toBe(0)
    done = notification()
    await commands.get('task-resume').execute({ sessionID })
    expect(await done).toContain('已完成并合并')
    expect(selected).toEqual(['gpt-6-astra', 'gpt-6-astra', 'gpt-6-astra', 'gpt-5.6-luna', 'gpt-5.6-luna', 'gpt-5.6-luna'])
    expect(directory).toBe(temp)
    expect(await readFile(path.join(temp, 'feature.txt'), 'utf8')).toBe('implemented\n')
    expect(JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8')).status).toBe('done')
    expect(namingCalls).toBe(2)
    // Reproduce the user's partial manual repair: branch/tree exist but flags/name were omitted.
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
  } finally {
    try { git(temp, 'worktree', 'remove', '--force', path.join(path.dirname(temp), `lazydb-${stem}-3`)) } catch {}
    await rm(occupied, { recursive: true, force: true })
    await rm(temp, { recursive: true, force: true })
  }
}, 30000)
