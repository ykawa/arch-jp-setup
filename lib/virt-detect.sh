#!/bin/bash

# Virtual Environment Detection Utility

is_virtual_environment() {
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        local virt_type=$(systemd-detect-virt 2>/dev/null)
        case "$virt_type" in
            vmware | kvm | qemu | virtualbox | xen | microsoft | parallels | bhyve | openvz | lxc | docker | podman)
                echo "Virtual environment detected via systemd-detect-virt: $virt_type" >&2
                return 0
                ;;
            *)
                ;;
        esac
    fi
    return 1
}
