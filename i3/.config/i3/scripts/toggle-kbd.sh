#!/bin/bash
STATE_FILE="/tmp/i3-kbd-layout"
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "us")

if [ "$CURRENT" = "us" ]; then
    NEW="ua"
else
    NEW="us"
fi

setxkbmap "$NEW"
echo "$NEW" > "$STATE_FILE"
killall -SIGUSR1 i3status
