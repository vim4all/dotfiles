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
| `prefix + n` / `C-n` | New session |
| `prefix + t` / `C-t` | New window |
| `prefix + q` / `C-q` | Kill session |
| `prefix + C-d` | Detach client |
| `prefix + r` | Reload config |
| `prefix + D` | Open dev layout (runs `~/.tmux/dev_1.sh`) |

### Panes

| Key | Action |
|-----|--------|
| `prefix + g` / `C-g` | Split vertically (side by side) |
| `prefix + h` / `C-h` | Split horizontally (top/bottom) |
| `prefix + w` / `C-w` | Kill pane |
| `prefix + D` | Dev layout at current path |

### Navigation

| Key | Action |
|-----|--------|
| `Alt+Arrow` | Move between panes (no prefix) |
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
