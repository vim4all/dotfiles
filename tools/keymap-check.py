#!/usr/bin/env python3
"""Compare the Alt keys of i3 (Linux), GlazeWM (Windows) and AeroSpace (macOS).

The three window managers should feel the same, so every Alt key should exist on
all three (or be known to be missing). This reads the three configs from the
three dotfiles repos side by side and prints the keys that differ.

    tools/keymap-check.py            keys missing on some platform
    tools/keymap-check.py --all      every Alt key with its command per platform
    tools/keymap-check.py --root D   repos are in D/{linux,windows,macos}
                                     (or D/dotfiles, D/dotfiles-windows, D/dotfiles-macos)

Standard library only (works with the system python on Ubuntu 22.04 and macOS).
"""
import argparse
import os
import re
import sys

NAMES = {"linux": ["linux", "dotfiles"], "windows": ["windows", "dotfiles-windows"],
         "macos": ["macos", "dotfiles-macos"]}
FILES = {"linux": "i3/.config/i3/config", "windows": "glazewm/config.yaml",
         "macos": "aerospace/.aerospace.toml"}
WM = {"linux": "i3", "windows": "GlazeWM", "macos": "AeroSpace"}

# Key names differ per WM; map them to one spelling
ALIAS = {"return": "enter", "esc": "escape", "grave": "`", "backtick": "`",
         "minus": "-", "equal": "=", "mod1": "alt", "$mod": "alt", "option": "alt",
         "control": "ctrl", "cmd": "win", "mod4": "win", "super": "win",
         "backspace": "backspace", "print": "print"}
MOD_ORDER = ["ctrl", "alt", "shift", "win"]


def norm(parts):
    parts = [ALIAS.get(p.lower(), p.lower()) for p in parts if p]
    mods = sorted({p for p in parts if p in MOD_ORDER}, key=MOD_ORDER.index)
    keys = [p for p in parts if p not in MOD_ORDER]
    return "+".join(mods + keys)


def short(cmd):
    cmd = re.sub(r"shell-exec\s+", "run ", cmd.strip())
    cmd = re.sub(r"exec(-and-forget)?\s+(--no-startup-id\s+)?", "run ", cmd)
    # paths -> program name
    cmd = re.sub(r"\S*[\\/]([^\\/\s]+)", r"\1", cmd)
    return cmd if len(cmd) <= 34 else cmd[:33] + "…"


def read_i3(path):
    keys, depth = {}, 0
    for line in open(path, encoding="utf-8"):
        s = line.strip()
        if s.startswith("mode ") and s.endswith("{"):
            depth += 1
        elif s == "}" and depth:
            depth -= 1
        elif not depth and s.startswith("bindsym "):
            m = re.match(r"bindsym\s+(?:--\S+\s+)*(\S+)\s+(.*)", s)
            if m:
                keys[norm(m.group(1).split("+"))] = m.group(2)
    return keys


def read_glazewm(path):
    keys, in_main, cmds = {}, False, None
    for line in open(path, encoding="utf-8"):
        if re.match(r"^keybindings:", line):
            in_main = True
            continue
        if in_main and re.match(r"^\S", line):
            in_main = False
        if not in_main:
            continue
        m = re.search(r"commands:\s*\[(.*)\]", line)
        if m:
            cmds = ", ".join(c.strip(" '\"") for c in re.findall(r"'[^']*'|\"[^\"]*\"", m.group(1)))
        m = re.search(r"bindings:\s*\[(.*)\]", line)
        if m and cmds is not None:
            for b in re.findall(r"'([^']*)'|\"([^\"]*)\"", m.group(1)):
                keys[norm((b[0] or b[1]).split("+"))] = cmds
    return keys


def read_aerospace(path):
    keys, section = {}, ""
    for line in open(path, encoding="utf-8"):
        s = line.split("#", 1)[0].strip()
        if s.startswith("["):
            section = s.strip("[]")
            continue
        if section != "mode.main.binding":
            continue
        m = re.match(r"([\w-]+)\s*=\s*(.+)", s)
        if m:
            val = m.group(2).strip()
            val = ", ".join(re.findall(r"'([^']*)'", val)) or val.strip("'\"")
            keys[norm(m.group(1).split("-"))] = val
    return keys


READ = {"linux": read_i3, "windows": read_glazewm, "macos": read_aerospace}


def find_repo(root, platform):
    for n in NAMES[platform]:
        p = os.path.join(root, n, FILES[platform])
        if os.path.isfile(p):
            return p
    return None


def main():
    here = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=os.path.dirname(here), help="folder that holds the three repos")
    ap.add_argument("--all", action="store_true", help="show every Alt key, not only differences")
    a = ap.parse_args()

    maps, missing = {}, []
    for p in NAMES:
        path = find_repo(a.root, p)
        if path:
            maps[p] = {k: v for k, v in READ[p](path).items() if "alt" in k.split("+")}
        else:
            missing.append(p)
    if missing:
        print(f"not found in {a.root}: {', '.join(missing)} (./sync.sh --clone gets them)", file=sys.stderr)
    if len(maps) < 2:
        return 1

    plats = list(maps)
    allkeys = sorted(set().union(*maps.values()),
                     key=lambda k: (k.count("+"), k.split("+")[-1].isdigit(), k))
    rows = [k for k in allkeys if a.all or not all(k in maps[p] for p in plats)]
    if not rows:
        print(f"All {len(allkeys)} Alt keys exist on {', '.join(WM[p] for p in plats)}.")
        return 0
    w = max(len(k) for k in rows)
    print(f"{'key':<{w}}  " + "  ".join(f"{WM[p]:<34}" for p in plats).rstrip())
    for k in rows:
        cells = [short(maps[p][k]) if k in maps[p] else "—" for p in plats]
        print(f"{k:<{w}}  " + "  ".join(f"{c:<34}" for c in cells).rstrip())
    if not a.all:
        print(f"\n{len(rows)} of {len(allkeys)} Alt keys are not on every platform "
              "(some can't be: see the 'Not available' notes in each README).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
