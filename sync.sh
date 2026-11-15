#!/bin/bash
# Keep the three dotfiles repos (Linux, Windows, macOS) in step, side by side.
#   ./sync.sh           pull every repo found next to this one, then show what is not pushed
#   ./sync.sh --clone   also clone the repos that are missing
#   ./sync.sh --push    also push repos that have commits to push (clean ones only)
# The same script is in dotfiles (Linux) and dotfiles-macos; Windows has sync.ps1.
# Repos are looked up in the parent folder as linux|dotfiles, windows|dotfiles-windows,
# macos|dotfiles-macos. At the end it compares the window-manager keys of all three.
set -uo pipefail
here=$(cd "$(dirname "$(realpath "$0")")" && pwd)
root=$(dirname "$here")

CLONE=0 PUSH=0
for a in "$@"; do
  case "$a" in
    --clone) CLONE=1 ;;
    --push) PUSH=1 ;;
    -h|--help) sed -n 2,8p "$0"; exit 0 ;;
    *) echo "unknown option: $a"; exit 1 ;;
  esac
done

# (no associative arrays: macOS ships bash 3.2)
repo() { case $1 in linux) echo dotfiles ;; *) echo "dotfiles-$1" ;; esac; }
url() { echo "https://github.com/vim4all/$(repo "$1").git"; }
# New clones follow the naming already used here: short names (D:\...\dotfiles\linux)
# or repo names (~/dotfiles next to ~/dotfiles-macos)
case "$(basename "$here")" in linux|windows|macos) short=1 ;; *) short=0 ;; esac

for p in linux windows macos; do
  dir=""
  for n in "$p" "$(repo "$p")"; do [ -e "$root/$n/.git" ] && dir="$root/$n" && break; done
  if [ -z "$dir" ]; then
    if [ "$CLONE" = 1 ]; then
      n=$( [ $short = 1 ] && echo "$p" || repo "$p" )
      echo "── $p: cloning into $root/$n"
      git clone --recurse-submodules -q "$(url "$p")" "$root/$n" || continue
      dir="$root/$n"
    else
      echo "── $p: not found next to this repo (./sync.sh --clone)"
      continue
    fi
  fi
  echo "── $p: $dir"
  g() { git -C "$dir" "$@"; }
  g fetch -q --recurse-submodules=on-demand || { echo "   fetch failed"; continue; }
  if [ -n "$(g status --porcelain)" ]; then
    echo "   uncommitted changes — not pulled:"; g status --short | sed 's/^/     /'
  elif ! g rev-parse -q --verify '@{u}' >/dev/null; then
    echo "   branch has no upstream — not pulled"
  else
    g pull -q --ff-only --recurse-submodules || echo "   cannot fast-forward: merge or rebase by hand"
  fi
  if g rev-parse -q --verify '@{u}' >/dev/null; then
    read -r behind ahead < <(g rev-list --left-right --count '@{u}...HEAD')
    [ "$behind" -gt 0 ] && echo "   $behind commit(s) behind"
    if [ "$ahead" -gt 0 ]; then
      if [ "$PUSH" = 1 ] && [ -z "$(g status --porcelain)" ]; then
        g push -q && echo "   pushed $ahead commit(s)"
      else
        echo "   $ahead commit(s) to push"; g log --oneline '@{u}..HEAD' | sed 's/^/     /'
      fi
    fi
  fi
  # nvim is a submodule of the Linux repo with its own commits to push
  if [ "$p" = linux ] && [ -e "$dir/nvim/.config/nvim/.git" ]; then
    sub="$dir/nvim/.config/nvim"
    if git -C "$sub" rev-parse -q --verify '@{u}' >/dev/null; then
      n=$(git -C "$sub" rev-list --count '@{u}..HEAD')
      [ "$n" -gt 0 ] && echo "   nvim submodule: $n commit(s) to push (cd $sub && git push)"
    fi
  fi
done

# Do the Alt keys still match across i3, GlazeWM and AeroSpace?
for n in linux dotfiles; do
  if [ -f "$root/$n/tools/keymap-check.py" ] && command -v python3 >/dev/null; then
    echo; echo "── window-manager keys (tools/keymap-check.py --all for the full table)"
    python3 "$root/$n/tools/keymap-check.py" --root "$root" | tail -n 1
    break
  fi
done
