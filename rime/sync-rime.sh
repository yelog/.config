#!/bin/bash
# sync-rime.sh — 同步 Rime 配置和用户词典到 Hamster (iPhone)
# 手动执行：~/.config/rime/sync-rime.sh
# 自动执行：crontab 每 30 分钟调用

set -uo pipefail

LOG="$HOME/.config/rime/sync.log"
RIME_DIR="$HOME/.config/rime"
HAMSTER_DIR="$HOME/Library/Mobile Documents/iCloud~dev~fuxiao~app~hamsterapp/Documents/RIME/Rime"
SYNC_DIR="$HOME/Library/Mobile Documents/iCloud~dev~fuxiao~app~hamsterapp/Documents/sync"
USERDB="$SYNC_DIR/squirrel_yelog/wanxiang.userdb.txt"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

# 检查是否手动执行（有终端输出）
is_manual() { [[ -t 1 ]]; }

log "=== sync started ==="

# 1. 检查用户词典导出状态
if [[ -f "$USERDB" ]]; then
    # 获取 userdb.txt 的最后修改时间
    db_mtime=$(stat -f %m "$USERDB")
    now=$(date +%s)
    age_hours=$(( (now - db_mtime) / 3600 ))

    if is_manual && [[ $age_hours -gt 1 ]]; then
        echo "⚠️  用户词典已 ${age_hours} 小时未导出"
        echo "   请先点击菜单栏 Squirrel → 同步用户数据"
        echo ""
    fi
fi

# 2. 推送配置到 Hamster iCloud 目录
if [[ -d "$HAMSTER_DIR" ]]; then
    rsync -av --delete \
        --exclude='*.userdb' \
        --exclude='*.userdb.*' \
        --exclude='build/' \
        --exclude='*.gram' \
        --exclude='*.bin' \
        --exclude='sync/' \
        --exclude='installation.yaml' \
        --exclude='user.yaml' \
        --exclude='.git' \
        --exclude='.gitignore' \
        --exclude='sync-rime.sh' \
        --exclude='sync.log' \
        "$RIME_DIR/" "$HAMSTER_DIR/" >> "$LOG" 2>&1 \
        && log "config synced to hamster" \
        || log "config sync failed"

    if is_manual; then
        echo "✅ 配置已同步到 Hamster"
    fi
else
    log "hamster icloud dir not found, skipping"
    if is_manual; then
        echo "❌ Hamster iCloud 目录不存在，请先在 iPhone 端开启 iCloud 同步"
    fi
fi

log "=== sync done ==="

tail -500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
