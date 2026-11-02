#!/bin/sh
# Launch snap Firefox from any session, including the TigerVNC one.
#
# The VNC session runs i3 under `dbus-run-session` (private bus, so its dunst /
# notifications stay on the VNC display). Strictly-confined snaps must ask the
# systemd user manager — reachable only via the real user bus — to place them in
# a snap.firefox.* cgroup scope; from the private bus that fails with
# "... is not a snap cgroup for tag snap.firefox.firefox".
# Fix: point just this launch at the user bus. On :0 this is a no-op.
#
# Installed as ~/.local/bin/firefox (symlink) and used by the
# ~/.local/share/applications/firefox_firefox.desktop override.
USER_BUS="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus"
[ -S "$USER_BUS" ] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS"
exec /snap/bin/firefox "$@"
