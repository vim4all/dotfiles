#!/bin/bash
# Mount Google Drive with rclone (remote "gdrive:") at ~/GoogleDrive, plus an
# optional shared drive configured in ~/.config/rclone/shared-drive.env:
#   SHARED_DRIVE_ID=...   SHARED_MOUNT="$HOME/Team"   SHARED_NAME="Team"
mkdir -p ~/GoogleDrive
fusermount -u ~/GoogleDrive 2>/dev/null

rclone mount gdrive: ~/GoogleDrive --vfs-cache-mode writes --daemon && \
  notify-send "Google Drive" "Personal drive mounted" --icon=drive-harddisk

ENV="$HOME/.config/rclone/shared-drive.env"
[ -f "$ENV" ] || exit 0
# shellcheck source=/dev/null
. "$ENV"
[ -n "${SHARED_DRIVE_ID:-}" ] && [ -n "${SHARED_MOUNT:-}" ] || exit 0
mkdir -p "$SHARED_MOUNT"
fusermount -u "$SHARED_MOUNT" 2>/dev/null
rclone mount gdrive: "$SHARED_MOUNT" \
  --drive-team-drive "$SHARED_DRIVE_ID" \
  --vfs-cache-mode writes \
  --daemon && \
  notify-send "Google Drive" "${SHARED_NAME:-Shared} drive mounted" --icon=drive-harddisk
