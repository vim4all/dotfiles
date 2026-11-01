#!/bin/bash
# Pick a project with rofi and open it in a tmux dev workspace in a new terminal.
#   dev-picker.sh [lite|claude|gemini|plain]   (default: lite)
# Lists running tmux sessions (● …) first, then ~/wrk_dir/*/* project folders
# plus zoxide's frecent directories.
#   Enter  — open (attach if it's a running session)
#   Alt+c  — open a new workspace with `claude --continue`
#   Alt+v  — open the folder (or the session's folder) in VimCommander
MODE="${1:-lite}"
WS="$HOME/.config/tmux_workspaces/dev_${MODE}.sh"
[ -f "$WS" ] || { notify-send "dev-picker" "unknown mode: $MODE"; exit 1; }

choice=$(
  {
    tmux list-sessions -F '● #S' 2>/dev/null
    {
      zoxide query -l 2>/dev/null
      find "$HOME/wrk_dir" -mindepth 1 -maxdepth 2 -type d -not -name '.*' 2>/dev/null | sort
    } | awk -v home="$HOME" 'NF && !seen[$0]++ && $0 != home { sub("^" home, "~"); print }'
  } | rofi -dmenu -i -p "dev-$MODE" \
      -mesg "Enter: open   ·   Alt+c: claude --continue   ·   Alt+v: VimCommander" \
      -kb-custom-1 "Alt+c" -kb-custom-2 "Alt+v" -no-show-icons
)
rc=$?
CONT=()
case $rc in
  0)  ;;
  10) CONT=(-c) ;;
  11) ;;
  *)  exit 0 ;;
esac
[ -z "$choice" ] && exit 0

if [ $rc -eq 11 ]; then
  if [[ "$choice" == "● "* ]]; then
    dir=$(tmux display-message -p -t "=${choice#● }:" '#{session_path}' 2>/dev/null)
  else
    dir="${choice/#\~/$HOME}"
  fi
  [ -d "$dir" ] || { notify-send "dev-picker" "not a directory: $dir"; exit 1; }
  exec "$HOME/.local/bin/vimcommander" "$dir"
fi

# the terminal may not pass i3's environment through, so set PATH explicitly
ENVPATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

# Running session → just attach
if [[ "$choice" == "● "* ]]; then
  exec ~/.config/i3/scripts/term.sh env PATH="$ENVPATH" tmux attach -t "=${choice#● }"
fi

dir="${choice/#\~/$HOME}"
[ -d "$dir" ] || { notify-send "dev-picker" "not a directory: $dir"; exit 1; }

exec ~/.config/i3/scripts/term.sh -d "$dir" \
  env PATH="$ENVPATH" bash "$WS" "${CONT[@]}" "$dir"
