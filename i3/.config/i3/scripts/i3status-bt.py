#!/usr/bin/env python3
"""i3status wrapper — injects Bluetooth and keyboard layout blocks."""

import json
import os
import subprocess
import sys
import threading

from Xlib import display as Xdisplay
from Xlib.protocol import rq

BT_SCRIPT = os.path.expanduser("~/.config/i3/scripts/rofi-bluetooth.sh")
KBD_TOGGLE = os.path.expanduser("~/.config/i3/scripts/toggle-kbd.py")


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

def bt_block():
    try:
        show = subprocess.check_output(
            ["bluetoothctl", "show"], text=True, stderr=subprocess.DEVNULL
        )
        if "Powered: yes" not in show:
            return {"name": "bluetooth", "full_text": "󰂲 bt", "color": "#6c7086"}

        lines = subprocess.check_output(
            ["bluetoothctl", "devices", "Connected"],
            text=True, stderr=subprocess.DEVNULL,
        ).strip().splitlines()
        lines = [l for l in lines if l]

        if lines:
            name = lines[0].split(" ", 2)[-1]
            return {"name": "bluetooth", "full_text": f"󰂱 {name}", "color": "#a6e3a1"}
        return {"name": "bluetooth", "full_text": "󰂯 bt", "color": "#cdd6f4"}
    except Exception:
        return {"name": "bluetooth", "full_text": "󰂲 bt", "color": "#f38ba8"}


def layout_block():
    try:
        group = _xkb_group()
        if group == 1:
            return {"name": "keyboard", "full_text": "󰌌 UA", "color": "#89b4fa"}
        return {"name": "keyboard", "full_text": "󰌌 EN", "color": "#cdd6f4"}
    except Exception:
        return {"name": "keyboard", "full_text": "󰌌 ??", "color": "#6c7086"}


# ── Click listener ────────────────────────────────────────────────────────────

def click_listener():
    for raw in sys.stdin:
        line = raw.strip().lstrip(",")
        if not line:
            continue
        try:
            ev = json.loads(line)
            if ev.get("name") == "bluetooth":
                subprocess.Popen(
                    [BT_SCRIPT],
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
        blocks.insert(-1, layout_block())    # before tztime

        prefix = "" if first else ","
        first = False
        print(f"{prefix}{json.dumps(blocks)}", flush=True)


if __name__ == "__main__":
    main()
