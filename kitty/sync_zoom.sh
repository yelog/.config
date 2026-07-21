#!/bin/bash
NVIM=/Users/yelog/software/neovim/nvim-macos-arm64/bin/nvim

# Get the active tab layout, window count, and its Kitty window PIDs before toggling.
TAB_INFO=$(kitty @ ls 2>/dev/null | /usr/bin/python3 -c "
import json, sys

for os_window in json.loads(sys.stdin.read()):
    for tab in os_window.get('tabs', []):
        if not tab.get('is_active'):
            continue

        pids = [str(window['pid']) for window in tab.get('windows', []) if window.get('pid')]
        print('|'.join((tab.get('layout', ''), str(len(tab.get('windows', []))), ','.join(pids))))
        raise SystemExit
" 2>/dev/null)

IFS='|' read -r BEFORE WINDOW_COUNT WINDOW_PIDS <<EOF
$TAB_INFO
EOF

# With one Kitty window, leave Kitty unchanged but still toggle Neovim's own zoom.
if [ "${WINDOW_COUNT:-0}" -lt 2 ]; then
    REMOTE_COMMAND='<cmd>lua SmartZoom()<CR>'
else
    kitty @ action toggle_layout stack 2>/dev/null

    # Determine action from the state BEFORE toggle.
    if [ "$BEFORE" = "splits" ]; then
        ACTION=zoom
    else
        ACTION=unzoom
    fi
    REMOTE_COMMAND="<cmd>lua SmartZoom('${ACTION}')<CR>"
fi

# Send only to Neovim instances descended from a window in the active Kitty tab.
# Kitty may report a shell PID rather than Neovim's PID, so direct PID matching is
# insufficient when Neovim was launched from a shell.
OLD_IFS=$IFS
IFS=','
for window_pid in $WINDOW_PIDS; do
    [ -n "$window_pid" ] || continue
    for s in /tmp/nvim-*/*; do
        [ -S "$s" ] || continue

        process_pid=$(basename "$s")
        current_pid=$process_pid
        while [ -n "$current_pid" ] && [ "$current_pid" -gt 1 ] 2>/dev/null; do
            if [ "$current_pid" = "$window_pid" ]; then
                $NVIM --server "$s" --remote-send "$REMOTE_COMMAND" 2>/dev/null
                break
            fi
            current_pid=$(ps -o ppid= -p "$current_pid" 2>/dev/null | tr -d ' ')
        done
    done
done
IFS=$OLD_IFS
