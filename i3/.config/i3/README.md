# i3 · Catppuccin Mocha

i3 setup for the ThinkPad: Catppuccin Mocha colors, rofi launchers, tmux dev
workspaces, Obsidian overlay. Reload after edits with `Super + Shift + C`.

## Files

| Path | Purpose |
|------|---------|
| `config` | i3 — colors, gaps, keybindings, startup apps |
| `scripts/term.sh` | terminal launcher: kitty; gnome-terminal on VNC `:1` (no GPU) or as fallback (`-d DIR`, optional command) |
| `scripts/dev-picker.sh` | rofi project picker → tmux dev workspace (`~/.config/tmux_workspaces/dev_*.sh`) |
| `scripts/obsidian-toggle.py` | show/hide Obsidian as a centered scratchpad overlay |
| `scripts/quick-capture.sh` | rofi prompt → append a line to `99_Input/Inbox.md` in the vault |
| `scripts/i3status-bt.py` | bar status: i3status wrapper adding Bluetooth + layout blocks |
| `scripts/monitors.sh` | xrandr layout VGA → DP → LVDS (left to right) at login; links nouveau PRIME provider, detects output names |
| `scripts/rofi-bluetooth.sh` | rofi Bluetooth menu |
| `scripts/toggle-kbd.py` | toggle keyboard layout us ↔ ua (XKB) |
| `scripts/mount-gdrive.sh` | rclone mount of `~/GoogleDrive`, plus an optional shared drive from `~/.config/rclone/shared-drive.env` |

## Look

- Full Catppuccin Mocha palette as `$variables` at the top of `config`; accent is `$mauve`
- Gaps 4 px inner / 4 px outer, 4 px pixel borders, `smart_gaps` + `smart_borders`
- Font: JetBrainsMono Nerd Font 10
- Wallpaper via `feh`, compositor `picom` (skipped on VNC display `:1`)

## Startup

Keyboard layouts `us,ua` (Alt+Shift toggles), `dex` autostart, monitors/autorandr,
`xss-lock` + `i3lock`, `nm-applet`, `dunst`, `picom`, `feh`, rclone mount of
`gdrive:` at `~/GoogleDrive`.

## Keybindings

`Super` = `Mod4`.

### Apps & workflow

| Binding | Action |
|---------|--------|
| `Super + Enter` | terminal: kitty (gnome-terminal on VNC `:1` or if kitty fails) |
| `Super + D` | rofi app launcher |
| `Super + Tab` | rofi window switcher |
| `Super + P` | project picker → **dev-lite** (claude + shell) |
| `Super + Shift + P` | project picker → dev-claude (full layout: nvim + claude + repl) |
| `Super + O` | Obsidian overlay (show/hide) |
| `Super + N` | quick capture → `99_Input/Inbox.md` |
| `Super + C` | VimCommander (two-pane file manager) |
| `Super + F8` | Bluetooth menu |
| `Super + \`` | toggle layout us ↔ ua |
| `Print` / `Super + Print` | flameshot area / full screen |
| `Super + Shift + X` | lock screen |
| `Super + F9` / `F10` | unmount / mount Google Drive |
| `Super + Shift + Q` | close window |

In the project picker: running tmux sessions are listed first (`● name`, Enter
attaches); on a folder, `Enter` opens a new workspace and `Alt + C` opens it
with `claude --continue`; `Alt + V` opens the folder (or the session's folder) in VimCommander.

### VNC fallbacks (Super is grabbed by the VNC client)

| Binding | Action |
|---------|--------|
| `Ctrl + Alt + Enter` | terminal |
| `Ctrl + Alt + D` | rofi launcher |
| `Ctrl + Alt + Q` | close window |
| `Ctrl + Alt + P` / `Ctrl + Alt + Shift + P` | picker: lite / full |
| `Ctrl + Alt + O` | Obsidian overlay |

### Windows & layout

| Binding | Action |
|---------|--------|
| `Super + H J K L` / arrows | focus |
| `Super + Shift + H J K L` / arrows | move window |
| `Super + B` / `V` | split horizontal / vertical |
| `Super + F` | fullscreen |
| `Super + S` / `W` / `E` | stacking / tabbed / toggle split |
| `Super + Shift + Space` | toggle floating |
| `Super + Space` | focus tiling ↔ floating |
| `Super + A` | focus parent |
| `Super + R` | resize mode (`HJKL`/arrows, `Enter`/`Esc` to exit) |
| `Super + -` / `Super + Shift + -` | scratchpad show / move to scratchpad |

### Workspaces

| Binding | Action |
|---------|--------|
| `Super + 1 – 0` | switch to workspace 1–10 |
| `Super + Shift + 1 – 0` | move window to workspace 1–10 |

### Media & i3

| Binding | Action |
|---------|--------|
| Volume / mute / mic-mute keys | `pactl` ±5% / toggle |
| Brightness keys | `xbacklight` ±5 |
| `Super + Shift + C` | reload config |
| `Super + Shift + R` | restart i3 |
| `Super + Shift + E` | exit i3 |

## Dependencies

```bash
sudo apt install i3 rofi dunst feh picom flameshot xss-lock i3lock \
                 network-manager-gnome pulseaudio-utils dex xbacklight \
                 autorandr rclone zoxide
# kitty: curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin  (→ ~/.local/kitty.app, linked in ~/.local/bin)
```
Fonts: JetBrainsMono Nerd Font.
