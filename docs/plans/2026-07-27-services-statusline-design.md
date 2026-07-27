# Services Statusline Design

## Goal

Show managed-service state in Heirline, including the graceful shutdown wait
started by `Q`, without relying on Noice or command-area messages.

## Status Model

The central statusline component uses one highest-priority state:

| Priority | State | Text | Color |
| --- | --- | --- | --- |
| 1 | force closing | `! 正在强制关闭剩余服务` | red |
| 2 | closing | `◒ 关闭中 2/3 · 1.2s` | orange |
| 3 | starting | `◔ 启动中 1` | blue |
| 4 | failed | `× 服务启动失败` | red |
| 5 | running | `● 运行中 2` | green |
| 6 | idle | `○ 服务未运行` | gray |

The component appears only after the session has registered a service. It is
placed after statusline alignment, ahead of navigation and file metadata, so
the exit explanation is prominent without displacing the mode or file context.

## Architecture

`services.lifecycle` publishes structured shutdown status instead of writing a
command-area message. `services.runtime` publishes a `ServicesStatusChanged`
user event whenever a service changes state. The Heirline component reads the
shutdown status first, then aggregates runtime services, and redraws on that
event.

The statusline is read-only: process control remains in the lifecycle and
runtime modules. Feedback is cleared after shutdown completion or escalation.

## Verification

Lifecycle tests verify status publication and clearing. A focused status-model
test verifies priority and text for idle, starting, running, failed, closing,
