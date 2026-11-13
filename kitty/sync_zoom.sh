#!/bin/bash
NVIM=/Users/yelog/software/neovim/nvim-macos-arm64/bin/nvim

# Get the source tab layout, window count, and its Kitty window PIDs before toggling.
TAB_INFO=$(kitty @ ls 2>/dev/null | /usr/bin/python3 -c "
import json, os, sys

source_id = os.environ.get('KITTY_WINDOW_ID')
for os_window in json.loads(sys.stdin.read()):
    for tab in os_window.get('tabs', []):
        windows = tab.get('windows', [])
        if source_id:
            source = next((window for window in windows if str(window['id']) == source_id), None)
            if source is None:
                continue
        else:
            if not tab.get('is_active'):
                continue
            source = next((window for window in windows if window.get('is_active')), None)

        pids = [str(window['pid']) for window in windows if window.get('pid')]
        source_pid = str(source.get('pid', '')) if source else ''
        print('|'.join((tab.get('layout', ''), str(len(windows)), ','.join(pids), source_pid)))
        raise SystemExit
" 2>/dev/null)

IFS='|' read -r BEFORE WINDOW_COUNT WINDOW_PIDS SOURCE_PID <<EOF
$TAB_INFO
EOF

is_descendant() {
    local current_pid=$1
    local ancestor_pid=$2
    while [ -n "$current_pid" ] && [ "$current_pid" -gt 1 ] 2>/dev/null; do
        if [ "$current_pid" = "$ancestor_pid" ]; then
            return 0
        fi
        current_pid=$(ps -o ppid= -p "$current_pid" 2>/dev/null | tr -d ' ')
    done
    return 1
}

if [ -n "$SOURCE_PID" ]; then
    for server in /tmp/nvim-*/*; do
        [ -S "$server" ] || continue
        is_descendant "$(basename "$server")" "$SOURCE_PID" || continue
        handled=$("$NVIM" --server "$server" --remote-expr \
            "luaeval('require(\"custom.igit_terminal\").toggle_maximize() and 1 or 0')" 2>/dev/null)
        if [ "$handled" = 1 ]; then
            exit 0
        fi
    done
fi

# With one Kitty window, leave Kitty unchanged but still toggle Neovim's own zoom.
if [ "${WINDOW_COUNT:-0}" -lt 2 ]; then
    REMOTE_COMMAND='<cmd>lua SmartZoom()<CR>'
else
    if [ -n "$KITTY_WINDOW_ID" ]; then
        kitty @ action --match "id:$KITTY_WINDOW_ID" toggle_layout stack 2>/dev/null
    else
        kitty @ action toggle_layout stack 2>/dev/null
    fi

    # Determine action from the state BEFORE toggle.
    if [ "$BEFORE" = "splits" ]; then
        ACTION=zoom
    else
        ACTION=unzoom
    fi
    REMOTE_COMMAND="<cmd>lua SmartZoom('${ACTION}')<CR>"
fi

# Send only to Neovim instances descended from a window in the source Kitty tab.
# Kitty may report a shell PID rather than Neovim's PID, so direct PID matching is
# insufficient when Neovim was launched from a shell.
OLD_IFS=$IFS
IFS=','
for window_pid in $WINDOW_PIDS; do
    [ -n "$window_pid" ] || continue
    for s in /tmp/nvim-*/*; do
        [ -S "$s" ] || continue

        process_pid=$(basename "$s")
        if is_descendant "$process_pid" "$window_pid"; then
            "$NVIM" --server "$s" --remote-send "$REMOTE_COMMAND" 2>/dev/null
        fi
    done
done
IFS=$OLD_IFS
