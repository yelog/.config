#!/bin/bash
# sync-rime.sh — 自动推送配置到 Hamster iCloud 目录
# 由 crontab 每 30 分钟定时调用

set -uo pipefail

LOG="$HOME/.config/rime/sync.log"
RIME_DIR="$HOME/.config/rime"
HAMSTER_DIR="$HOME/Library/Mobile Documents/iCloud~dev~fuxiao~app~hamsterapp/Documents/RIME/Rime"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

log "=== sync started ==="

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
        --exclude='sync-to-hamster.sh' \
        --exclude='sync.log' \
        "$RIME_DIR/" "$HAMSTER_DIR/" >> "$LOG" 2>&1 \
        && log "config synced to hamster" \
        || log "config sync failed"
else
    log "hamster icloud dir not found, skipping"
fi

log "=== sync done ==="

tail -500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
