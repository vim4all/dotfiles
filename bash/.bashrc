# ~/.bashrc: executed by bash(1) for non-login shells.
#
# ══════════════════════════════════════════════════════════════════════════════
#  OVERVIEW
#  A lean, functional bash config. No frameworks, no plugins — just bash.
#
#  SHELL OPTIONS
#    globstar   — ** matches files recursively (ls **/*.c)
#    cdspell    — typo correction for cd (cd Docuemnts → Documents)
#    autocd     — type a directory path to enter it without typing 'cd'
#
#  HISTORY
#    100k entries, no duplicates, timestamped. Shared across all sessions
#    in real time via 'history -a; history -c; history -r' in PROMPT_COMMAND.
#
#  READLINE
#    Up/Down     — partial-string history search (type prefix, then arrow up)
#    Tab         — case-insensitive, single-press shows all options
#
#  PROMPT  →   path [branch ●] [venv]  ❯
#    branch      — current git branch (yellow)
#    ●           — dim dot when there are uncommitted changes
#    venv        — active Python virtualenv name (dim)
#    ❯           — green on success, red on non-zero exit code
#
#  ALIASES
#    ll          — long list with human-readable sizes
#    la          — same but includes hidden files
#    .. / ... / ....  — go up 1 / 2 / 3 directories
#    cls         — clear screen
#    path        — print $PATH one entry per line
#    duh         — disk usage of current directory, sorted by size
#    week        — print current ISO week number
#    rg          — ripgrep with --smart-case (case-insensitive unless uppercase)
#
#  FUNCTIONS
#    mkcd <dir>      — mkdir -p and cd into it in one step
#    extract <file>  — unpack any archive (tar.gz, zip, 7z, bz2, zst, …)
#    vifm            — open vifm and cd to the last visited directory on exit
#
#  TOOLS
#    zoxide      — smart cd replacement (use 'z' instead of 'cd')
#    lesspipe    — makes 'less' handle binary/compressed files gracefully
#
#  PATH  (in order of precedence)
#    ~/.local/bin · ~/.npm-global/bin · ~/.local/stm32cube/bin · system
# ══════════════════════════════════════════════════════════════════════════════

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ── Shell options ──────────────────────────────────────────────────────────────
# globstar  — enables ** for recursive globs (e.g. ls **/*.c)
# cdspell   — fixes minor typos in cd (e.g. cd Docuemnts works)
# autocd    — type a path alone to cd into it, no 'cd' needed
shopt -s histappend checkwinsize globstar cdspell autocd

# ── History ────────────────────────────────────────────────────────────────────
HISTCONTROL=ignoredups:erasedups   # no duplicate or space-prefixed entries
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT="%F %T  "           # timestamp each history entry

# ── Readline ───────────────────────────────────────────────────────────────────
# Up/down arrows do partial-string history search — type 'git' then press up
# to cycle only through past git commands.
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward'  2>/dev/null
bind 'set completion-ignore-case on'       # case-insensitive tab completion
bind 'set show-all-if-ambiguous on'        # single-tab shows all options
bind 'set mark-symlinked-directories on'   # append / to symlinked dirs

# ── Environment ────────────────────────────────────────────────────────────────
export EDITOR=nvim
export LESS='-RFXi --mouse'   # -R colors, -F quit if one screen, -X no clear, -i smart case
export LESSHISTFILE=/dev/null  # don't litter ~/.lesshst
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# chroot label (Debian)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# ── Colors ─────────────────────────────────────────────────────────────────────
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto --group-directories-first'
    alias grep='grep --color=auto'
fi

