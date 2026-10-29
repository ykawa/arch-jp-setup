#!/usr/bin/env bash
# Create a br0 bridge over the active Ethernet interface for libvirt.
#
# Usage:
#   sudo ./setup-br0.sh              # auto-detect active Ethernet
#   sudo ./setup-br0.sh enp0s31f6    # specify interface explicitly
#
# What this does:
#   1. Creates a br0 NetworkManager bridge (DHCP, STP off)
#   2. Adds the Ethernet interface as a bridge member
#   3. Switches network traffic to br0
#
# Undo (remove br0 and restore original connection):
#   sudo nmcli connection delete br0
#   sudo nmcli connection delete br0-slave-<iface>
#   sudo nmcli connection up "$(nmcli -g NAME connection show | grep -v br0 | head -1)"

set -euo pipefail

# ── helpers ─────────────────────────────────────────────────────────────────
die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "[br0-setup] $*"; }

[[ $EUID -eq 0 ]] || die "Run as root (sudo $0)"

# ── resolve target interface ────────────────────────────────────────────────
if [[ -n "${1:-}" ]]; then
    ETH_IFACE="$1"
else
    # Find the interface used by the default route that is Ethernet (not bridge/veth/wlan)
    ETH_IFACE=$(ip route show default \
        | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' \
        | head -1)
fi

[[ -n "$ETH_IFACE" ]] || die "Could not detect active Ethernet interface"

# Verify it looks like a physical Ethernet port (not an existing bridge)
IFACE_TYPE=$(nmcli -g GENERAL.TYPE device show "$ETH_IFACE" 2>/dev/null || true)
if [[ "$IFACE_TYPE" == "bridge" ]]; then
    die "$ETH_IFACE is already a bridge — nothing to do"
fi

ETH_MAC=$(cat /sys/class/net/"$ETH_IFACE"/address)
[[ -n "$ETH_MAC" ]] || die "Could not read MAC from $ETH_IFACE"

info "Target Ethernet interface : $ETH_IFACE  (MAC: $ETH_MAC)"

# ── check br0 doesn't already exist ─────────────────────────────────────────
if nmcli connection show br0 &>/dev/null; then
    info "Connection 'br0' already exists — skipping creation"
else
    info "Creating bridge br0 (DHCP, STP disabled, MAC=$ETH_MAC)"
    # Use the physical NIC MAC for br0 so the router's ARP table stays stable.
    # Without this NM assigns a random MAC, which can trigger the switch's
    # MAC-flood protection when a guest VM appears on the same physical port.
    nmcli connection add \
        type bridge \
        ifname br0 \
        con-name br0 \
        ipv4.method auto \
        ipv6.method disabled \
        bridge.stp no \
        ethernet.cloned-mac-address "$ETH_MAC"
fi

SLAVE_CON="br0-slave-${ETH_IFACE}"
if nmcli connection show "$SLAVE_CON" &>/dev/null; then
    info "Slave connection '$SLAVE_CON' already exists — skipping creation"
else
    info "Adding $ETH_IFACE as bridge member"
    nmcli connection add \
        type ethernet \
        ifname "$ETH_IFACE" \
        con-name "$SLAVE_CON" \
        master br0
fi

# ── activate ────────────────────────────────────────────────────────────────
info "Activating br0 (brief network interruption expected)"
# Bring up the slave first so the bridge has a member before going live
nmcli connection up "$SLAVE_CON"
nmcli connection up br0

# Disable the old standalone Ethernet connection so it won't compete
OLD_CON=$(nmcli -g NAME,DEVICE connection show --active \
    | awk -F: -v iface="$ETH_IFACE" '$2 == iface && $1 != "br0-slave-"iface {print $1}' \
    | head -1 || true)
if [[ -n "$OLD_CON" ]]; then
    info "Disabling old connection: $OLD_CON"
    nmcli connection down "$OLD_CON" || true
    # Prevent auto-reconnect on this interface (the slave now owns it)
    nmcli connection modify "$OLD_CON" connection.autoconnect no
fi

# ── rp_filter ───────────────────────────────────────────────────────────────
SYSCTL_FILE="/etc/sysctl.d/99-libvirt-br0.conf"
info "Writing $SYSCTL_FILE (rp_filter)"
tee "$SYSCTL_FILE" > /dev/null <<EOF
# rp_filter for libvirt br0 bridge
net.ipv4.conf.${ETH_IFACE}.rp_filter = 0
net.ipv4.conf.br0.rp_filter = 1
EOF
sysctl -p "$SYSCTL_FILE"

# ── NetworkManager: do not manage vnet* tap devices ─────────────────────────
# Without this, NM detects vnetN when a VM starts, runs DHCP on it, and adds
# a low-metric default route through the guest tap → host loses internet instantly.
NM_CONF="/etc/NetworkManager/conf.d/90-libvirt-unmanaged.conf"
if [[ ! -f "$NM_CONF" ]]; then
    info "Writing $NM_CONF (vnet* unmanaged)"
    mkdir -p /etc/NetworkManager/conf.d
    tee "$NM_CONF" > /dev/null <<'NMEOF'
[keyfile]
unmanaged-devices=interface-name:vnet*;interface-name:tap*
NMEOF
    systemctl reload NetworkManager
fi

# ── qemu-bridge-helper: allow br0 ───────────────────────────────────────────
QEMU_BRIDGE="/etc/qemu/bridge.conf"
if ! grep -q "^allow br0$" "$QEMU_BRIDGE" 2>/dev/null; then
    info "Adding 'allow br0' to $QEMU_BRIDGE"
    echo "allow br0" >> "$QEMU_BRIDGE"
fi

# ── e1000e TSO fix ───────────────────────────────────────────────────────────
# e1000e TX queue stalls under heavy traffic when TSO is on (kernel Bug #118721).
# Triggered by Ubuntu 22.04 guests (kernel 5.15 virtio-net); newer kernels are unaffected.
E1000E_SERVICE="/etc/systemd/system/e1000e-fix.service"
ETH_DRIVER=$(readlink "/sys/class/net/${ETH_IFACE}/device/driver" 2>/dev/null | xargs basename 2>/dev/null || true)
if [[ "$ETH_DRIVER" == "e1000e" ]]; then
    info "e1000e detected on $ETH_IFACE — creating TSO fix service"
    tee "$E1000E_SERVICE" > /dev/null <<EOF
[Unit]
Description=Disable TSO/GSO on ${ETH_IFACE} (e1000e Hardware Unit Hang fix)
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ethtool -K ${ETH_IFACE} tso off gso off gro off sg off
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable e1000e-fix.service
    systemctl start e1000e-fix.service
    info "e1000e-fix.service enabled and started."
else
    info "$ETH_IFACE driver is '${ETH_DRIVER:-unknown}' — e1000e fix not needed, skipping."
fi

# ── verify ──────────────────────────────────────────────────────────────────
sleep 2
info "Bridge status:"
ip link show br0
ip addr show br0
info "Done. br0 is active. Verify with: bridge link show"
