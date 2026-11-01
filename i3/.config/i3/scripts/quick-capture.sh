#!/bin/bash
# Quick capture ($mod+n): type a line in rofi, it's appended to the Obsidian
# inbox (99_Input/Inbox.md) with a timestamp.
VAULT="$HOME/Documents/RemoteKnowledgeBase"
INBOX="$VAULT/99_Input/Inbox.md"

text=$(rofi -dmenu -p "capture" -lines 0 -mesg "→ 99_Input/Inbox.md")
[ -z "$text" ] && exit 0

mkdir -p "$(dirname "$INBOX")"
[ -f "$INBOX" ] || printf '# Inbox\n\n' > "$INBOX"
printf -- '- %s %s\n' "$(date '+%Y-%m-%d %H:%M')" "$text" >> "$INBOX"
notify-send -a "Obsidian" -t 2000 "Captured" "$text"
