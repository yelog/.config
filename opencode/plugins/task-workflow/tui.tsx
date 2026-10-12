import { Plugin } from '@opencode/plugin/tui'
import { createEffect, createSignal, onCleanup, Show } from 'solid-js'
import { Workflow, isTerminalTaskStatus, progressSegments, progressState, terminalNotification, type TaskView, type StageKey } from './rpc.js'

const stageHue: Record<StageKey, 'cyan' | 'purple' | 'blue' | 'orange' | 'green'> = {
  analyze: 'cyan', plan: 'purple', implement: 'blue', integrate: 'orange', cleanup: 'green',
}

export default Plugin.define({
  id: 'local.task-workflow.tui',
  setup(context) {
    const rpc = context.client.rpc(Workflow)
    const observed = new Map<string, string>()
    const initialized = new Set<string>()
    const observeTerminal = async (sessionID: string) => {
      try {
        const session = context.data.session.get(sessionID)
        const response = await rpc.status({ sessionID }, { location: session?.location ?? context.location ?? context.data.location.default() }) as { task: TaskView | null }
        const task = response.task
        if (!task) return
        const previous = observed.get(sessionID)
        observed.set(sessionID, task.status)
        if (!initialized.has(sessionID)) { initialized.add(sessionID); return }
        if (isTerminalTaskStatus(task.status) && previous !== task.status) {
          const message = terminalNotification(task)
          await context.attention.notify({
            title: message.title,
            message: message.message,
            notification: { when: 'blurred' },
          })
        }
      } catch {
        // The progress bar's polling path remains responsible for reconnecting.
      }
    }
    const stopTerminalNotifications = context.data.listen(({ details }) => {
      if (details.type === 'session.execution.succeeded' || details.type === 'session.execution.failed' || details.type === 'session.execution.interrupted') {
        void observeTerminal(details.data.sessionID)
      }
    })
    const unregister = context.ui.slot({
      append: 'session.composer.top',
      render: (props) => {
        const [task, setTask] = createSignal<TaskView | null>(null)
        const [offline, setOffline] = createSignal(false)
        createEffect(() => {
          const sessionID = props.sessionID
          let disposed = false, busy = false
          setTask(null)
          const refresh = async () => {
            if (busy || disposed) return
            busy = true
            try {
              const session = context.data.session.get(sessionID)
              const response = await rpc.status({ sessionID }, { location: session?.location ?? context.location ?? context.data.location.default() }) as { task: TaskView | null }
              if (!disposed) { setTask(response.task); setOffline(false); void observeTerminal(sessionID) }
            } catch { if (!disposed) setOffline(true) }
            finally { busy = false }
          }
          const unsubscribe = rpc.events.on('updated', event => {
            if ((event.data as { sessionID: string }).sessionID === sessionID) void refresh()
          })
          // Live events do not replay after disconnects; periodic read reconciles state.
          const timer = setInterval(() => void refresh(), 3000)
          void refresh()
          onCleanup(() => { disposed = true; clearInterval(timer); unsubscribe() })
        })
        const waiting = () => offline() ? '状态连接中断' :
          context.data.session.permission.list(props.sessionID)?.length ? '等待授权' :
          context.data.session.form.list(props.sessionID)?.length ? '等待输入' : undefined
        return <Show when={task()}>{value => <box flexDirection="column" paddingLeft={1} paddingRight={1}>
          <text wrapMode="none">
            {progressSegments(value()).map((segment, index) => <>
              <span
                style={{
                  fg: segment.state === 'done' ? context.theme.hue.green[500] : segment.state === 'paused' ? context.theme.hue.orange[500] : segment.state === 'active' ? context.theme.hue[stageHue[segment.key]][500] : context.theme.text.subdued,
                  bold: segment.state === 'active' || segment.state === 'paused',
                  dim: segment.state === 'pending',
                }}
              >{segment.state === 'done' ? '✓' : segment.state === 'paused' ? '!' : segment.state === 'active' ? '●' : '○'} {segment.label}</span>
              {index < 4 && <span style={{ fg: context.theme.text.subdued }}> → </span>}
            </>)}
          </text>
          <text wrapMode="none">
            <span style={{ fg: context.theme.text.default }}>{value().name}</span>
            <span style={{ fg: context.theme.text.subdued }}> · {value().model} · </span>
            <span style={{ fg: value().status === 'done' ? context.theme.hue.green[500] : value().status === 'blocked' || !value().running ? context.theme.hue.orange[500] : value().review ? context.theme.hue.purple[500] : context.theme.hue.blue[500], bold: true }}>{progressState(value(), waiting())}</span>
            <span style={{ fg: context.theme.text.subdued }}> · 第 {value().rounds} 轮</span>
            <Show when={value().error || value().next}><span style={{ fg: context.theme.text.subdued }}> · {value().error ?? value().next}</span></Show>
          </text>
        </box>}</Show>
      },
    })
    return () => { stopTerminalNotifications(); unregister() }
  },
})
