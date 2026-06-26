#!/bin/bash
# watch-sync.sh — 监听 Rime 同步事件，自动推送配置到 Hamster
# 当用户点击「同步用户数据」时，userdb.txt 会更新，触发此脚本
# 用法：~/.config/rime/watch-sync.sh
# 停止：Ctrl+C 或 kill $(cat ~/.config/rime/watch-sync.pid)

set -uo pipefail

PID_FILE="$HOME/.config/rime/watch-sync.pid"
USERDB="$HOME/Library/Mobile Documents/iCloud~dev~fuxiao~app~hamsterapp/Documents/sync/squirrel_yelog/wanxiang.userdb.txt"
SYNC_SCRIPT="$HOME/.config/rime/sync-rime.sh"

# 保存 PID
echo $$ > "$PID_FILE"

# 记录初始的修改时间
last_mtime=$(stat -f %m "$USERDB" 2>/dev/null || echo 0)

echo "✅ 监听已启动 (PID: $$)"
echo "   监听文件: $USERDB"
echo "   停止: Ctrl+C 或 kill $$"
echo ""

while true; do
    sleep 2
    current_mtime=$(stat -f %m "$USERDB" 2>/dev/null || echo 0)

    if [[ "$current_mtime" != "$last_mtime" ]]; then
        echo "[$(date '+%H:%M:%S')] 🔄 检测到同步事件，开始推送配置..."
        "$SYNC_SCRIPT"
        last_mtime=$current_mtime
        echo "[$(date '+%H:%M:%S')] ✅ 推送完成，继续监听..."
        echo ""
    fi
done
