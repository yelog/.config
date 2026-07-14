#!/bin/bash
NVIM=/Users/yelog/software/neovim/nvim-macos-arm64/bin/nvim

# Get current layout BEFORE toggle
BEFORE=$(kitty @ ls 2>/dev/null | /usr/bin/python3 -c "
import sys,json
for w in json.loads(sys.stdin.read()):
    for t in w.get('tabs',[]):
        if t.get('is_active'): print(t['layout'])
" 2>/dev/null)

# Toggle
kitty @ action toggle_layout stack 2>/dev/null

# Determine action from the state BEFORE toggle
if [ "$BEFORE" = "splits" ]; then
    ACTION=zoom
else
    ACTION=unzoom
fi

# Send to all neovim instances
for s in /tmp/nvim-*/*; do
    if [ -S "$s" ]; then
        pid=$(basename "$s")
        ps -p "$pid" > /dev/null 2>&1 || { rm -f "$s"; continue; }
        $NVIM --server "$s" --remote-send "<cmd>lua SmartZoom('${ACTION}')<CR>" 2>/dev/null
    fi
done
