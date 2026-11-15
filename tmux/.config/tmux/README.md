# tmux config

Personal tmux configuration with a Catppuccin Mocha status bar, vi copy mode, and WSL2 clipboard support.

## Setup

Part of `~/dotfiles` (package `tmux`): `stow tmux` links `~/.config/tmux` and
`~/.tmux.conf`. Then install the plugins:

```
prefix + I
```

## Prefix

`Ctrl+a` (replaces default `Ctrl+b`)

## Key Bindings

### Sessions & Windows

| Key | Action |
|-----|--------|
| `prefix + C-n` | New session |
| `prefix + C-t` | New window |
| `prefix + q` / `C-q` | Kill session |
| `prefix + C-o` | Session switcher (tmux-sessionx) |
| `prefix + C-d` | Detach client |
| `prefix + R` | Reload config |

### Panes

| Key | Action |
|-----|--------|
| `prefix + C-g` | Split vertically (side by side) |
| `prefix + h` / `C-h` | Split horizontally (top/bottom) |
| `prefix + C-w` | Kill pane |
| `prefix + C-l` | Clear the screen (`C-l` alone moves to the right pane) |

### My tools (prefix + letter)

Rule: `prefix` + letter = my own tools; `prefix` + Ctrl+letter = tmux itself. tmux stays off `Alt`,
which belongs to the window manager (i3 / GlazeWM / AeroSpace). Full rules: the main README's *Key rules*.

| Key | Action |
|-----|--------|
| `prefix + t` | Scratch shell popup |
| `prefix + g` | lazygit popup |
| `prefix + o` | Fuzzy-pick a file and edit it |
| `prefix + e` | vifm popup |
| `prefix + v` | VimCommander in this folder |
| `prefix + r` | Run a project `run_*.sh` (last-run first: `prefix + r Enter` repeats) |
| `prefix + s` | Serial monitor |
| `prefix + w` | Pomodoro timer |
| `prefix + n` | Dev layout at current path |
| `prefix + /` | Key cheat sheet |
| `prefix + m` | Phone menu (the same tools full screen) |

### Navigation

| Key | Action |
|-----|--------|
| `C-h/j/k/l` | Move between panes and nvim splits (no prefix) |
| `prefix + j/k` | Move pane down/up |
| `prefix + Left/Right` | Move pane left/right |
| `PageUp/PageDown` | Previous/next window |

### Pane Resizing (repeatable)

| Key | Action |
|-----|--------|
| `prefix + H/L` | Resize left/right by 5 |
| `prefix + J/K` | Resize down/up by 5 |

### Copy Mode (vi)

| Key | Action |
|-----|--------|
| `prefix + Enter` | Enter copy mode |
| `v` | Begin selection |
| `C-v` | Rectangle toggle |
| `y` | Copy selection |
| `H` / `L` | Start / end of line |

Clipboard is piped to `clip.exe` for WSL2 system clipboard integration.

## Plugins

Managed via [TPM](https://github.com/tmux-plugins/tpm).

- **tmux-resurrect** — save/restore sessions (`prefix + C-s` / `prefix + C-r`); captures pane contents and vim/nvim sessions
- **tmux-continuum** — auto-save every 5 minutes, auto-restore on start
- **tmux-yank** — system clipboard integration
