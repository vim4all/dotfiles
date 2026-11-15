# i3 · Catppuccin Mocha

i3 setup for the ThinkPad: Catppuccin Mocha colors, rofi launchers, tmux dev
workspaces, Obsidian overlay. Reload after edits with `Alt + Shift + C`.

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

Keyboard layouts `us,ua` (Super+Space toggles), `dex` autostart, monitors/autorandr,
`xss-lock` + `i3lock`, `nm-applet`, `dunst`, `picom`, `feh`, rclone mount of
`gdrive:` at `~/GoogleDrive`.

## Keybindings

`Alt` = `Mod1`, so the same keys work with GlazeWM (Windows) and AeroSpace (macOS).
`Super + Space` switches keyboard layout us ↔ ua.

### Apps & workflow

| Binding | Action |
|---------|--------|
| `Alt + Enter` | terminal: kitty (gnome-terminal on VNC `:1` or if kitty fails) |
| `Alt + D` | rofi app launcher |
| `Alt + Tab` | rofi window switcher |
| `Alt + P` | project picker → **dev-lite** (claude + shell) |
| `Alt + Shift + P` | project picker → dev-claude (full layout: nvim + claude + repl) |
| `Alt + O` | Obsidian overlay (show/hide) |
| `Alt + N` | quick capture → `99_Input/Inbox.md` |
| `Alt + C` | VimCommander (two-pane file manager) |
| `Alt + F8` | Bluetooth menu |
| `Alt + \`` | toggle layout us ↔ ua |
| `Print` / `Alt + Print` | flameshot area / full screen |
| `Alt + Shift + X` | lock screen |
| `Alt + F9` / `F10` | unmount / mount Google Drive |
| `Alt + Shift + Q` | close window |

In the project picker: running tmux sessions are listed first (`● name`, Enter
attaches); on a folder, `Enter` opens a new workspace and `Ctrl + R` opens it
with `claude --continue`; `Ctrl + O` opens the folder (or the session's folder) in VimCommander;
`Ctrl + K` kills the session (asks first).

### VNC fallbacks (Super is grabbed by the VNC client)

With i3 on `Alt` the VNC client no longer grabs the WM key; these stay as a fallback.

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
| `Alt + H J K L` / arrows | focus |
| `Alt + Shift + H J K L` / arrows | move window |
| `Alt + B` / `V` | split horizontal / vertical |
| `Alt + F` | fullscreen |
| `Alt + S` / `W` / `E` | stacking / tabbed / toggle split |
| `Alt + Shift + Space` | toggle floating |
| `Alt + Space` | focus tiling ↔ floating |
| `Alt + A` | focus parent |
| `Alt + R` | resize mode (`HJKL`/arrows, `Enter`/`Esc` to exit) |
| `Alt + -` / `Alt + Shift + -` | scratchpad show / move to scratchpad |

### Workspaces

| Binding | Action |
|---------|--------|
| `Alt + 1 – 0` | switch to workspace 1–10 |
| `Alt + Shift + 1 – 0` | move window to workspace 1–10 |

### Media & i3

| Binding | Action |
|---------|--------|
| Volume / mute / mic-mute keys | `pactl` ±5% / toggle |
| Brightness keys | `xbacklight` ±5 |
| `Alt + Shift + C` | reload config |
| `Alt + Shift + R` | restart i3 |
| `Alt + Shift + E` | exit i3 |

## Dependencies

```bash
sudo apt install i3 rofi dunst feh picom flameshot xss-lock i3lock \
                 network-manager-gnome pulseaudio-utils dex xbacklight \
                 autorandr rclone zoxide
# kitty: curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin  (→ ~/.local/kitty.app, linked in ~/.local/bin)
```
Fonts: JetBrainsMono Nerd Font.
