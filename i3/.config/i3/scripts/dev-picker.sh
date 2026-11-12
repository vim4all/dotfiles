#!/bin/bash
# Pick a project with rofi and open it in a tmux dev workspace in a new terminal.
#   dev-picker.sh [--tty] [lite|claude|gemini|plain]   (default: lite)
# --tty: pick with fzf in the current terminal and attach right there (over
#        SSH, e.g. from the phone; `dev` in bash, also run at SSH login).
#        Keys: Enter open · Ctrl+r claude --continue · Ctrl+k kill session
# List, top to bottom:
#   ● session  ·  folder      running tmux sessions
#   DCR/DCR_ESP32_Telemetry   ~/wrk_dir/<group>/<project> (those without a session)
#   ~/some/other/dir          zoxide's frecent folders outside that list
# Keys:
#   Enter  — open (attach if it's a running session)
#   Ctrl+r — open a new workspace with `claude --continue` (r = resume)
#   Ctrl+o — open the folder (or the session's folder) in VimCommander (rofi only)
#   Ctrl+k — kill the selected session (asks first)
# Ctrl, not Alt, so the same keys work in fzf from the phone (no Alt key there).
# A session that is already on screen gets focused; new terminals open on the
# dev workspaces (2: dev main screen, 1: dev left, 3: ref — two per workspace, first free).
TTY=0
[ "$1" = "--tty" ] && { TTY=1; shift; }
MODE="${1:-lite}"
WS="$HOME/.config/tmux_workspaces/dev_${MODE}.sh"

say() { if [ $TTY = 1 ]; then echo "dev: $*" >&2; else notify-send "dev-picker" "$*"; fi; }

[ -f "$WS" ] || { say "unknown mode: $MODE"; exit 1; }
WRK="$HOME/wrk_dir"

short() { local p="$1"; p="${p#$WRK/}"; [ "$p" = "$1" ] && p="${1/#$HOME/\~}"; printf '%s' "$p"; }

# Folders under ~/wrk_dir that are worth listing: group/project, or a top-level
# folder that is itself a project (EVerest) — but not its source subfolders.
is_project() {
  local d="$1"
  [ -e "$d/.git" ] || [ -f "$d/CMakeLists.txt" ] || [ -f "$d/platformio.ini" ] ||
  [ -f "$d/Makefile" ] || [ -f "$d/pyproject.toml" ] || [ -f "$d/package.json" ]
}
projects() {
  local top d
  for top in "$WRK"/*/; do
    top="${top%/}"
    case "$(basename "$top")" in build|.*|_*) continue ;; esac
    if is_project "$top"; then echo "$top"; continue; fi
    for d in "$top"/*/; do
      d="${d%/}"
      [ -d "$d" ] && case "$(basename "$d")" in build|.*|_*) ;; *) echo "$d" ;; esac
    done
  done
}

declare -A SESSION_DIR
while IFS=$'\t' read -r s p; do SESSION_DIR["$s"]="$p"; done \
  < <(tmux list-sessions -F $'#S\t#{session_path}' 2>/dev/null)

