#!/bin/bash
# Make gnome-terminal match kitty: it is the terminal on the VNC display (:1),
# where kitty would render through software OpenGL (see term.sh).
# Applies to the "Catppuccin Mocha" profile (install it from
# https://github.com/catppuccin/gnome-terminal if missing) and makes it default.
set -euo pipefail
command -v dconf >/dev/null || { echo "dconf missing"; exit 1; }

BASE=/org/gnome/terminal/legacy
uuid=""
for p in $(dconf list "$BASE/profiles:/" | grep '^:' | tr -d ':/'); do
  if [ "$(dconf read "$BASE/profiles:/:$p/visible-name")" = "'Catppuccin Mocha'" ]; then
    uuid=$p; break
  fi
done
[ -n "$uuid" ] || { echo "Catppuccin Mocha profile not found — install it first"; exit 1; }

P="$BASE/profiles:/:$uuid"
dconf write "$P/use-system-font"     false
dconf write "$P/font"                "'JetBrainsMono Nerd Font Mono 11'"
dconf write "$P/scrollback-lines"    10000
dconf write "$P/audible-bell"        false
dconf write "$P/cursor-blink-mode"   "'off'"   # each blink is a VNC frame update
dconf write "$P/default-size-columns" 120
dconf write "$P/default-size-rows"   35
dconf write "$BASE/profiles:/default" "'$uuid'"
dconf write "$BASE/default-show-menubar" false
dconf write "$BASE/confirm-close"    false
echo "gnome-terminal: Catppuccin Mocha ($uuid) configured as default"
