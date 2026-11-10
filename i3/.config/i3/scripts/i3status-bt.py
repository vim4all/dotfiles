#!/usr/bin/env python3
"""i3status wrapper — injects Bluetooth, keyboard layout and Claude blocks.

Claude block: tmux sessions where Claude is waiting for me, from the state
files written by ~/.claude/hooks/notify.py (~/.cache/claude-status/*.json).
  ⚠ name  waiting for a permission answer (urgent, red)
  ✓ name  turn finished; disappears once that session's terminal is focused
Click: focus the terminal of the first one (sessions.py focus).
"""

import glob
import json
import os
import subprocess
import sys
import threading
import time

from Xlib import display as Xdisplay
from Xlib.protocol import rq

BT_SCRIPT = os.path.expanduser("~/.config/i3/scripts/rofi-bluetooth.sh")
KBD_TOGGLE = os.path.expanduser("~/.config/i3/scripts/toggle-kbd.py")
SESSIONS = os.path.expanduser("~/.config/i3/scripts/sessions.py")
CLAUDE_DIR = os.path.expanduser("~/.cache/claude-status")


# ── XKB protocol helpers ──────────────────────────────────────────────────────

class _XkbUseExtension(rq.ReplyRequest):
    _request = rq.Struct(
        rq.Card8('opcode'), rq.Opcode(0), rq.RequestLength(),
        rq.Card16('wanted_major'), rq.Card16('wanted_minor'),
    )
    _reply = rq.Struct(
        rq.ReplyCode(), rq.Card8('supported'), rq.Card16('sequence_number'),
        rq.ReplyLength(), rq.Card16('server_major'), rq.Card16('server_minor'),
        rq.Pad(20),
    )


class _XkbGetState(rq.ReplyRequest):
    _request = rq.Struct(
        rq.Card8('opcode'), rq.Opcode(4), rq.RequestLength(),
        rq.Card16('device_spec'), rq.Pad(2),
    )
    _reply = rq.Struct(
        rq.ReplyCode(), rq.Card8('device_id'), rq.Card16('sequence_number'),
        rq.ReplyLength(), rq.Card8('mods'), rq.Card8('base_mods'),
        rq.Card8('latched_mods'), rq.Card8('locked_mods'),
        rq.Card8('group'), rq.Card8('locked_group'),
        rq.Int16('base_group'), rq.Int16('latched_group'),
        rq.Card8('compat_state'), rq.Pad(7),
    )


_xkb_d = None
_xkb_op = None


def _xkb_init():
    global _xkb_d, _xkb_op
    if _xkb_d is not None:
        return
    d = Xdisplay.Display()
    ext = d.query_extension('XKEYBOARD')
    op = ext.major_opcode
    _XkbUseExtension(d.display, opcode=op, wanted_major=1, wanted_minor=0)
    _xkb_d = d
    _xkb_op = op


def _xkb_group():
    _xkb_init()
    return _XkbGetState(_xkb_d.display, opcode=_xkb_op, device_spec=0x0100).group


# ── Status blocks ─────────────────────────────────────────────────────────────

BT_TTL = 10          # seconds between bluetoothctl polls (i3status ticks every 2 s)
_bt_cache = (0.0, None)


def bt_block():
    global _bt_cache
    now = time.monotonic()
    if _bt_cache[1] is not None and now - _bt_cache[0] < BT_TTL:
        return _bt_cache[1]
    block = _bt_query()
    _bt_cache = (now, block)
    return block


_bus = None


def _bt_query():
    """One BlueZ GetManagedObjects call over D-Bus (no subprocesses).
    bluetoothctl 5.64 (Ubuntu 22.04) has no `devices Connected`."""
    global _bus
    try:
        import dbus
        if _bus is None:
            _bus = dbus.SystemBus()
        mgr = dbus.Interface(_bus.get_object("org.bluez", "/"),
                             "org.freedesktop.DBus.ObjectManager")
        objs = mgr.GetManagedObjects(timeout=2)

        powered = any(ifs.get("org.bluez.Adapter1", {}).get("Powered")
                      for ifs in objs.values())
        if not powered:
            return {"name": "bluetooth", "full_text": "󰂲 bt", "color": "#6c7086"}

        for ifs in objs.values():
            dev = ifs.get("org.bluez.Device1")
            if dev and dev.get("Connected"):
                name = str(dev.get("Alias") or dev.get("Name") or "?")
                return {"name": "bluetooth", "full_text": f"󰂱 {name}", "color": "#a6e3a1"}
        return {"name": "bluetooth", "full_text": "󰂯 bt", "color": "#cdd6f4"}
    except Exception:
        _bus = None  # reconnect next time (e.g. bluetoothd restarted)
        return {"name": "bluetooth", "full_text": "󰂲 bt", "color": "#f38ba8"}


