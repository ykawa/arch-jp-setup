#!/bin/bash
# Desktop Environment Detection Library
# Source this file in setup.sh: source lib/desktop-detect.sh

# Function to detect the current desktop environment
# Returns: gnome, cosmic, cinnamon, niri, or unknown
detect_desktop_environment() {
    local desktop_env=""

    # Method 1: Check XDG_CURRENT_DESKTOP environment variable
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        case "$XDG_CURRENT_DESKTOP" in
            *GNOME*)
                desktop_env="gnome"
                ;;
            *COSMIC*)
                desktop_env="cosmic"
                ;;
            *Cinnamon*)
                desktop_env="cinnamon"
                ;;
            *niri*)
                desktop_env="niri"
                ;;
        esac
    fi

    # Method 2: Check running processes if XDG_CURRENT_DESKTOP is not set
    if [ -z "$desktop_env" ]; then
        if pgrep -x "gnome-shell" > /dev/null; then
            desktop_env="gnome"
        elif pgrep -x "cosmic-comp" > /dev/null || pgrep -x "cosmic-panel" > /dev/null; then
            desktop_env="cosmic"
        elif pgrep -x "cinnamon" > /dev/null; then
            desktop_env="cinnamon"
        elif pgrep -x "niri" > /dev/null; then
            desktop_env="niri"
        fi
    fi

    # Method 3: Check session files as fallback
    if [ -z "$desktop_env" ] && [ -n "$XDG_SESSION_DESKTOP" ]; then
        case "$XDG_SESSION_DESKTOP" in
            gnome*)
                desktop_env="gnome"
                ;;
            cosmic*)
                desktop_env="cosmic"
                ;;
            cinnamon*)
                desktop_env="cinnamon"
                ;;
            niri*)
                desktop_env="niri"
                ;;
        esac
    fi

    # Return the detected desktop environment or "unknown"
    if [ -z "$desktop_env" ]; then
        echo "unknown"
    else
        echo "$desktop_env"
    fi
}

# Function to check if we're in a specific desktop environment
# Usage: is_desktop "gnome" && echo "Running on GNOME"
is_desktop() {
    local target="$1"
    local current=$(detect_desktop_environment)
    [ "$current" = "$target" ]
}

# Function to get the desktop environment display name
get_desktop_display_name() {
    local desktop_env=$(detect_desktop_environment)
    get_desktop_display_name_for "$desktop_env"
}

# Function to get the display name for a specific desktop environment
get_desktop_display_name_for() {
    local desktop_env="$1"
    case "$desktop_env" in
        gnome)
            echo "GNOME"
            ;;
        cosmic)
            echo "COSMIC Desktop"
            ;;
        cinnamon)
            echo "Cinnamon"
            ;;
        niri)
            echo "niri"
            ;;
        *)
            echo "Unknown Desktop Environment"
            ;;
    esac
}

# Function to detect all installed desktop environments
# Returns: space-separated list of installed DEs (e.g., "gnome cosmic niri")
detect_installed_desktop_environments() {
    local installed_des=""

    # Check for GNOME (gnome-shell package)
    if pacman -Q gnome-shell &>/dev/null; then
        installed_des="$installed_des gnome"
    fi

    # Check for COSMIC (cosmic-comp package)
    if pacman -Q cosmic-comp &>/dev/null; then
        installed_des="$installed_des cosmic"
    fi

    # Check for Cinnamon (cinnamon package)
    if pacman -Q cinnamon &>/dev/null; then
        installed_des="$installed_des cinnamon"
    fi

    # Check for niri (niri package)
    if pacman -Q niri &>/dev/null; then
        installed_des="$installed_des niri"
    fi

    # Trim leading space and return
    echo "$installed_des" | sed 's/^ //'
}

# Function to check if a specific desktop environment is installed
# Usage: is_desktop_installed "gnome" && echo "GNOME is installed"
is_desktop_installed() {
    local target="$1"
    case "$target" in
        gnome)
            pacman -Q gnome-shell &>/dev/null
            ;;
        cosmic)
            pacman -Q cosmic-comp &>/dev/null
            ;;
        cinnamon)
            pacman -Q cinnamon &>/dev/null
            ;;
        niri)
            pacman -Q niri &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Example usage:
# source lib/desktop-detect.sh
# DESKTOP=$(detect_desktop_environment)
# echo "Current desktop: $DESKTOP"
#
# if is_desktop "gnome"; then
#     echo "Running GNOME-specific code"
# fi
#
# INSTALLED=$(detect_installed_desktop_environments)
# echo "Installed desktops: $INSTALLED"
#
# if is_desktop_installed "cosmic"; then
#     echo "COSMIC is installed"
# fi
