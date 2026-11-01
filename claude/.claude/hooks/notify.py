#!/usr/bin/env python3
"""Claude Code hook: tell me when Claude needs input or has finished.

  notify.py notification  — desktop popup (notify-send) + terminal bell
  notify.py stop          — terminal bell only (turn finished)

The bell goes to Claude's terminal: inside tmux it flags the window in the
status bar, and gnome-terminal sets the urgency hint so i3 marks the workspace.
"""
import json
import os
import subprocess
import sys


def claude_tty() -> str:
    """Walk up from this hook to the first ancestor that has a terminal."""
    pid = os.getppid()
    for _ in range(6):
        try:
            out = subprocess.run(["ps", "-o", "tty=,ppid=", "-p", str(pid)],
                                 capture_output=True, text=True).stdout.split()
        except OSError:
            return ""
        if len(out) < 2:
            return ""
        tty, ppid = out
        if tty not in ("?", ""):
            return "/dev/" + tty
        pid = int(ppid)
    return ""


def bell() -> None:
    tty = claude_tty()
    if tty:
        try:
            with open(tty, "w") as f:
                f.write("\a")
        except OSError:
            pass


def where(cwd: str) -> str:
    name = os.path.basename(cwd.rstrip("/")) or cwd
    pane = os.environ.get("TMUX_PANE")
    if pane:
        try:
            sw = subprocess.run(["tmux", "display-message", "-p", "-t", pane, "#S:#W"],
                                capture_output=True, text=True, timeout=1).stdout.strip()
            if sw:
                return f"{name}  [{sw}]"
        except (OSError, subprocess.SubprocessError):
            pass
    return name


def main() -> None:
    event = sys.argv[1] if len(sys.argv) > 1 else "notification"
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}

    bell()
    if event != "notification":
        return

    kind = data.get("notification_type", "")
    urgency = "critical" if kind == "permission_prompt" else "normal"
    title = f"Claude · {where(data.get('cwd') or os.getcwd())}"
    body = data.get("message") or "Claude needs your attention"
    try:
        subprocess.run(["notify-send", "-a", "Claude Code", "-u", urgency, title, body],
                       timeout=3)
    except (OSError, subprocess.SubprocessError):
        pass


if __name__ == "__main__":
    main()