choice=$(
  {
    # Running sessions; drop the folders they cover from the lists below
    declare -A seen=(["$HOME"]=1 ["$WRK"]=1)
    for s in "${!SESSION_DIR[@]}"; do
      printf '● %s  ·  %s\n' "$s" "$(short "${SESSION_DIR[$s]}")"
    done | sort -k2
    for s in "${!SESSION_DIR[@]}"; do seen["${SESSION_DIR[$s]}"]=1; done

    while read -r d; do
      [ -n "${seen[$d]}" ] && continue; seen["$d"]=1; short "$d"; echo
    done < <(projects)

    # Frecent folders elsewhere (skip /, /home, /tmp and the group folders)
    n=0
    while read -r d; do
      [ -n "${seen[$d]}" ] && continue
      [ -d "$d" ] || continue
      case "$d" in
        /|/home|/tmp|/tmp/*) continue ;;
        "$WRK"/*/*) ;;              # deeper than a group folder: keep
        "$WRK"/*) continue ;;       # a group folder (DCR, univ, …): skip
      esac
      seen["$d"]=1; short "$d"; echo
      n=$((n + 1)); [ $n -ge 15 ] && break
    done < <(zoxide query -l 2>/dev/null)
  } | if [ $TTY = 1 ]; then
    # fzf; map its --expect keys onto rofi's custom-key exit codes
    out=$(fzf --reverse --no-sort --prompt "dev-$MODE ▸ " --expect ctrl-r,ctrl-k \
              --header "Enter open · ^R continue · ^K kill · Esc shell") || exit 1
    key=$(head -1 <<<"$out"); sel=$(sed -n 2p <<<"$out")
    printf '%s' "$sel"
    case "$key" in ctrl-r) exit 10 ;; ctrl-k) exit 12 ;; *) exit 0 ;; esac
  else
    rofi -dmenu -i -p "dev-$MODE" \
      -mesg "Enter: open  ·  Ctrl+r: claude --continue  ·  Ctrl+o: VimCommander  ·  Ctrl+k: kill session" \
      -kb-remove-to-eol "" \
      -kb-custom-1 "Control+r" -kb-custom-2 "Control+o" -kb-custom-3 "Control+k" -no-show-icons
  fi
)
rc=$?
case $rc in 0|10|11|12) ;; *) exit 0 ;; esac
[ -z "$choice" ] && exit 0

session=""
if [[ "$choice" == "● "* ]]; then
  session="${choice#● }"; session="${session%%  ·  *}"
  dir="${SESSION_DIR[$session]}"
elif [[ "$choice" == "~"* || "$choice" == /* ]]; then
  dir="${choice/#\~/$HOME}"
else
  dir="$WRK/$choice"
fi

# Ctrl+k: kill a session, then show the picker again
if [ $rc -eq 12 ]; then
  [ -z "$session" ] && { say "kill only works on a running session (●)"; exit 0; }
  if [ $TTY = 1 ]; then
    read -rp "kill session $session? [y/N] " ok </dev/tty
  else
    ok=$(printf 'no\nyes, kill %s\n' "$session" | rofi -dmenu -i -p "kill session $session?" -no-show-icons)
  fi
  [[ "$ok" == [yY]* ]] && tmux kill-session -t "=$session"
  exec "$0" $([ $TTY = 1 ] && echo --tty) "$MODE"
fi

[ -d "$dir" ] || { say "not a directory: $dir"; exit 1; }

CONT=(); [ $rc -eq 10 ] && CONT=(-c)

# Terminal mode: attach in this terminal (switch if already inside tmux)
if [ $TTY = 1 ]; then
  if [ -n "$session" ]; then
    if [ -n "$TMUX" ]; then exec tmux switch-client -t "=$session"; fi
    exec tmux attach -t "=$session"
  fi
  cd "$dir" && exec bash "$WS" "${CONT[@]}" "$dir"
fi

# Ctrl+o: VimCommander
[ $rc -eq 11 ] && exec "$HOME/.local/bin/vimcommander" "$dir"

# the terminal may not pass i3's environment through, so set PATH explicitly
ENVPATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

SESSIONS="$HOME/.config/i3/scripts/sessions.py"

# Running session already on screen → focus that terminal instead of opening another
[ -n "$session" ] && "$SESSIONS" focus "$session" && exit 0

# New terminals go to the dev workspaces: 1, then 2, then 3, two per workspace
# (see sessions.py pick-ws). Switch there first so the window opens in place.
ws=$("$SESSIONS" pick-ws 2>/dev/null)
[ -n "$ws" ] && i3-msg -q "workspace --no-auto-back-and-forth \"$ws\""

# Running session → just attach
[ -n "$session" ] && exec ~/.config/i3/scripts/term.sh env PATH="$ENVPATH" tmux attach -t "=$session"

exec ~/.config/i3/scripts/term.sh -d "$dir" \
  env PATH="$ENVPATH" bash "$WS" "${CONT[@]}" "$dir"
