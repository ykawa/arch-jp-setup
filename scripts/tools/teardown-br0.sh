#!/usr/bin/env bash
# teardown-br0.sh — Cleanly remove br0 bridge and restore direct Ethernet
#
# What this does:
#   1. Detects the physical interface that was br0's member
#   2. Deletes the br0 and br0-slave-* NM connections
#   3. Restores (or creates) a direct DHCP connection on the physical interface
#   4. Removes /etc/sysctl.d/99-libvirt-br0.conf and reloads sysctl
#   5. Removes /etc/NetworkManager/conf.d/90-libvirt-unmanaged.conf
#   6. Removes 'allow br0' from /etc/qemu/bridge.conf
#   7. Disables and removes e1000e-fix.service (if present)
#
# Usage:
#   sudo ./teardown-br0.sh           # interactive teardown
#   sudo ./teardown-br0.sh --dry-run # show what would change without touching anything

set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

die() {
    echo "ERROR: $*" >&2
    exit 1
}
info() { echo "[teardown-br0] $*"; }
run() { $DRY_RUN && echo "  [DRY RUN] $*" || "$@"; }

[[ $EUID -eq 0 ]] || die "Run as root (sudo $0)"

SYSCTL_FILE="/etc/sysctl.d/99-libvirt-br0.conf"
NM_CONF="/etc/NetworkManager/conf.d/90-libvirt-unmanaged.conf"
QEMU_BRIDGE="/etc/qemu/bridge.conf"
E1000E_SERVICE="/etc/systemd/system/e1000e-fix.service"

# ── detect bridge member ──────────────────────────────────────────────────────
ETH_IFACE=$(bridge link show 2>/dev/null \
    | awk 'index($0, "master br0") {gsub(/:$/, "", $2); print $2}' \
    | grep -v '^vnet' | head -1 || true)

if [[ -z "$ETH_IFACE" ]]; then
    # br0 may already be down; try to infer from NM slave connections
    ETH_IFACE=$(nmcli -g NAME,DEVICE connection show \
        | awk -F: '/^br0-slave-/{gsub(/^br0-slave-/, "", $1); print $1; exit}' || true)
fi

if [[ -z "$ETH_IFACE" ]]; then
    info "Warning: Could not detect bridge member — will still remove br0 NM connections"
fi

info "Bridge member : ${ETH_IFACE:-unknown}"
echo

# ── 1. Bring down br0 ────────────────────────────────────────────────────────
info "=== Step 1: Bringing down br0 ==="
if nmcli connection show br0 &>/dev/null; then
    run nmcli connection down br0 2>/dev/null || true
else
    info "NM connection 'br0' not found — skipping"
fi
echo

# ── 2. Delete slave connection ────────────────────────────────────────────────
info "=== Step 2: Deleting br0 slave connections ==="
SLAVE_DELETED=false
while IFS= read -r con; do
    [[ "$con" == br0-slave-* ]] || [[ "$con" == bridge-slave-* ]] || continue
    info "Deleting: $con"
    run nmcli connection delete "$con"
    SLAVE_DELETED=true
done < <(nmcli -g NAME connection show 2>/dev/null || true)
$SLAVE_DELETED || info "No slave connections found — skipping"
echo

# ── 3. Delete br0 connection ──────────────────────────────────────────────────
info "=== Step 3: Deleting br0 NM connection ==="
if nmcli connection show br0 &>/dev/null; then
    run nmcli connection delete br0
else
    info "Not found — skipping"
fi
echo

# ── 4. Restore Ethernet connection ───────────────────────────────────────────
info "=== Step 4: Restoring direct Ethernet connection ==="
if [[ -n "$ETH_IFACE" ]]; then
    # Look for an existing (inactive) connection for this interface
    EXISTING_CON=$(nmcli -g NAME,DEVICE connection show \
        | awk -F: -v iface="$ETH_IFACE" \
            '$2 == iface || ($2 == "" && $1 ~ iface) {print $1; exit}' || true)

    if [[ -n "$EXISTING_CON" ]]; then
        info "Re-enabling existing connection: $EXISTING_CON"
        run nmcli connection modify "$EXISTING_CON" connection.autoconnect yes
        run nmcli connection up "$EXISTING_CON"
    else
        info "No existing connection found — creating new DHCP connection for $ETH_IFACE"
        run nmcli connection add \
            type ethernet \
            ifname "$ETH_IFACE" \
            con-name "$ETH_IFACE" \
            ipv4.method auto \
            ipv6.method auto
        run nmcli connection up "$ETH_IFACE"
    fi
else
    info "Skipped (no interface detected)"
fi
echo

# ── 5. rp_filter sysctl ───────────────────────────────────────────────────────
info "=== Step 5: Removing rp_filter sysctl ==="
if [[ -f "$SYSCTL_FILE" ]]; then
    run rm -f "$SYSCTL_FILE"
    $DRY_RUN || sysctl --system >/dev/null
    info "Removed $SYSCTL_FILE"
else
    info "Not found — skipping"
fi
echo

# ── 6. NM unmanaged vnet* ─────────────────────────────────────────────────────
info "=== Step 6: Removing NM unmanaged-devices config ==="
if [[ -f "$NM_CONF" ]]; then
    run rm -f "$NM_CONF"
    run systemctl reload NetworkManager
    info "Removed $NM_CONF"
else
    info "Not found — skipping"
fi
echo

# ── 7. qemu bridge.conf ───────────────────────────────────────────────────────
info "=== Step 7: Removing 'allow br0' from qemu bridge.conf ==="
if grep -q "^allow br0$" "$QEMU_BRIDGE" 2>/dev/null; then
    run sed -i '/^allow br0$/d' "$QEMU_BRIDGE"
    info "Removed from $QEMU_BRIDGE"
else
    info "Not present — skipping"
fi
echo

# ── 8. e1000e-fix service ─────────────────────────────────────────────────────
info "=== Step 8: Removing e1000e-fix.service ==="
if [[ -f "$E1000E_SERVICE" ]]; then
    systemctl is-active e1000e-fix.service &>/dev/null && run systemctl stop e1000e-fix.service
    systemctl is-enabled e1000e-fix.service &>/dev/null && run systemctl disable e1000e-fix.service
    run rm -f "$E1000E_SERVICE"
    run systemctl daemon-reload
    info "Removed $E1000E_SERVICE"
else
    info "Not found — skipping"
fi
echo

# ── Verify ────────────────────────────────────────────────────────────────────
if ! $DRY_RUN; then
    sleep 2
    info "=== Verification ==="
    if [[ -n "$ETH_IFACE" ]]; then
        IP=$(ip -4 addr show "$ETH_IFACE" 2>/dev/null | awk '/inet /{print $2}' || true)
        info "$ETH_IFACE IP: ${IP:-(no address yet — DHCP may still be negotiating)}"
    fi
    nmcli connection show --active | grep -v "^NAME" | awk '{printf "  Active: %s\n", $1}' || true
    info "Done. br0 removed."
fi
