#!/bin/bash
# Pick a serial port and open picocom on it in a new tmux window.
#   serial.sh PANE_PATH      (meant for a display-popup: Alt+s)
# Enter   → 115200 baud      Ctrl+b → choose another baud rate
# The window is named after the port; picocom's escape key is Ctrl+b
# (Ctrl+a is the tmux prefix): Ctrl+b Ctrl+x quits, Ctrl+b Ctrl+h shows help.
# When the port disappears (board unplugged) the window waits for Enter
# instead of closing, so the last output stays readable.
DIR="${1:-$HOME}"

ports() {
  local dev desc link
  for dev in /dev/ttyUSB* /dev/ttyACM*; do
    [ -e "$dev" ] || continue
    desc=""
    for link in /dev/serial/by-id/*; do
      [ "$(readlink -f "$link")" = "$dev" ] && desc="${link##*/}" && break
    done
    desc="${desc#usb-}"; desc="${desc%-if[0-9]*-port[0-9]*}"; desc="${desc%-if[0-9]*}"
    busy=""; fuser -s "$dev" 2>/dev/null && busy="  [in use]"
    printf '%-14s %s%s\n' "${dev#/dev/}" "$desc" "$busy"
  done
}

list=$(ports)
if [ -z "$list" ]; then
  echo "No serial ports (/dev/ttyUSB*, /dev/ttyACM*). Plug a board in and try again."
  read -rsn1 -t 5
  exit 0
fi

out=$(printf '%s\n' "$list" | fzf --reverse --prompt "serial ▸ " \
  --header "Enter: 115200   Ctrl+b: pick baud   (quit picocom: Ctrl+b Ctrl+x)" \
  --expect ctrl-b) || exit 0
key=$(head -1 <<<"$out")
port=$(sed -n 2p <<<"$out" | awk '{print $1}')
[ -n "$port" ] || exit 0

baud=115200
if [ "$key" = "ctrl-b" ]; then
  baud=$(printf '%s\n' 115200 9600 19200 38400 57600 74880 230400 460800 921600 1500000 2000000 |
    fzf --reverse --prompt "baud ▸ " --print-query | tail -1) || exit 0
  [[ "$baud" =~ ^[0-9]+$ ]] || exit 0
fi

tmux new-window -n "⚡$port" -c "$DIR" \
  "picocom -q -e b -b $baud /dev/$port; echo; read -rp '[picocom closed — Enter to close the window]'"
