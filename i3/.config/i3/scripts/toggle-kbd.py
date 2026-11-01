#!/usr/bin/env python3
"""Toggle keyboard layout between group 0 (us) and group 1 (ua) via XKB."""
from Xlib import display
from Xlib.protocol import rq
import subprocess


class XkbUseExtension(rq.ReplyRequest):
    _request = rq.Struct(
        rq.Card8('opcode'), rq.Opcode(0), rq.RequestLength(),
        rq.Card16('wanted_major'), rq.Card16('wanted_minor'),
    )
    _reply = rq.Struct(
        rq.ReplyCode(), rq.Card8('supported'), rq.Card16('sequence_number'),
        rq.ReplyLength(), rq.Card16('server_major'), rq.Card16('server_minor'),
        rq.Pad(20),
    )


class XkbGetState(rq.ReplyRequest):
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


class XkbLatchLockState(rq.Request):
    _request = rq.Struct(
        rq.Card8('opcode'), rq.Opcode(5), rq.RequestLength(),
        rq.Card16('device_spec'),
        rq.Card8('affect_mod_locks'), rq.Card8('mod_locks'),
        rq.Card8('lock_group'), rq.Card8('group_lock'),
        rq.Card8('affect_mod_latches'), rq.Card8('latch_group'),
        rq.Int16('groups_to_latch'), rq.Pad(2),
    )


d = display.Display()
ext = d.query_extension('XKEYBOARD')
op = ext.major_opcode
XkbUseExtension(d.display, opcode=op, wanted_major=1, wanted_minor=0)
state = XkbGetState(d.display, opcode=op, device_spec=0x0100)
new_group = 1 - state.group
XkbLatchLockState(
    d.display, opcode=op, device_spec=0x0100,
    affect_mod_locks=0, mod_locks=0,
    lock_group=1, group_lock=new_group,
    affect_mod_latches=0, latch_group=0, groups_to_latch=0,
)
d.flush()
subprocess.run(['killall', '-SIGUSR1', 'i3status'])
