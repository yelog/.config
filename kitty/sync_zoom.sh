#!/bin/bash
LOG=/tmp/sync-zoom.log
echo "=== $(date '+%H:%M:%S') ===" >> "$LOG"

# Find kitty socket
# When launched as background process, kitty inherits the RC socket on stdin/stdout
# So `kitty @` works without --to. Fall back to explicit socket path if needed.
KITTY_CMD="kitty @"
if ! $KITTY_CMD ls >/dev/null 2>&1; then
    SOCK=$(ls /tmp/kitty-* 2>/dev/null | head -1)
    if [ -n "$SOCK" ]; then
        KITTY_CMD="kitty @ --to $SOCK"
    else
        echo "ERROR: no kitty socket" >> "$LOG"
        exit 1
    fi
fi
echo "kitty_cmd=$KITTY_CMD" >> "$LOG"

# Layout BEFORE toggle
BEFORE=$($KITTY_CMD ls 2>/dev/null | python3 -c "
import sys,json
d=json.loads(sys.stdin.read())
for w in d:
    for t in w.get('tabs',[]):
        if t.get('is_active'): print(t['layout'])
" 2>/dev/null)
echo "layout_before=$BEFORE" >> "$LOG"

# Toggle kitty layout
$KITTY_CMD action toggle_layout stack 2>/dev/null

# Layout AFTER toggle
AFTER=$($KITTY_CMD ls 2>/dev/null | python3 -c "
import sys,json
d=json.loads(sys.stdin.read())
for w in d:
    for t in w.get('tabs',[]):
        if t.get('is_active'): print(t['layout'])
" 2>/dev/null)
echo "layout_after=$AFTER" >> "$LOG"

if [ "$AFTER" = "stack" ]; then
    ACTION="zoom"
else
    ACTION="unzoom"
fi
echo "action=$ACTION" >> "$LOG"

# Send to all neovim instances
for s in /tmp/nvim-*/*; do
    if [ -S "$s" ]; then
        # Skip stale sockets: check if owning PID is alive
        pid=$(basename "$s")
        if ! ps -p "$pid" > /dev/null 2>&1; then
            rm -f "$s"
            continue
        fi

        nvim --server "$s" --remote-send "<cmd>lua vim.fn.writefile({#vim.api.nvim_list_wins(), tostring(Snacks.zen.win ~= nil and Snacks.zen.win:valid())}, '/tmp/sync-pre.log')<CR>" 2>/dev/null
        sleep 0.1
        PRE=$(cat /tmp/sync-pre.log 2>/dev/null | tr '\n' ',')

        nvim --server "$s" --remote-send "<cmd>lua SmartZoom('${ACTION}')<CR>" 2>/dev/null
        sleep 0.5

        nvim --server "$s" --remote-send "<cmd>lua vim.fn.writefile({#vim.api.nvim_list_wins(), tostring(Snacks.zen.win ~= nil and Snacks.zen.win:valid())}, '/tmp/sync-post.log')<CR>" 2>/dev/null
        sleep 0.1
        POST=$(cat /tmp/sync-post.log 2>/dev/null | tr '\n' ',')

        echo "  socket=$s pre=[$PRE] post=[$POST]" >> "$LOG"
    fi
done
