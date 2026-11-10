#!/usr/bin/env python3
"""Claude Code hook: tell me when Claude needs input or has finished.

  notify.py notification  — desktop popup (notify-send) + terminal bell
  notify.py stop          — terminal bell only (turn finished)
  notify.py prompt        — I sent a prompt: Claude is working again
  notify.py tool          — a tool ran (so a permission prompt was answered)
  notify.py end           — the Claude session ended

The bell goes to Claude's terminal: inside tmux it flags the window in the
status bar, and gnome-terminal sets the urgency hint so i3 marks the workspace.

Each event also records the session's state for the i3 bar
(~/.config/i3/scripts/i3status-bt.py), one file per tmux pane in
~/.cache/claude-status/:  {"session", "pane", "project", "state", "since"}
  state: "ask"  — waiting for a permission answer / input
         "done" — turn finished, waiting for the next prompt
         "busy" — working
"""
import json
import os
import subprocess
import sys
import time

STATUS_DIR = os.path.expanduser("~/.cache/claude-status")


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


def tmux_session() -> str:
    pane = os.environ.get("TMUX_PANE")
    if not pane:
        return ""
    try:
        return subprocess.run(["tmux", "display-message", "-p", "-t", pane, "#S"],
                              capture_output=True, text=True, timeout=1).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


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


def status_file() -> str:
    pane = os.environ.get("TMUX_PANE", "")
    return os.path.join(STATUS_DIR, pane.lstrip("%") + ".json") if pane else ""


def read_state() -> str:
    try:
        with open(status_file()) as f:
            return json.load(f).get("state", "")
    except (OSError, ValueError):
        return ""


def set_state(state: str, cwd: str) -> None:
    """Record this pane's Claude state; only for Claude running inside tmux."""
    path = status_file()
    if not path:
        return
    if state == "":
        try:
            os.remove(path)
        except OSError:
            pass
        return
    session = tmux_session()
    if not session:
        return
    os.makedirs(STATUS_DIR, exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump({"session": session, "pane": os.environ["TMUX_PANE"],
                   "project": os.path.basename(cwd.rstrip("/")),
                   "state": state, "since": int(time.time())}, f)
    os.replace(tmp, path)


def main() -> None:
    event = sys.argv[1] if len(sys.argv) > 1 else "notification"
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}
    cwd = data.get("cwd") or os.getcwd()

    if event == "prompt":
        set_state("busy", cwd)
        return
    if event == "tool":
        if read_state() == "ask":  # the prompt was answered and the tool ran
            set_state("busy", cwd)
        return
    if event == "end":
        set_state("", cwd)
        return

    bell()
    if event != "notification":  # stop
        set_state("done", cwd)
        return

    kind = data.get("notification_type", "")
    if kind in ("permission_prompt", "agent_needs_input"):
        set_state("ask", cwd)
    urgency = "critical" if kind == "permission_prompt" else "normal"
    title = f"Claude · {where(cwd)}"
    body = data.get("message") or "Claude needs your attention"
    try:
        subprocess.run(["notify-send", "-a", "Claude Code", "-u", urgency, title, body],
                       timeout=3)
    except (OSError, subprocess.SubprocessError):
        pass


if __name__ == "__main__":
    main()
