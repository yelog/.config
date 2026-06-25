#!/bin/bash
# sync-to-hamster.sh — 将 Rime 配置同步到 Hamster (iPhone) 的 iCloud 目录
# 同步后在 iPhone 端 Hamster 中点击「重新部署」即可生效

set -euo pipefail

SRC="$HOME/.config/rime"
DST="$HOME/Library/Mobile Documents/iCloud~dev~fuxiao~app~hamsterapp/Documents/RIME/Rime"

if [[ ! -d "$DST" ]]; then
  echo "❌ Hamster iCloud 目录不存在: $DST"
  echo "   请先在 iPhone 端 Hamster 中开启 iCloud 同步"
  exit 1
fi

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
  "$SRC/" "$DST/"

echo ""
echo "✅ 配置已同步到 Hamster iCloud 目录"
echo "   请在 iPhone 端 Hamster 中点击「重新部署」生效"
