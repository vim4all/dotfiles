#!/usr/bin/env python3
"""Claude Code status line: model · context · project/branch · 5h / weekly limits.

Reads the status-line JSON from stdin (https://code.claude.com/docs/en/statusline).
Example:  Opus 5.5 · ctx 34% · myproj  main · 5h 12% · week 69% ↻ 21h50m
"""
import json
import os
import subprocess
import sys
import time

# Catppuccin Mocha, matching tmux / i3
C = {
    "text":  (205, 214, 244),
    "dim":   (108, 112, 134),
    "blue":  (137, 180, 250),
    "mauve": (203, 166, 247),
    "green": (166, 227, 161),
    "yellow": (249, 226, 175),
    "red":   (243, 139, 168),
}


def col(name: str, s: str) -> str:
    r, g, b = C[name]
    return f"\033[38;2;{r};{g};{b}m{s}\033[0m"


def level(pct: float) -> str:
    return "red" if pct >= 85 else "yellow" if pct >= 60 else "green"


def until(epoch: float) -> str:
    secs = max(int(epoch - time.time()), 0)
    d, rem = divmod(secs, 86400)
    h, rem = divmod(rem, 3600)
    m = rem // 60
    return f"{d}d{h}h" if d else f"{h}h{m:02d}m"


def branch(cwd: str) -> str:
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "branch", "--show-current"],
            capture_output=True, text=True, timeout=1,
        )
        return out.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}

    parts = []

    model = (data.get("model") or {}).get("display_name")
    if model:
        parts.append(col("mauve", model))

    ctx = (data.get("context_window") or {}).get("used_percentage")
    if ctx is not None:
        parts.append(col("dim", "ctx ") + col(level(ctx), f"{ctx:.0f}%"))

    cwd = data.get("cwd") or (data.get("workspace") or {}).get("current_dir") or os.getcwd()
    where = col("blue", os.path.basename(cwd.rstrip("/")) or "/")
    br = branch(cwd)
    if br:
        where += " " + col("dim", f" {br}")
    parts.append(where)

    limits = data.get("rate_limits") or {}
    for key, label in (("five_hour", "5h"), ("seven_day", "week")):
        win = limits.get(key) or {}
        pct = win.get("used_percentage")
        if pct is None:
            continue
        seg = col("dim", f"{label} ") + col(level(pct), f"{pct:.0f}%")
        if key == "seven_day" and win.get("resets_at"):
            seg += col("dim", f" ↻ {until(win['resets_at'])}")
        parts.append(seg)

    print(col("dim", " · ").join(parts))


if __name__ == "__main__":
    main()