def layout_block():
    try:
        group = _xkb_group()
        if group == 1:
            return {"name": "keyboard", "full_text": "󰌌 UA", "color": "#89b4fa"}
        return {"name": "keyboard", "full_text": "󰌌 EN", "color": "#cdd6f4"}
    except Exception:
        return {"name": "keyboard", "full_text": "󰌌 ??", "color": "#6c7086"}


_panes_cache = (0.0, set())
_claude_first = ""   # session the block's click focuses


def _live_panes():
    """tmux pane ids that still exist (cached for 10 s)."""
    global _panes_cache
    now = time.monotonic()
    if now - _panes_cache[0] > 10:
        try:
            out = subprocess.run(["tmux", "list-panes", "-a", "-F", "#{pane_id}"],
                                 capture_output=True, text=True, timeout=2).stdout
            _panes_cache = (now, set(out.split()))
        except (OSError, subprocess.SubprocessError):
            pass
    return _panes_cache[1]


def _focused_title():
    try:
        from Xlib import X
        _xkb_init()
        d = _xkb_d
        root = d.screen().root
        active = root.get_full_property(d.intern_atom("_NET_ACTIVE_WINDOW"), X.AnyPropertyType)
        if not active or not active.value[0]:
            return ""
        win = d.create_resource_object("window", active.value[0])
        name = win.get_full_property(d.intern_atom("_NET_WM_NAME"), d.intern_atom("UTF8_STRING"))
        return name.value.decode("utf-8", "replace") if name else ""
    except Exception:
        return ""


def claude_block():
    global _claude_first
    panes = _live_panes()
    focused = _focused_title()
    ask, done = [], []
    for path in glob.glob(os.path.join(CLAUDE_DIR, "*.json")):
        try:
            with open(path) as f:
                st = json.load(f)
        except (OSError, ValueError):
            continue
        session = st.get("session", "")
        if panes and st.get("pane") not in panes:   # pane closed: forget it
            os.remove(path)
            continue
        if st.get("state") == "done" and focused.startswith(session + ":"):
            os.remove(path)                          # seen it
            continue
        if st.get("state") == "ask":
            ask.append((st.get("since", 0), session))
        elif st.get("state") == "done":
            done.append((st.get("since", 0), session))
    if not ask and not done:
        _claude_first = ""
        return None
    ask.sort()
    done.sort()
    _claude_first = (ask or done)[0][1]

    def short(s):
        s = s[:-5] if s.endswith("_lite") else s
        return s if len(s) <= 18 else s[:17] + "…"

    items = [f"⚠ {short(s)}" for _, s in ask] + [f"✓ {short(s)}" for _, s in done]
    text = "  ".join(items[:3]) + (f"  +{len(items) - 3}" if len(items) > 3 else "")
    block = {"name": "claude", "full_text": f"󰚩 {text}",
             "color": "#fab387" if ask else "#a6e3a1"}
    if ask:
        block["urgent"] = True
    return block


# ── Click listener ────────────────────────────────────────────────────────────

def click_listener():
    for raw in sys.stdin:
        line = raw.strip().lstrip(",")
        if not line:
            continue
        try:
            ev = json.loads(line)
            if ev.get("name") == "bluetooth":
                global _bt_cache
                _bt_cache = (0.0, None)
                subprocess.Popen(
                    [BT_SCRIPT],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            elif ev.get("name") == "claude" and _claude_first:
                subprocess.Popen(
                    [SESSIONS, "focus", _claude_first],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            elif ev.get("name") == "keyboard":
                subprocess.Popen(
                    [KBD_TOGGLE],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
        except (json.JSONDecodeError, ValueError):
            pass


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    threading.Thread(target=click_listener, daemon=True).start()

    proc = subprocess.Popen(
        ["i3status", "--config", os.path.expanduser("~/.config/i3status/config")],
        stdout=subprocess.PIPE,
        text=True,
    )

    # Protocol header — enable click events
    header = json.loads(proc.stdout.readline())
    header["click_events"] = True
    print(json.dumps(header), flush=True)

    # Opening bracket
    print(proc.stdout.readline().strip(), flush=True)

    first = True
    for raw in proc.stdout:
        line = raw.strip().lstrip(",")
        if not line:
            continue
        try:
            blocks = json.loads(line)
        except json.JSONDecodeError:
            continue

        blocks.insert(1, bt_block())         # after wireless
        cb = claude_block()
        if cb:
            blocks.insert(0, cb)             # leftmost: easy to spot
        blocks.insert(-1, layout_block())    # before tztime

        prefix = "" if first else ","
        first = False
        print(f"{prefix}{json.dumps(blocks)}", flush=True)


if __name__ == "__main__":
    main()
