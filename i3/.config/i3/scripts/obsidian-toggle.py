#!/usr/bin/env python3
"""Show/hide Obsidian as a centered i3 scratchpad window ($mod+o).

- Obsidian not running  → launch it; the for_window rule in the i3 config
  sends it to the scratchpad, then we show it.
- Running but tiled      → move it into the scratchpad and show it.
- In the scratchpad      → toggle (scratchpad show hides it if it's visible).

--show: only ever show it (used after opening a note from another app).
"""
import json
import subprocess
import sys
import time

CRIT = '[class="obsidian"]'


def i3(cmd: str) -> None:
    subprocess.run(["i3-msg", "-q", cmd])


def find_windows(node, out, ws=""):
    if node.get("type") == "workspace":
        ws = node.get("name", "")
    props = node.get("window_properties") or {}
    if props.get("class", "").lower() == "obsidian":
        node["_ws"] = ws  # "__i3_scratch" = hidden in the scratchpad
        out.append(node)
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        find_windows(child, out, ws)
    return out


def obsidian_windows():
    tree = json.loads(subprocess.run(["i3-msg", "-t", "get_tree"],
                                     capture_output=True, text=True).stdout)
    return find_windows(tree, [])


SHOW_ONLY = "--show" in sys.argv[1:]

wins = obsidian_windows()
if SHOW_ONLY and wins and all(w["_ws"] != "__i3_scratch" for w in wins):
    i3(f"{CRIT} focus")  # already visible (tiled or shown) → just focus it
elif not wins:
    subprocess.Popen(["obsidian"], stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)
    for _ in range(60):  # wait up to ~15 s for the window
        time.sleep(0.25)
        if obsidian_windows():
            break
    i3(f"{CRIT} scratchpad show")
elif all(w.get("scratchpad_state", "none") == "none" for w in wins):
    i3(f"{CRIT} move scratchpad, resize set 85 ppt 85 ppt, move position center")
    i3(f"{CRIT} scratchpad show")
else:
    i3(f"{CRIT} scratchpad show")
