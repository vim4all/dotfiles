#!/bin/bash
# Zoom the Claude pane while a phone (a narrow SSH client) looks at a window;
# unzoom it when the phone is gone. Run from tmux hooks (client-attached,
# client-detached, client-session-changed, client-resized, session-window-changed).
#
# A client counts as a phone when its tmux process came in over SSH
# (SSH_CONNECTION in its environment) and it's under PHONE_COLS wide — wide
# desktop kitty windows and narrow local splits are left alone.
# Windows zoomed here get @phone_zoom=1. Unzooming by hand on the phone
# (prefix z) is respected: the window isn't zoomed again until the phone leaves.
PHONE_COLS=120

phone_sessions=()
while read -r pid width session; do
  [ "$width" -lt "$PHONE_COLS" ] || continue
  tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -q '^SSH_CONNECTION=' || continue
  phone_sessions+=("$session")
done < <(tmux list-clients -F '#{client_pid} #{client_width} #{session_name}')

on_phone() { local s; for s in "${phone_sessions[@]}"; do [ "$s" = "$1" ] && return 0; done; return 1; }

# Zoom the current window of every session a phone is looking at
for s in "${phone_sessions[@]}"; do
  read -r win panes zoomed flag < <(tmux display-message -p -t "=$s:" \
    '#{window_id} #{window_panes} #{window_zoomed_flag} #{?@phone_zoom,1,0}')
  [ -n "$win" ] && [ "$panes" -gt 1 ] && [ "$zoomed" = 0 ] && [ "$flag" = 0 ] || continue
  # Prefer the pane running Claude, else the active one
  pane=$(tmux list-panes -t "$win" -F '#{pane_id} #{pane_current_command}' | awk '$2 == "claude" {print $1; exit}')
  [ -n "$pane" ] && tmux select-pane -t "$pane"
  tmux resize-pane -Z -t "${pane:-$win}"
  tmux set -w -t "$win" @phone_zoom 1
done

# Undo it where no phone is looking any more
tmux list-windows -a -F '#{session_name} #{window_id} #{window_zoomed_flag} #{?@phone_zoom,1,0}' |
while read -r s win zoomed flag; do
  [ "$flag" = 1 ] || continue
  on_phone "$s" && continue
  [ "$zoomed" = 1 ] && tmux resize-pane -Z -t "$win"
  tmux set -uw -t "$win" @phone_zoom
done
