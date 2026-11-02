#!/bin/bash
# Open a terminal.
#   :0 (real GPU)    → kitty, falling back to gnome-terminal if it fails to start
#   :1 (TigerVNC)    → gnome-terminal. There is no GPU there, so kitty renders
#                      through llvmpipe (software OpenGL); for 8 s of streaming
#                      output kitty cost ~27 CPU-s (~11 with LP_NUM_THREADS=1)
#                      vs ~3 CPU-s for gnome-terminal's CPU renderer.
#   term.sh [-d DIR] [CMD ARGS...]
KITTY="$HOME/.local/bin/kitty"
DIR=""
if [ "$1" = "-d" ]; then DIR="$2"; shift 2; fi

gterm() {
  if [ $# -gt 0 ]; then
    exec gnome-terminal ${DIR:+--working-directory="$DIR"} -- "$@"
  else
    exec gnome-terminal ${DIR:+--working-directory="$DIR"}
  fi
}

[ "$DISPLAY" = ":1" ] && gterm "$@"

if [ -x "$KITTY" ]; then
  start=$(date +%s)
  "$KITTY" ${DIR:+--directory "$DIR"} "$@"
  rc=$?
  # Ran fine, or the user simply used it for a while → done
  [ $rc -eq 0 ] || [ $(( $(date +%s) - start )) -ge 3 ] && exit $rc
  notify-send -u low "term" "kitty failed to start — using gnome-terminal"
fi

gterm "$@"
