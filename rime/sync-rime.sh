#!/bin/bash
# sync-rime.sh — 同步 Rime 配置到 Hamster (iPhone)
# 用法：~/.config/rime/sync-rime.sh 或 rime-sync

set -uo pipefail

RIME_DIR="$HOME/.config/rime"
HAMSTER_DIR="$HOME/Library/Mobile Documents/iCloud~dev~fuxiao~app~hamsterapp/Documents/RIME/Rime"
SYNC_DIR="$HOME/Library/Mobile Documents/iCloud~dev~fuxiao~app~hamsterapp/Documents/sync"
USERDB="$SYNC_DIR/squirrel_yelog/wanxiang.userdb.txt"

# 检查用户词典导出状态
if [[ -f "$USERDB" ]]; then
    db_mtime=$(stat -f %m "$USERDB")
    now=$(date +%s)
    age_hours=$(( (now - db_mtime) / 3600 ))
    if [[ $age_hours -gt 1 ]]; then
        echo "⚠️  用户词典已 ${age_hours} 小时未导出"
        echo "   请先点击菜单栏 Squirrel → 同步用户数据"
        echo ""
    fi
fi

# 推送配置到 Hamster iCloud 目录
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
        "$RIME_DIR/" "$HAMSTER_DIR/" \
        && echo "✅ 配置已同步到 Hamster" \
        || echo "❌ 同步失败"
else
    echo "❌ Hamster iCloud 目录不存在，请先在 iPhone 端开启 iCloud 同步"
fi
