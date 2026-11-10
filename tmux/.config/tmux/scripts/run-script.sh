#!/bin/bash
# Run one of the project's run_*.sh scripts in the window's shell pane.
#   run-script.sh WINDOW_ID PANE_PATH SESSION_PATH [build|flash|NAME]
# Without NAME: fzf picker (meant for a display-popup).
# The project dir is the nearest folder above PANE_PATH holding run_*.sh,
# falling back to SESSION_PATH. The command goes to the lowest idle shell pane
# of the window (dev-lite: the shell under claude); if there is none, a new
# pane is split off. Focus stays where it was, so Claude can read the output.
WIN="$1" PANE_PATH="$2" SESSION_PATH="$3" NAME="${4:-}"

msg() { tmux display-message -d 3000 "$*"; }

has_run() { compgen -G "$1/run_*.sh" >/dev/null; }

dir="$PANE_PATH"
while [ -n "$dir" ] && [ "$dir" != "/" ] && [ "$dir" != "$HOME" ] && ! has_run "$dir"; do
  dir=$(dirname "$dir")
done
has_run "$dir" || dir="$SESSION_PATH"
has_run "$dir" || { msg "no run_*.sh in $PANE_PATH or its parents"; exit 0; }

case "$NAME" in
  "")
    script=$(cd "$dir" && ls run_*.sh | sed 's/^run_//; s/\.sh$//' |
      fzf --prompt "run ▸ " --header "$dir" --reverse \
          --preview "sed -n '1,40p' '$dir/run_{}.sh'" --preview-window right,60%) || exit 0
    script="run_$script.sh" ;;
  build)
    script=run_build.sh; [ -f "$dir/$script" ] || script=run_rebuild.sh ;;
  *)
    script="run_$NAME.sh" ;;
esac
[ -f "$dir/$script" ] || { msg "$script not found in $dir"; exit 0; }

# Lowest pane in the window whose foreground process is a shell (= idle)
target=$(tmux list-panes -t "$WIN" -F '#{pane_top} #{pane_id} #{pane_current_command}' |
  awk '$3 ~ /^-?(bash|zsh|sh|fish)$/' | sort -n | tail -1 | cut -d' ' -f2)
if [ -z "$target" ]; then
  target=$(tmux split-window -d -v -l 30% -t "$WIN" -c "$dir" -P -F '#{pane_id}')
fi

here=$(tmux display-message -p -t "$target" '#{pane_current_path}')
if [ "$here" = "$dir" ]; then
  cmd="bash $script"
else
  cmd="cd $(printf '%q' "$dir") && bash $script"
fi
tmux send-keys -t "$target" "$cmd" C-m
msg "▶ $script"
