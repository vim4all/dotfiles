#!/bin/sh
# Layout: VGA (via VGA->HDMI converter, max 1080p, no EDID) | DP-1-1 | LVDS-1
xrandr --output DP-1-1 --mode 2560x1440 --left-of LVDS-1

if xrandr --query | grep -q '^VGA-1-2 connected'; then
    xrandr --newmode "1920x1080_dmt" 148.50 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync 2>/dev/null
    xrandr --addmode VGA-1-2 1920x1080_dmt 2>/dev/null
    xrandr --output VGA-1-2 --mode 1920x1080_dmt --left-of DP-1-1
fi
