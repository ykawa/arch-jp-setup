#!/bin/bash

logout_session() {
    case "${XDG_CURRENT_DESKTOP,,}" in
        niri) niri msg action quit --skip-confirmation ;;
        hyprland) hyprctl dispatch exit ;;
        gnome) gnome-session-quit --logout --no-prompt ;;
        cinnamon) cinnamon-session-quit --logout --no-prompt ;;
        *) loginctl terminate-session "$XDG_SESSION_ID" ;;
    esac
}

options="Shutdown\nReboot\nLogout\nSuspend\nHibernate\nLock\nExit"
chosen=$(echo -e "$options" | wofi --show dmenu --prompt "Power Menu> ")

case $chosen in
    "Shutdown") systemctl poweroff ;;
    "Reboot") systemctl reboot ;;
    "Logout") logout_session ;;
    "Suspend") systemctl suspend ;;
    "Hibernate") systemctl hibernate ;;
    "Lock") swaylock ;;
    "Exit") exit 0 ;;
    *) exit 1 ;;
esac
