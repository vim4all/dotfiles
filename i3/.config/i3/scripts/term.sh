#!/bin/bash
# Open a terminal: kitty, falling back to gnome-terminal if kitty is missing or
# fails to start (e.g. a VNC display without OpenGL 3.3).
#   term.sh [-d DIR] [CMD ARGS...]
KITTY="$HOME/.local/bin/kitty"
DIR=""
if [ "$1" = "-d" ]; then DIR="$2"; shift 2; fi

if [ -x "$KITTY" ]; then
  start=$(date +%s)
  "$KITTY" ${DIR:+--directory "$DIR"} "$@"
  rc=$?
  # Ran fine, or the user simply used it for a while → done
  [ $rc -eq 0 ] || [ $(( $(date +%s) - start )) -ge 3 ] && exit $rc
  notify-send -u low "term" "kitty failed to start — using gnome-terminal"
fi

if [ $# -gt 0 ]; then
  exec gnome-terminal ${DIR:+--working-directory="$DIR"} -- "$@"
else
  exec gnome-terminal ${DIR:+--working-directory="$DIR"}
fi
