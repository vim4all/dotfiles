#!/usr/bin/env bash
# Rofi Bluetooth menu using bluetoothctl

set -euo pipefail

power_on() { bluetoothctl show | grep -q "Powered: yes"; }

toggle_power() {
    if power_on; then
        bluetoothctl power off
    else
        bluetoothctl power on
    fi
}

# Get paired devices: "MAC Name"
paired_devices() {
    bluetoothctl devices Paired 2>/dev/null | awk '{mac=$2; $1=$2=""; name=substr($0,3); print mac " " name}'
}

is_connected() {
    bluetoothctl info "$1" 2>/dev/null | grep -q "Connected: yes"
}

# Build menu entries
menu() {
    if power_on; then
        echo "  Power off"
        echo "  Scan & pair new device"
        while IFS= read -r line; do
            mac="${line%% *}"
            name="${line#* }"
            if is_connected "$mac"; then
                echo "󰂱  Disconnect $name ($mac)"
            else
                echo "󰂯  Connect $name ($mac)"
            fi
        done < <(paired_devices)
    else
        echo "  Power on"
    fi
}

chosen=$(menu | rofi -dmenu -p "󰂯 Bluetooth" -i)
[[ -z "$chosen" ]] && exit 0

case "$chosen" in
    *"Power off"*)     toggle_power ;;
    *"Power on"*)      toggle_power ;;
    *"Scan & pair"*)
        # Open a terminal running bluetoothctl for interactive pairing
        gnome-terminal -- bash -c "bluetoothctl; exec bash"
        ;;
    *"Disconnect "*)
        mac=$(grep -oP '\(([0-9A-F:]+)\)' <<< "$chosen" | tr -d '()')
        bluetoothctl disconnect "$mac"
        ;;
    *"Connect "*)
        mac=$(grep -oP '\(([0-9A-F:]+)\)' <<< "$chosen" | tr -d '()')
        bluetoothctl connect "$mac"
        ;;
esac
