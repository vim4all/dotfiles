#!/bin/bash
# System-level settings that stow can't link (they live in /etc, owned by root).
# Safe to run again: every step checks or overwrites with the same result.
#   sudo ~/dotfiles/system/setup.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run it with sudo"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
DELTA=0.20.1
step() { printf '\n\033[1;34m==\033[0m %s\n' "$*"; }

step "Packages: zram-tools (compressed swap), ncdu (disk usage)"
apt-get install -y -qq zram-tools ncdu >/dev/null

step "delta $DELTA (git diffs; not in Ubuntu 22.04, static musl build from GitHub)"
if ! delta --version 2>/dev/null | grep -q "$DELTA"; then
    t="$(mktemp -d)"
    curl -fsSL -o "$t/delta.deb" \
        "https://github.com/dandavison/delta/releases/download/$DELTA/git-delta-musl_${DELTA}_amd64.deb"
    dpkg -i "$t/delta.deb" >/dev/null
    rm -rf "$t"
fi
delta --version

step "Config files → /etc"
for f in default/zramswap docker/daemon.json udev/rules.d/90-battery-charge-limit.rules \
         systemd/journald.conf.d/size.conf; do
    install -Dm644 "$HERE/etc/$f" "/etc/$f" && echo "  /etc/$f"
done

step "Swap: zram"
systemctl restart zramswap
swapon --show

step "Battery: charge to 80 %, resume below 75 %"
udevadm control --reload
B=/sys/class/power_supply/BAT0
if [ -w "$B/charge_control_end_threshold" ]; then
    echo 80 >"$B/charge_control_end_threshold"
    echo 75 >"$B/charge_control_start_threshold"
    echo "  now: $(cat $B/charge_control_start_threshold)-$(cat $B/charge_control_end_threshold) %"
fi

step "Journal: max 500 MB"
systemctl restart systemd-journald

step "Keyboard: us,ua + Alt+Shift also for keyboards plugged in later (Bluetooth)"
sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="us,ua"/; s/^XKBOPTIONS=.*/XKBOPTIONS="grp:alt_shift_toggle"/' /etc/default/keyboard

step "Snap: keep 2 revisions"
snap set system refresh.retain=2

step "Docker: logs max 3 × 10 MB per container"
dockerd --validate --config-file /etc/docker/daemon.json
running="$(docker ps -q)"
systemctl restart docker
# containers with restart=unless-stopped come back by themselves; start the rest
# that were running (e.g. an emulator started with plain `docker run`)
[ -n "$running" ] && docker start $running >/dev/null
echo "  applies to containers created from now on; recreate running ones to pick it up"

printf '\n\033[1;32mdone\033[0m\n'
