#!/usr/bin/env bash
set -euo pipefail

# Simple wofi-based power menu for Waybar

logout_session() {
  case "${XDG_CURRENT_DESKTOP,,}" in
    niri)     niri msg action quit --skip-confirmation ;;
    hyprland) hyprctl dispatch exit ;;
    gnome)    gnome-session-quit --logout --no-prompt ;;
    cinnamon) cinnamon-session-quit --logout --no-prompt ;;
    *)        loginctl terminate-session "$XDG_SESSION_ID" ;;
  esac
}

choices=(
  "Lock"
  "Logout"
  "Suspend"
  "Hibernate"
  "Reboot"
  "Shutdown"
)

selection=$(printf '%s\n' "${choices[@]}" | wofi --show dmenu --prompt "Power> ") || exit 0

case "$selection" in
  Lock)
    exec swaylock -f -c 000000
    ;;
  Logout)
    logout_session
    ;;
  Suspend)
    exec systemctl suspend
    ;;
  Hibernate)
    exec systemctl hibernate
    ;;
  Reboot)
    exec systemctl reboot -i
    ;;
  Shutdown)
    exec systemctl poweroff -i
    ;;
  *) exit 0 ;;
 esac
