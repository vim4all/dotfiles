#!/bin/bash
# Fuzzy-pick a file under the current pane's directory and open it in $EDITOR.
# Used by the tmux popup on prefix + f.
command -v fzf >/dev/null || { echo "fzf is not installed:  sudo apt install fzf"; read -rn1; exit 1; }
FD=$(command -v fdfind || command -v fd)
if [ -n "$FD" ]; then
  list() { "$FD" --type f --hidden --exclude .git; }
else
  list() { find . -type f -not -path '*/.git/*' | sed 's|^\./||'; }
fi
file=$(list | fzf --prompt 'edit> ' --preview 'head -120 {}') || exit 0
exec ${EDITOR:-nvim} "$file"
