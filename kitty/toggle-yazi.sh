#!/bin/bash

FOCUSED_YAZI=$(kitty @ ls 2>/dev/null | jq -r '.[].tabs[].windows[] | select(.is_focused == true and (.foreground_processes[0].cmdline | index("yazi"))) | .id' | head -1)

if [ -n "$FOCUSED_YAZI" ]; then
    kitty @ close-window --match "id:$FOCUSED_YAZI"
else
    kitty @ launch --type=overlay --cwd=current yazi
fi