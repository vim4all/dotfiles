#!/bin/sh
# Layout: VGA (via VGA->HDMI converter, max 1080p, no EDID) | DP | LVDS (left to right)
# Output names depend on GPU enumeration order (Intel/nouveau can swap between
# boots: LVDS-1 vs LVDS-2, VGA-1-2 vs VGA-1-1), so detect them dynamically.

# Route the NVIDIA (nouveau) outputs through the primary provider (PRIME).
sink=$(xrandr --listproviders | awk '/Sink Output/ {print $4; exit}')
src=$(xrandr --listproviders | awk '/Source Output/ {print $4; exit}')
[ -n "$sink" ] && [ -n "$src" ] && [ "$sink" != "$src" ] && \
    xrandr --setprovideroutputsource "$sink" "$src" && sleep 1

out() { xrandr --query | awk -v p="$1" '$2=="connected" && $1 ~ p {print $1; exit}'; }
LVDS=$(out '^LVDS')
DP=$(out '^DP')
VGA=$(out '^VGA')

[ -n "$DP" ] && xrandr --output "$DP" --mode 2560x1440 --left-of "$LVDS"

if [ -n "$VGA" ]; then
    xrandr --newmode "1920x1080_dmt" 148.50 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync 2>/dev/null
    xrandr --addmode "$VGA" 1920x1080_dmt 2>/dev/null
    xrandr --output "$VGA" --mode 1920x1080_dmt --left-of "${DP:-$LVDS}"
fi
