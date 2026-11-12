# dotfiles

My Linux workstation: **i3 + tmux + Claude Code + kitty**, with Obsidian for notes,
VimCommander for files and Tailscale to reach it all from the phone.
Catppuccin Mocha everywhere. Ubuntu 22.04 on a ThinkPad.

Managed with [GNU Stow](https://www.gnu.org/software/stow/). nvim is a git submodule
([Neovim_lua_config](https://github.com/vim4all/Neovim_lua_config)).

![Demo: pick a project, Claude edits the code, build, review and commit in a lazygit popup, then explore the project in VimCommander](docs/screenshots/demo.gif)

- [Quick start](#quick-start)
- [Screenshots](#screenshots)
- [How it fits together](#how-it-fits-together)
- [Cheat sheet](#cheat-sheet): [key rules](#key-rules) · [i3](#i3--super) · [project picker](#project-picker) · [tmux](#tmux--alt-and-prefix-ctrla) · [dev workspaces](#dev-workspaces) · [key cheat sheet](#key-cheat-sheet) · [Claude](#claude-code) · [kitty](#kitty) · [VimCommander](#vimcommander) · [Obsidian](#obsidian) · [bash](#bash) · [git](#git) · [ssh](#ssh) · [nvim](#nvim--leader-space)
- [Managing the dotfiles](#managing-the-dotfiles)
- [Packages](#packages)

---

## Quick start

```bash
git clone --recurse-submodules git@github.com:vim4all/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --deps      # apt packages, kitty, tmux TPM, then link everything
```

Then open tmux and press `Ctrl+a I` to install the tmux plugins, and log into i3.

| Command | Does |
|---|---|
| `./install.sh` | (re)link every package into `$HOME` |
| `./install.sh i3 kitty` | link only these packages |
| `./install.sh --deps` | install dependencies first |
| `sudo system/setup.sh` | the `/etc` settings stow can't link: zram swap, battery limit, Docker and journal log caps, keyboard, delta |

It also creates the [local files](#local-never-committed) that are not in this public repo.

`install.sh` never overwrites a real file: if one is in the way it lists it and stops.

---

## Screenshots

**Claude Code in a dev-lite session.** Claude makes the change and shows the diff. The status line
shows model, context, branch and usage limits.

![Claude Code editing src/pid.c with the diff panel open](docs/screenshots/claude-edit.png)

**VimCommander quick view** (`Ctrl+Q`, `zp` for plots): folder sunburst, CSV and LTspice plots,
STL and STEP models in 3D, firmware memory maps from a linker `.map` or ELF.

![VimCommander previews: sunburst, telemetry plot, 3D motor model, memory map](docs/screenshots/vimcommander-previews.png)

**The full layout** (`Super+Shift+P`): nvim, a shell and Claude in one window, plus repl and git windows.

![dev-claude layout: nvim, shell and Claude](docs/screenshots/full-layout.png)

<sub>Recorded in a throwaway demo home with a made-up firmware project; Claude's answers are real.</sub>

---

## How it fits together

```mermaid
flowchart LR
    subgraph i3["🪟 i3 (Super)"]
        P["Super+P<br/>project picker"]
        O["Super+O<br/>Obsidian overlay"]
        N["Super+N<br/>quick capture"]
        C["Super+C<br/>VimCommander"]
        T["Super+Enter<br/>kitty"]
    end

    P -->|Enter| LITE
    P -->|Ctrl+R| LITE
    P -->|Ctrl+O| VC
    C --> VC

    subgraph tmux["🖥 tmux session (in kitty)"]
        LITE["dev-lite<br/>Claude ▸ shell"]
        POP["popups<br/>Alt+G lazygit · Alt+O files · Alt+E vifm"]
        LITE -.-> POP
    end

    VC["📁 VimCommander"] -->|":dev / F9"| LITE
    VC -->|":obs"| OBS
    LITE -->|"Alt+V"| VC
    O --> OBS["📓 Obsidian vault"]
    N -->|"99_Input/Inbox.md"| OBS
    LITE -->|"claude-notes"| OBS

    PHONE["📱 iPhone (ish)"] -.->|"Tailscale SSH<br/>tmux attach"| tmux
    PHONE -.->|":share via Tailscale"| VC
```

**A typical day:** `Super+P` → pick a project → a tmux session opens with Claude on top
and a shell below. Git in a popup (`Alt+G`), files in a popup (`Alt+O`, `Alt+E`) or in
VimCommander (`Alt+V`). Ideas go to Obsidian with `Super+N`. After a reboot,
tmux restores every session and Claude continues its last conversation.

---

## Cheat sheet

### Key rules

Each modifier belongs to one layer, so the modifier tells you who handles the key.

| Modifier | Layer | For |
|---|---|---|
| `Super` | desktop (i3) | windows, workspaces, apps, system |
| `Alt` | terminal (tmux, no prefix) | moving between panes, and all my tools |
| `Ctrl+a`, then a key | tmux itself | sessions, windows, splits, copy mode |
| `Ctrl` | the app or picker in front | its own keys; picker actions (they work on the phone too) |

- `Shift` means *move*, *the other variant* or *careful*: `Super+Shift+H` moves a window, `Super+Shift+P` opens the full layout, `Super+Shift+Q` closes.
- The layers mirror each other: `Super+H J K L` / `Alt+H J K L` move between windows / panes; `Super+/` / `Alt+/` show this cheat sheet.
- The phone menu (`Ctrl+a m`) uses the same letters as the `Alt` keys.
- Left free on purpose: `Alt+F B D .` (bash word moves), `Alt+C` (fzf cd), `Alt+Shift` (keyboard layout).

### i3 · `Super`

**Apps**

| Key | Action |
|---|---|
| `Super+Enter` | terminal (kitty; gnome-terminal on VNC `:1` or if kitty fails) |
| `Super+D` / `Super+Tab` | app launcher / window switcher (rofi) |
| `Super+P` / `Super+Shift+P` | [project picker](#project-picker) → **dev-lite** / full layout |
| `Super+O` | Obsidian overlay, show / hide |
| `Super+N` | quick capture → `99_Input/Inbox.md` |
| `Super+C` | VimCommander |
| `Super+/` | key cheat sheet |

**Windows and workspaces**

| Key | Action |
|---|---|
| `Super+H J K L` / `+Shift` | focus / move (arrows work too) |
| `Super+1…0` / `+Shift` | go to / move window to workspace |
| `Super+Esc` | previous workspace (so does pressing the current workspace's number) |
| `Super+Shift+Q` | close window |
| `Super+F` | fullscreen |
| `Super+B` / `Super+V` | next window opens to the right / below |
| `Super+S` · `W` · `E` | stacking · tabbed · toggle split |
| `Super+Shift+Space` / `Super+Space` | float / unfloat · focus tiling ↔ floating |
| `Super+-` / `+Shift` | scratchpad: show / move window there |
| `Super+R` | resize mode (`H J K L`, `Esc` to leave) |

**System**

| Key | Action |
|---|---|
| `Super+Backspace` / `+Shift` / `+Ctrl` | notification: close / bring the last one back / close all |
| `Super+Shift+X` | lock (also after 10 min idle and on suspend) |
| `Super+F7` | re-apply monitor layout (after plugging monitors in or out) |
| `Super+F8` | Bluetooth menu |
| `Super+F9` / `Super+F10` | unmount / mount Google Drive |
| `Alt+Shift` or ``Super+` `` | keyboard layout us ↔ ua |
| `Print` / `Super+Print` | screenshot area / screen (flameshot) |
| `Super+Shift+C` · `R` · `E` | reload · restart · exit i3 |

Over VNC, put TigerVNC in fullscreen (`Ctrl+Alt+Enter`) so it passes every `Super` key through.

### Workspaces

Each workspace has a fixed job and monitor (VGA | DP main | laptop). Apps open on theirs automatically;
with fewer screens (undocked, VNC) everything falls back to the one available.

| Key | Workspace | Monitor | Auto-assigned |
|---|---|---|---|
| `Super+1` | `1: dev` | VGA (left) | |
| `Super+2` | `2: dev` | DP (main) | |
| `Super+3` | `3: ref` | laptop | |
| `Super+4` | `4: web` | DP | |
| `Super+5` | `5: chat` | laptop | Telegram, Discord, Thunderbird (tabbed; Telegram + Discord start at login) |
| `Super+6` | `6: media` | VGA | mpv, VLC, Spotify |
| `Super+7` | `7: eda` | DP | KiCad, STM32CubeMX |
| `Super+8` `9` | spare | any | |
| `Super+0` | `10: sys` | laptop | monitoring: btop, lazydocker |

Change the map in `i3/.config/i3/config` (`App → workspace` section); `xprop WM_CLASS` shows a window's class.

### Project picker

`Super+P` lists, top to bottom: running tmux sessions (`● name  ·  folder`), projects in `~/wrk_dir/<group>/`
(as `DCR/DCR_ESP32_Telemetry`), then up to 15 of zoxide's frecent folders.

| Key | Action |
|---|---|
| `Enter` | open: attach the session, or start a dev-lite workspace in the folder |
| `Ctrl+R` | the same with `claude --continue` (resume) |
| `Ctrl+O` | open the folder in VimCommander |
| `Ctrl+K` | kill the session (asks first) |

The terminal version, `dev` (opens by itself on an SSH login), has the same keys except `Ctrl+O`.
A session already on screen is focused, not opened twice. New terminals go to `2: dev` (main screen), then `1: dev`,
then `3: ref`, two per workspace.

### tmux · `Alt` and prefix `Ctrl+a`

**`Alt`: panes and my tools**

| Key | Action |
|---|---|
| `Alt+H J K L` / arrows | move between panes (into nvim splits too) |
| `Alt+T` | scratch shell popup |
| `Alt+G` | **lazygit** popup |
| `Alt+O` | **open a file**: fuzzy-pick it, edit it |
| `Alt+E` | **vifm** popup |
| `Alt+V` | **VimCommander** in this folder |
| `Alt+R` | **run a project script** (`run_*.sh`); `Alt+R` `Enter` repeats the last one |
| `Alt+S` | **serial monitor**: pick a port → picocom (`Ctrl+B Ctrl+X` quits) |
| `Alt+W` | Pomodoro timer |
| `Alt+N` | full dev layout in this folder |
| `Alt+/` | key cheat sheet |

Tools open in the pane's folder. Close a popup with `exit` / `q`, or hide it with `Ctrl+a Ctrl+d`
(scratch and Pomodoro keep running).

`Alt+R` finds `run_*.sh` in the pane's folder or a parent (else the session folder) and types it into the
window's idle shell pane (or a new one), so the output stays in view and Claude can read it.

**`Ctrl+a`, then:**

| Key | Action | | Key | Action |
|---|---|---|---|---|
| `t` | new window | | `g` / `h` | split side by side / top-bottom |
| `PgUp` / `PgDn` | previous / next window | | `j` `k` `←` `→` | select pane (no Alt needed) |
| `n` | new session | | `H J K L` | resize pane (repeatable) |
| `o` | **session switcher** (fuzzy) | | `w` | kill pane |
| `Ctrl+d` | detach | | `q` | kill session |
| `Enter` | copy mode (`v` select, `y` copy) | | `m` | phone menu |
| `Ctrl+s` / `Ctrl+r` | save / restore sessions | | `r` | reload config |
| `I` | install plugins (TPM) | | `?` | tmux's own key list |

Mouse works everywhere; selecting text copies it. Sessions are saved every 5 minutes and **restored after a
reboot**: Claude panes come back as `claude --continue`, and i3 reopens a terminal for every session that was
on screen, on the same workspace (`i3/.config/i3/scripts/sessions.py`). No need to start `tmux` by hand.

### Dev workspaces

```mermaid
flowchart TB
    subgraph lite["dev-lite (default · Super+P)"]
        direction TB
        L1["claude ~75%"] --- L2["shell ~25%"]
    end
    subgraph full["dev-claude (Super+Shift+P)"]
        direction TB
        subgraph w1["window 1: code"]
            direction LR
            F1["nvim<br/>+ terminal below"] --- F2["claude"]
        end
        w2["window 2: repl (ipython + shell)"]
        w3["window 3: git (lazygit)"]
        w4["window 4: openocd (if run_openocd.sh)"]
    end
```

| Command | Layout |
|---|---|
| `dev-lite [DIR]` | Claude + shell (lazygit via `Alt+G`) |
| `dev-claude [DIR]` | nvim + terminal + Claude, repl, git, openocd windows |
| `dev-plain [DIR]` | same without an AI pane |
| `dev-gemini [DIR]` | same with the Antigravity CLI |

Options: `-c` continue the last AI conversation · `DIR SESSION` custom session name ·
`-- ARGS` passed to the AI CLI (`dev-lite -- --model opus`). An existing session is just attached.

### Key cheat sheet

Forgot a key? **`Super+/`** (rofi) or **`Alt+/`** (tmux popup)
lists every i3 and tmux binding with a description and how often you've used it.
Type to search; in rofi, `Enter` runs an i3 binding.

Every key press is counted in `~/.local/state/keys/usage.log` (local, never committed).
To find bindings worth dropping:

| Command | Shows |
|---|---|
| `keys stats` | i3 + your tmux keys, least used first; red = never |
| `keys stats -u` | only the never-used ones |
| `keys stats -d 30` | the last 30 days |
| `keys stats -s` | also shell and git aliases, counted in bash history |

Descriptions live in the configs: a `#: text` line right above an i3 `bindsym`, and
`bind-key -N "text"` in tmux. A binding without one shows its command.

### Claude Code

| What | How |
|---|---|
| Claude with the Obsidian vault | `claude-notes` (vault rules in its `CLAUDE.md`) |
| Needs you / finished | desktop notification + bell → tmux window and i3 workspace get flagged |
| Which sessions wait | i3 bar, left: `⚠ name` needs a permission answer (red), `✓ name` finished (goes away once you focus it); click → jump to it |
| Full layout for this project | `Alt+N` in tmux (nvim + shell + Claude) |
| Status line | model · context % · project/branch · 5 h and weekly limits |
| Resume after reboot | automatic (tmux-resurrect → `claude --continue`) |
| From the phone | iSH → `ssh` over Tailscale → the picker opens by itself (see *Phone* below) |

### Phone (iSH over SSH)

- **Login opens the picker** (`dev`, the [project picker](#project-picker) in fzf): `Enter` open ·
  `Ctrl+R` resume Claude · `Ctrl+K` kill · `Esc` plain shell. Skip it once with `ssh -t host 'DEV_NO_PICKER=1 bash -l'`.
- **`Ctrl+a m` menu** for everything the `Alt` keys do (iOS has no Alt), same letters:
  `t` scratch · `g` lazygit · `o` open file · `e` vifm · `r` run script · `s` serial · `w` Pomodoro · `/` keys;
  then tmux: `z` zoom · `a` sessions · `n` next window · `d` detach.
- **Auto-zoom**: while an SSH client under 120 columns looks at a window, its Claude pane is zoomed;
  it unzooms when the phone detaches (`Ctrl+a z` on the phone keeps it unzoomed). tmux 3.2 has no
  hook for "the desktop is active again", so with both attached the desktop sees the zoom too.
- **Colours**: over SSH `TERM=xterm` (iSH) becomes `xterm-256color`.

### ESP-IDF via direnv

ESP32 projects have a `.envrc` with `use esp_idf`: `cd` in and `idf.py`, the Xtensa toolchain and OpenOCD
are on `PATH` (also for Claude in the dev-lite pane); `cd` out and they're gone. The first load caches the
environment per IDF commit (`~/.cache/direnv-esp-idf/`), so after that it's instant. New project:
`echo 'use esp_idf' > .envrc && direnv allow`. `.envrc` is in the global git ignore.

### kitty

| Key | Action |
|---|---|
| `Ctrl+Shift+C` / `Ctrl+Shift+V` | copy / paste |
| `Ctrl+=` / `Ctrl+-` / `Ctrl+0` | font bigger / smaller / reset |
| `Ctrl+click` | open link |
| `Ctrl+Shift+F5` | reload config |
| `Ctrl+Shift+A`, then `1` · `D` · `M` / `L` | background: solid · back to 93 % · more / less opaque |

### VimCommander

My additions on top of its [own keys](https://github.com/vim4all/VimCommander#key-reference):

| Key / command | Action |
|---|---|
| `F9` / `:dev` | dev-lite workspace in this folder |
| `:devc` | same with `claude --continue` |
| `F10` / `:lg` | lazygit in kitty |
| `:obs` | open the file in Obsidian |
| `S` | kitty here |
| `:share` | QR code for the phone: same Wi-Fi, or pick the `100.x` Tailscale address |
| bar | wrk_dir · Vault · Terminal · Claude |

### Obsidian

| What | How |
|---|---|
| show / hide | `Super+O` (centered overlay on any workspace) |
| capture a thought | `Super+N`, type, `Enter` → `99_Input/Inbox.md` with a timestamp |
| triage the inbox | `claude-notes`, then "sort my Inbox" |

### bash

| Command | Does |
|---|---|
| `z NAME` | jump to a frecent folder (zoxide) |
| `mkcd DIR` | create and enter |
| `extract FILE` | unpack any archive |
| `vifm` | file manager, cd to the last folder on exit |
| `ll` · `la` · `..` · `...` | listings, go up |
| `duh` · `path` · `week` | disk usage · PATH · ISO week |

Prompt: `path [branch ●] [venv] ❯`, history shared live between terminals,
`↑` / `↓` search history by the typed prefix. Start a command with a space to keep it
out of history.

**fzf**, anywhere at the prompt:

| Key | Does |
|---|---|
| `Ctrl+R` | fuzzy-search history, `Enter` puts the command on the prompt |
| `Ctrl+T` | insert a file path mid-command (`scp ` `Ctrl+T`), with a preview |
| `Alt+C` | cd into a subfolder |
| `**` `Tab` | fuzzy completion: `vim src/**`, `kill **`, `ssh **` |

`bat` and `fd` are Ubuntu's `batcat` and `fdfind`.

### git

| Alias | Does |
|---|---|
| `git st` · `git lg` · `git last` | short status · graph log · last commit with files |
| `git amend` · `git undo` · `git unstage F` | add to last commit · uncommit (keep changes) · unstage |
| `git wip` | commit everything as `wip` |
| `git ds` · `git recent` | side-by-side diff · branches by last commit |

Diffs go through [delta](https://github.com/dandavison/delta) when installed (`n` / `N`
jump between files), plain `less` otherwise. `pull` rebases with autostash, `push` goes
to the same-named branch, conflicts show the base (`diff3`) and `rerere` remembers
resolutions.

### ssh

Connections are reused for 10 minutes (a second `ssh`, `scp` or `git push` to the same
host starts instantly) and kept alive through Wi-Fi/Tailscale drops. Hosts go in
`~/.ssh/config.local`, which has a commented example for a board that gets reflashed.

### nvim · leader `Space`

| Key | Action |
|---|---|
| `Space ff` / `Space fg` | find files / live grep |
| `Space e` | file tree |
| `Space w` / `Space q` | save / quit |
| `Space gg` | Neogit |
| `Space rn` / `Space ca` / `Space cf` | rename / code action / format |
| `Space db` / `Space dc` | breakpoint / start debugging |

Full list in [nvim's README](nvim/.config/nvim/README.md#keymaps).

---

## Managing the dotfiles

Every config in `$HOME` is a **symlink into this repo**, so editing a config edits the repo.

```mermaid
flowchart LR
    A["edit ~/.config/i3/config"] --> B["~/dotfiles/i3/.config/i3/config<br/>(same file)"]
    B --> C["cd ~/dotfiles<br/>git add -A · commit · push"]
    C --> D["other machine:<br/>git pull (links are already there)"]
```

| Task | Commands |
|---|---|
| see what changed | `cd ~/dotfiles && git status` |
| save | `git add -A && git commit -m "…" && git push` |
| update another machine | `git pull --recurse-submodules` |
| add a new config | `mkdir -p btop/.config && mv ~/.config/btop btop/.config/ && stow btop` |
| unlink a package | `stow -D btop` |
| relink after a program replaced a link with a file | copy its changes into the repo, delete the file, `stow -R <package>` |

A new package also goes into `PACKAGES` in `install.sh` and the table below.

### nvim submodule

nvim keeps its own repository and history; this repo only records which commit to use.

```mermaid
sequenceDiagram
    participant N as nvim repo<br/>(nvim/.config/nvim)
    participant D as dotfiles repo
    N->>N: git commit -am "…"
    N->>N: git push
    D->>D: git add nvim/.config/nvim
    D->>D: git commit -m "nvim: bump"
```

```bash
cd ~/dotfiles/nvim/.config/nvim && git commit -am "…" && git push
cd ~/dotfiles && git add nvim/.config/nvim && git commit -m "nvim: bump"
git submodule update --remote nvim/.config/nvim     # pull the newest nvim config
```

---

## Packages

| Package | Links into `$HOME` | Contents |
|---|---|---|
| `bash` | `.bashrc`, `.profile` | shell options, prompt, aliases, `dev-*`, `claude-notes` |
| `git` | `.gitconfig`, `.config/git/ignore` | includes `~/.gitconfig.local` (name / e-mail, not in the repo); global ignores (`.envrc`, `settings.local.json`) |
| `i3` | `.config/i3/` | WM config + scripts (picker, Obsidian toggle, capture, terminal launcher, status) |
| `i3status` | `.config/i3status/` | bar blocks |
| `dunst` | `.config/dunst/` | notifications |
| `picom` | `.config/picom/` | compositor |
| `rofi` | `.config/rofi/` | launcher and picker theme |
| `kitty` | `.config/kitty/` | terminal (background 93 % opaque through picom) |
| `tmux` | `.config/tmux/`, `.tmux.conf` | tmux config, file picker script |
| `tmux_workspaces` | `.config/tmux_workspaces/` | dev workspace launchers, Pomodoro |
| `claude` | `.claude/settings.json`, `statusline.py`, `hooks/notify.py` | Claude Code settings |
| `vimcommander` | `.config/VimCommander/`, `.local/bin/vimcommander`, `.desktop` | VimCommander settings as `config.example.json`; `install.sh` makes `config.json` from it (app: [VimCommander](https://github.com/vim4all/VimCommander) in `~/src/VimCommander`) |
| `direnv` | `.config/direnv/lib/esp_idf.sh` | `use esp_idf` for `.envrc` files (cached ESP-IDF environment) |
| `vnc` | `.vnc/xstartup`, `.config/systemd/user/vncserver@.service` | TigerVNC session (i3) and a user unit to start it at boot: `systemctl --user enable --now vncserver@:1` + `loginctl enable-linger` |
| `ssh` | `.ssh/config` | generic defaults (connection reuse, keepalive); includes `~/.ssh/config.local` |
| `maint` | `.local/bin/pc-cleanup`, `pc-cleanup.timer` | monthly cleanup of unused Docker data, with a notification; `systemctl --user enable --now pc-cleanup.timer` |
| `keys` | `.local/bin/keys`, `keys-log` | key cheat sheet (`Super+/`, `Alt+/`) and usage counting (`keys stats`) |
| `nvim` | `.config/nvim/` | submodule → Neovim_lua_config |

### System settings (`system/`, not stowed)

Files under `/etc` belong to root, so `system/setup.sh` copies them in (with `sudo`; safe to run again):

| File | Does |
|---|---|
| `etc/default/zramswap` | ~8 GB compressed swap in RAM (zstd), so big builds slow down instead of being killed |
| `etc/udev/rules.d/90-battery-charge-limit.rules` | ThinkPad battery charges to 80 %, resumes below 75 % |
| `etc/docker/daemon.json` | container logs max 3 × 10 MB |
| `etc/systemd/journald.conf.d/size.conf` | system journal max 500 MB |

It also installs `ncdu` and [delta](https://github.com/dandavison/delta) (not packaged for Ubuntu 22.04),
sets the keyboard default to `us,ua` + `Alt+Shift` (a Bluetooth keyboard that reconnects would otherwise
come back as plain `us`) and keeps 2 snap revisions instead of 3.

### Local, never committed

This repo is public, so anything personal lives next to it, not in it:

| File | Holds | Created by |
|---|---|---|
| `~/.gitconfig.local` | git name and e-mail | `install.sh` (template) |
| `~/.config/VimCommander/config.json` | VimCommander settings + session state (open folders, history) | `install.sh`, from `config.example.json` |
| `~/.config/rclone/shared-drive.env` | optional shared Google Drive: `SHARED_DRIVE_ID`, `SHARED_MOUNT`, `SHARED_NAME` | you |
| `~/.config/rclone/rclone.conf` | Google tokens | `rclone config` |
| `~/.ssh/config.local` | your SSH hosts | `install.sh` (commented template) |
| `~/.vnc/passwd` | VNC password | `vncpasswd` |
| `~/.claude/.credentials.json`, `~/.claude.json`, history | Claude login and sessions | Claude Code |
| `**/.claude/settings.local.json` | per-project Claude permissions | Claude Code (git-ignored) |

Changed a VimCommander setting worth keeping? Copy it into `config.example.json`
(use `@HOME@` for your home folder). Before pushing, `git diff --cached` is the last check
that nothing personal slipped in.

tmux plugins come from TPM. Only the generic `~/.ssh/config` is in the repo: keys, hosts and `~/.gnupg` never are.