# ── Prompt ─────────────────────────────────────────────────────────────────────
# Format:  path [branch ●] [venv]  ❯
#   ●  — dim dot when repo has uncommitted changes
#   ❯  — green on success, red on non-zero exit
__build_ps1() {
    local exit_code=$?
    local reset='\[\033[00m\]'
    local blue='\[\033[38;2;137;180;250m\]'
    local yellow='\[\033[38;2;249;226;175m\]'
    local green='\[\033[38;2;166;227;161m\]'
    local red='\[\033[38;2;243;139;168m\]'
    local dim='\[\033[2m\]'

    local git_part=""
    local branch
    branch=$(git branch 2>/dev/null | grep '^\*' | sed 's/\* //')
    if [ -n "$branch" ]; then
        local dirty=""
        git status --porcelain 2>/dev/null | grep -q . && dirty="${dim} ●${reset}"
        git_part=" ${yellow} ${branch}${reset}${dirty}"
    fi

    local venv_part=""
    [ -n "$VIRTUAL_ENV" ] && venv_part=" ${dim}($(basename "$VIRTUAL_ENV"))${reset}"

    local arrow_color
    [ "$exit_code" -eq 0 ] && arrow_color=$green || arrow_color=$red

    PS1="${blue} \w${reset}${git_part}${venv_part} ${arrow_color}❯${reset} "
}

PROMPT_COMMAND="__build_ps1; history -a; history -c; history -r"

# ── Aliases ────────────────────────────────────────────────────────────────────
alias ll='ls -lhF'             # long list, human-readable sizes
alias la='ls -lhAF'            # same + hidden files
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias path='echo "$PATH" | tr : "\n"'   # print PATH one entry per line
alias duh='du -sh -- * | sort -h'       # disk usage of current dir, sorted
alias week='date +%V'                   # current ISO week number
alias rg='rg --smart-case'             # case-insensitive unless uppercase used

# ── Functions ──────────────────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }   # create dir and cd into it

# extract <file> — universal archive unpacker
extract() {
    case "$1" in
        *.tar.bz2)  tar xjf "$1"         ;;
        *.tar.gz)   tar xzf "$1"         ;;
        *.tar.xz)   tar xJf "$1"         ;;
        *.tar.zst)  tar --zstd -xf "$1"  ;;
        *.tar)      tar xf "$1"          ;;
        *.bz2)      bunzip2 "$1"         ;;
        *.gz)       gunzip "$1"          ;;
        *.zip)      unzip "$1"           ;;
        *.7z)       7z x "$1"            ;;
        *)          echo "Don't know how to extract '$1'" ;;
    esac
}

# vifm: cd to last visited directory on exit
vifm() {
    local tmp dir
    tmp=$(mktemp)
    command vifm --choose-dir "$tmp" "$@"
    dir=$(cat "$tmp")
    rm -f "$tmp"
    [ -d "$dir" ] && cd "$dir"
}

# ── Completions ────────────────────────────────────────────────────────────────
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# ── Tools ──────────────────────────────────────────────────────────────────────
eval "$(zoxide init bash)"
# direnv: per-project environments from .envrc (ESP32 projects: `use esp_idf`,
# see ~/.config/direnv/lib/esp_idf.sh). Messages are dimmed.
if command -v direnv >/dev/null; then
  export DIRENV_LOG_FORMAT=$'\e[2mdirenv: %s\e[0m'
  eval "$(direnv hook bash)"
fi

# ── Workspace aliases ──────────────────────────────────────────────────────────
alias dev-claude="bash $HOME/.config/tmux_workspaces/dev_claude.sh"
alias dev-gemini="bash $HOME/.config/tmux_workspaces/dev_gemini.sh"
alias dev-plain="bash $HOME/.config/tmux_workspaces/dev_plain.sh"
alias dev-lite="bash $HOME/.config/tmux_workspaces/dev_lite.sh"
# TigerVNC desktop :1 at 30 fps (FrameRate can't be changed at runtime; default 60)
alias vnc-start='vncserver :1 -FrameRate 30'
alias claude-notes='claude --add-dir ~/Documents/RemoteKnowledgeBase'   # Claude with Obsidian vault access

# ── PATH ───────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.local/stm32cube/bin:$PATH"

# kitty: remote hosts don't know TERM=xterm-kitty — use a generic one over ssh
[ "$TERM" = "xterm-kitty" ] && alias ssh='TERM=xterm-256color ssh'
