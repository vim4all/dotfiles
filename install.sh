#!/bin/bash
# Set up these dotfiles on a machine (Ubuntu / Debian).
#   ./install.sh          link every package into $HOME with GNU Stow
#   ./install.sh --deps   also install apt packages, kitty and tmux's TPM first
#   ./install.sh i3 tmux  link only these packages
set -euo pipefail
cd "$(dirname "$(realpath "$0")")"

PACKAGES=(bash git i3 i3status dunst picom rofi kitty tmux tmux_workspaces claude vimcommander nvim)

DEPS=0
SEL=()
for a in "$@"; do
  case "$a" in
    --deps) DEPS=1 ;;
    -h|--help) sed -n 2,5p "$0"; exit 0 ;;
    *) SEL+=("$a") ;;
  esac
done
[ ${#SEL[@]} -gt 0 ] && PACKAGES=("${SEL[@]}")

if [ "$DEPS" = 1 ]; then
  sudo apt install -y stow git i3 rofi dunst feh picom flameshot xss-lock i3lock \
    network-manager-gnome pulseaudio-utils dex xbacklight autorandr rclone \
    tmux fzf fd-find ripgrep zoxide vifm xclip python3
  if ! command -v kitty >/dev/null; then
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    mkdir -p ~/.local/bin && ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
  fi
  [ -d ~/.tmux/plugins/tpm ] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

command -v stow >/dev/null || { echo "stow is missing: sudo apt install stow (or ./install.sh --deps)"; exit 1; }

# nvim is its own repo, included here as a submodule
git submodule update --init --recursive

# Stow refuses to overwrite real files; list conflicts first so nothing is lost
if ! stow --no --verbose=0 --target="$HOME" "${PACKAGES[@]}" 2>/tmp/stow-check.$$; then
  echo "These files already exist in \$HOME — move them away (or into the repo) and run again:"
  grep -E "existing target|cannot stow" /tmp/stow-check.$$ || cat /tmp/stow-check.$$
  rm -f /tmp/stow-check.$$
  exit 1
fi
rm -f /tmp/stow-check.$$
stow --restow --target="$HOME" "${PACKAGES[@]}"
echo "linked: ${PACKAGES[*]}"

# Local files that are not in the (public) repo
VC=vimcommander/.config/VimCommander
if [ -f "$VC/config.example.json" ] && [ ! -f "$VC/config.json" ]; then
  sed "s|@HOME@|$HOME|g" "$VC/config.example.json" > "$VC/config.json"
  echo "created VimCommander config from config.example.json"
fi
if [ ! -f "$HOME/.gitconfig.local" ]; then
  printf '[user]\n\tname = %s\n\temail = %s\n' "$(whoami)" "you@example.com" > "$HOME/.gitconfig.local"
  echo "created ~/.gitconfig.local — put your git name and e-mail there"
fi
# Snap Firefox can't start from the VNC session (private D-Bus); route it through
# i3/scripts/firefox.sh — via PATH and a launcher override (rofi, xdg-open)
SNAP_DESKTOP=/var/lib/snapd/desktop/applications/firefox_firefox.desktop
if [ -f "$SNAP_DESKTOP" ] && [ -x "$HOME/.config/i3/scripts/firefox.sh" ]; then
  mkdir -p ~/.local/bin ~/.local/share/applications
  ln -sfn "$HOME/.config/i3/scripts/firefox.sh" ~/.local/bin/firefox
  sed "s#^Exec=/snap/bin/firefox#Exec=$HOME/.local/bin/firefox#" "$SNAP_DESKTOP" \
    > ~/.local/share/applications/firefox_firefox.desktop
  echo "installed snap Firefox wrapper (VNC-safe)"
fi
# gnome-terminal is the VNC terminal (term.sh); give it kitty's font/theme
"$HOME/.config/i3/scripts/gnome-terminal-setup.sh" || true
echo "tmux plugins: open tmux and press prefix + I"
