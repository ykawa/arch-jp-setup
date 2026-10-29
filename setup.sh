#!/bin/bash
# Main Setup Orchestrator for arch-jp-setup
# This script detects the desktop environment and runs appropriate setup scripts

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helper libraries
source "$SCRIPT_DIR/lib/desktop-detect.sh"
source "$SCRIPT_DIR/lib/virt-detect.sh" 2>/dev/null || true
source "$SCRIPT_DIR/lib/package-groups.sh"
source "$SCRIPT_DIR/lib/install-copy.sh"
source "$SCRIPT_DIR/lib/local-settings.sh"
source "$SCRIPT_DIR/lib/hooks.sh"

# リポジトリ（git clone や開発用の作業ディレクトリ）から実行された場合は、
# INSTALL_DIR にコピーしてからそちらで実行し直す。設定ファイルのリンクはすべて INSTALL_DIR を指す。
if [ "$SCRIPT_DIR" != "$INSTALL_DIR" ]; then
    echo "Copying $SCRIPT_DIR to $INSTALL_DIR ..."
    copy_to_install_dir "$SCRIPT_DIR"
    exec bash "$INSTALL_DIR/setup.sh" "$@"
fi

# Function to log messages with timestamps
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HOME/setup.log"
}

# TUI 用の gum を入れる（パッケージDBが古いと失敗するので、その場合は同期してから再試行）
ensure_gum() {
    command -v gum &>/dev/null && return 0
    sudo pacman -S --needed --noconfirm gum \
        || sudo pacman -Syu --needed --noconfirm gum
}

# Main setup process
main() {
    log_message "==========================================="
    log_message "  arch/manjaro/cachyos Linux Setup Script"
    log_message "==========================================="
    log_message ""

    # Detect current session's desktop environment
    CURRENT_DE=$(detect_desktop_environment)

    if [ "$CURRENT_DE" = "unknown" ]; then
        log_message "WARNING: Could not detect current desktop environment session"
        log_message "Supported environments: GNOME, COSMIC, Cinnamon, niri"
        log_message ""
        log_message "Checking session info:"
        log_message "  XDG_CURRENT_DESKTOP: ${XDG_CURRENT_DESKTOP:-not set}"
        log_message "  XDG_SESSION_DESKTOP: ${XDG_SESSION_DESKTOP:-not set}"
        log_message ""
        log_message "Only common setup scripts will be executed."
        log_message ""
    else
        log_message "Detected current desktop environment: $(get_desktop_display_name_for "$CURRENT_DE")"
        log_message ""
    fi

    log_message ""
    log_message "================================"
    log_message "  Package Group Selection"
    log_message "================================"
    log_message ""

    if ! ensure_gum; then
        log_message "WARNING: gum could not be installed; using saved/default selection"
    fi
    if ! select_groups "$SCRIPT_DIR"; then
        log_message "Group selection cancelled. Aborting setup."
        exit 1
    fi
    log_message "Selection saved to: $GROUP_SELECTION_FILE"
    while read -r group_name group_state; do
        log_message "  [$group_state] $group_name"
    done < "$GROUP_SELECTION_FILE"

    # PC ごとの設定（INSTALL_DIR のコピーにだけ反映する）
    if [ "$CURRENT_DE" = "niri" ]; then
        select_avatar_source || { log_message "Avatar selection cancelled. Aborting setup."; exit 1; }
        log_message "Noctalia avatar: $(cat "$AVATAR_SETTING_FILE")"
    fi

    log_message ""
    log_message "================================"
    log_message "  Phase 1: Common Setup"
    log_message "================================"
    log_message ""

    # Execute common scripts
    for script in "$SCRIPT_DIR"/scripts/common/*.sh; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            if ! is_group_selected "$script"; then
                log_message "Skipped (not selected): $script_name"
                log_message ""
                continue
            fi
            log_message "Running: $script_name"

            if bash "$script"; then
                log_message "✓ $script_name completed"
            else
                log_message "ERROR: $script_name failed"
                log_message "Setup interrupted due to error in: $script_name"
                exit 1
            fi

            log_message ""
        fi
    done

    # Phase 2: Desktop-specific setup for current session's DE
    if [ "$CURRENT_DE" != "unknown" ]; then
        DESKTOP_NAME=$(get_desktop_display_name_for "$CURRENT_DE")

        log_message ""
        log_message "================================"
        log_message "  Phase 2: $DESKTOP_NAME Setup"
        log_message "================================"
        log_message ""

        # Check if desktop-specific scripts exist
        if [ ! -d "$SCRIPT_DIR/scripts/desktop/$CURRENT_DE" ]; then
            log_message "WARNING: No desktop-specific scripts found for: $CURRENT_DE"
            log_message "Skipping $DESKTOP_NAME configuration"
        else
            # Execute desktop-specific scripts
            for script in "$SCRIPT_DIR"/scripts/desktop/"$CURRENT_DE"/*.sh; do
                if [ -f "$script" ]; then
                    script_name=$(basename "$script")
                    log_message "Running: $script_name"

                    if bash "$script"; then
                        log_message "✓ $script_name completed"
                    else
                        log_message "ERROR: $script_name failed"
                        log_message "Setup interrupted due to error in: $script_name"
                        exit 1
                    fi

                    log_message ""
                fi
            done
        fi
    fi

    log_message ""
    log_message "================================"
    log_message "  Phase 3: Final Setup"
    log_message "================================"
    log_message ""

    # Execute final scripts (network-disruptive steps like br0 bridge creation
    # run last so DHCP renegotiation doesn't break earlier network-dependent tasks)
    for script in "$SCRIPT_DIR"/scripts/final/*.sh; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            if ! is_group_selected "$script"; then
                log_message "Skipped (not selected): $script_name"
                log_message ""
                continue
            fi
            log_message "Running: $script_name"

            if bash "$script"; then
                log_message "✓ $script_name completed"
            else
                log_message "ERROR: $script_name failed"
                log_message "Setup interrupted due to error in: $script_name"
                exit 1
            fi

            log_message ""
        fi
    done

    log_message ""
    log_message "================================"
    log_message "  External Hooks"
    log_message "================================"
    log_message ""
    run_hooks "$SCRIPT_DIR" setup 2>&1 | tee -a "$HOME/setup.log"

    log_message ""
    log_message "======================================"
    log_message "  Setup Completed Successfully!"
    log_message "======================================"
    log_message ""
    if [ "$CURRENT_DE" != "unknown" ]; then
        log_message "Configured Desktop Environment: $(get_desktop_display_name_for "$CURRENT_DE")"
        log_message ""
    fi
    log_message "Log file: $HOME/setup.log"
    log_message ""
    log_message "🔄 RECOMMENDED: Reboot your system to apply all changes"
    log_message "   sudo reboot"
    log_message ""
    log_message "📝 OPTIONAL: Install Japanese Windows 11 fonts"
    log_message "   paru -S --needed --noconfirm ttf-ms-win11-auto-japanese"
    log_message ""
    log_message "======================================"
}

# Run main function
main "$@"
