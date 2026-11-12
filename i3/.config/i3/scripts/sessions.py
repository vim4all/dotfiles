#!/usr/bin/env python3
"""Bring back the terminals showing tmux sessions after a reboot.

tmux-resurrect/continuum restore the tmux *sessions*, but not the kitty
windows attached to them or the i3 workspace each one was on. This script:

  save     record which tmux session is shown on which i3 workspace
  restore  start tmux (continuum restores the sessions), then open one
           terminal per recorded session and move it to its workspace
  run      restore, then save every minute (started by i3 at login on :0)
  focus S  focus the terminal already showing session S (exit 1 if none)
  pick-ws  print the dev workspace a new session terminal should open on:
           the first of DEV_WORKSPACES with fewer than PER_WORKSPACE session
           terminals, else the one with the fewest (used by dev-picker.sh)

A terminal is matched to its session through the window title, which tmux
sets to "SESSION:WINDOW:NAME - ..." (set-titles on).
State: ~/.local/state/i3-sessions.json
"""
import fcntl
import json
import os
import re
import subprocess
import sys
import time

STATE = os.path.expanduser("~/.local/state/i3-sessions.json")
LOCK = os.path.expanduser("~/.local/state/i3-sessions.lock")
TERM = os.path.expanduser("~/.config/i3/scripts/term.sh")
TITLE_RE = re.compile(r"^([^:\s]+):\d+:")
BOOT_SESSION = "_boot"
SAVE_EVERY = 60
# Keep in sync with $ws1..$ws3 in the i3 config. Main screen (2) first, then left (1)
DEV_WORKSPACES = ["2: dev", "1: dev", "3: ref"]
PER_WORKSPACE = 2


def run(*cmd: str) -> str:
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def i3(cmd: str) -> None:
    subprocess.run(["i3-msg", "-q", cmd])


def tmux_sessions() -> set[str]:
    return set(run("tmux", "list-sessions", "-F", "#S").split())


def terminal_windows(node=None, ws="", out=None):
    """(con_id, workspace, session) for every window whose title names a tmux session."""
    if node is None:
        node, out = json.loads(run("i3-msg", "-t", "get_tree")), []
    if node.get("type") == "workspace":
        ws = node.get("name", "")
    if node.get("window") and not ws.startswith("__"):
        m = TITLE_RE.match(node.get("name") or "")
        if m:
            out.append((node["id"], ws, m.group(1)))
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        terminal_windows(child, ws, out)
    return out


def save() -> None:
    sessions = tmux_sessions()
    entries, seen = [], set()
    for _, ws, s in terminal_windows():
        if s in sessions and s not in seen:
            seen.add(s)
            entries.append({"workspace": ws, "session": s})
    if not entries:  # never replace a good layout with an empty one (logout, tmux down)
        return
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    tmp = STATE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(entries, f, indent=1)
    os.replace(tmp, STATE)


def start_tmux(wanted: set[str], timeout: float = 40) -> set[str]:
    """Make sure the tmux server is up; wait for continuum to restore the sessions."""
    if not tmux_sessions():
        # A server needs a session to live; continuum restores the rest on start
        subprocess.run(["tmux", "new-session", "-d", "-s", BOOT_SESSION])
    deadline = time.time() + timeout
    while time.time() < deadline:
        have = tmux_sessions()
        if wanted <= have:
            break
        time.sleep(1)
    subprocess.run(["tmux", "kill-session", "-t", "=" + BOOT_SESSION], capture_output=True)
    return tmux_sessions()


def restore() -> None:
    try:
        with open(STATE) as f:
            entries = json.load(f)
    except (OSError, ValueError):
        return
    have = start_tmux({e["session"] for e in entries})
    shown = {s for _, _, s in terminal_windows()}
    env = dict(os.environ)
    env["PATH"] = ":".join([os.path.expanduser("~/.local/bin"),
                            os.path.expanduser("~/.npm-global/bin"), env.get("PATH", "")])
    missing = []
    for e in entries:
        ws, s = e["workspace"], e["session"]
        if s not in have:
            missing.append(s)
            continue
        if s in shown:
            continue
        subprocess.Popen([TERM, "tmux", "attach", "-t", "=" + s], env=env,
                         start_new_session=True, stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL)
        # Wait for the window to show the session title, then put it in place
        for _ in range(60):
            time.sleep(0.25)
            win = next((cid for cid, _, t in terminal_windows() if t == s), None)
            if win:
                i3(f'[con_id={win}] move container to workspace "{ws}"')
                break
    if missing:
        subprocess.run(["notify-send", "-u", "low", "sessions",
                        "not restored by tmux: " + ", ".join(missing)])


def focus(session: str) -> bool:
    win = next((cid for cid, _, s in terminal_windows() if s == session), None)
    if win:
        i3(f"[con_id={win}] focus")
    return bool(win)


def pick_workspace() -> str:
    count = {ws: 0 for ws in DEV_WORKSPACES}
    for _, ws, _ in terminal_windows():
        if ws in count:
            count[ws] += 1
    for ws in DEV_WORKSPACES:
        if count[ws] < PER_WORKSPACE:
            return ws
    return min(DEV_WORKSPACES, key=lambda w: count[w])


def main() -> None:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "save"
    if cmd == "save":
        save()
    elif cmd == "restore":
        restore()
    elif cmd == "focus" and len(sys.argv) > 2:
        sys.exit(0 if focus(sys.argv[2]) else 1)
    elif cmd == "pick-ws":
        print(pick_workspace())
    elif cmd == "run":
        os.makedirs(os.path.dirname(LOCK), exist_ok=True)
        lock = open(LOCK, "w")
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            return  # already running (e.g. i3 restarted)
        time.sleep(3)  # let monitors.sh set up the outputs first
        restore()
        while True:
            time.sleep(SAVE_EVERY)
            save()
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
