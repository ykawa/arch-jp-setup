#!/usr/bin/env bash

# Simple power menu inspired by Omarchy (Super+Escape)
# Requires: wofi, swaylock, systemd user privileges

set -euo pipefail

choices=(
    "Lock"
    "Suspend"
    "Logout"
    "Restart(Reboot)"
    "Shutdown"
)

choice=$(printf '%s\n' "${choices[@]}" | wofi --show dmenu --prompt "Power> ")

case "$choice" in
    "Lock")
        swaylock -f -c 000000
        ;;
    "Suspend")
        swaylock -f -c 000000 && systemctl suspend
        ;;
    "Logout")
        niri msg action quit --skip-confirmation
        ;;
    "Restart(Reboot)")
        systemctl reboot
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
    *)
        exit 0
        ;;
esac
