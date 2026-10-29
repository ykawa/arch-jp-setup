#!/bin/bash
# Virtualization tools, br0 bridge, and e1000e TSO fix
# @group: 仮想化 (QEMU / libvirt / br0 ブリッジ)
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/virt-detect.sh"

echo "======================================="
echo "  Virtualization Tools & Network Setup"
echo "======================================="
echo ""

if is_virtual_environment; then
    echo "Virtual environment detected — skipping virtualization tools"
    echo ""
    exit 0
fi

echo "Physical hardware detected — proceeding"
echo ""

# ── 1. Packages ──────────────────────────────────────────────────────────────
echo "Installing virtualization tools..."
paru -S --needed --noconfirm \
    qemu-full \
    libvirt \
    virt-manager \
    virt-viewer \
    cloud-utils \
    guestfs-tools \
    dnsmasq \
    bridge-utils \
    ethtool \
    || true
echo ""

# ── 2. libvirt service & user group ──────────────────────────────────────────
echo "Configuring libvirt..."
sudo usermod -aG libvirt "$USER"
sudo systemctl enable libvirtd
echo ""

# ── 3. br0 bridge ────────────────────────────────────────────────────────────
echo "=== br0 Bridge Setup ==="

# Detect active wired interface
ETH_IFACE=$(nmcli -t -f DEVICE,TYPE,STATE device \
    | awk -F: '$2=="ethernet" && $3=="connected" {print $1; exit}')
if [[ -z "$ETH_IFACE" ]]; then
    ETH_IFACE=$(nmcli -t -f DEVICE,TYPE device \
        | awk -F: '$2=="ethernet" {print $1; exit}')
fi

if [[ -z "$ETH_IFACE" ]]; then
    echo "Warning: No wired interface found — skipping bridge setup"
    echo "  (Bridge over Wi-Fi is not supported)"
else
    ETH_MAC=$(cat /sys/class/net/"$ETH_IFACE"/address)
    echo "Interface: $ETH_IFACE  (MAC: $ETH_MAC)"

    SLAVE_CON="br0-slave-${ETH_IFACE}"

    if nmcli connection show br0 &>/dev/null; then
        echo "br0 already exists — skipping bridge creation"
        # echo "Applying DNS settings to existing br0 (AdGuard DNS)..."
        # nmcli connection modify br0 \
        #     ipv4.dns "94.140.14.14 94.140.15.15" \
        #     ipv4.ignore-auto-dns yes \
        #     ipv6.dns "2a10:50c0::ad1:ff 2a10:50c0::ad2:ff" \
        #     ipv6.ignore-auto-dns yes
    else
        echo "Creating br0 (DHCP, STP off, MAC=$ETH_MAC)..."
        # Pin br0 MAC to physical NIC MAC so the router's ARP table stays stable.
        # Without this NM assigns a random MAC, which can trigger the switch's
        # MAC-flood protection when a guest VM appears on the same physical port.
        nmcli connection add \
            type bridge \
            ifname br0 \
            con-name br0 \
            ipv4.method auto \
            ipv4.dns "94.140.14.14 94.140.15.15" \
            ipv4.ignore-auto-dns yes \
            ipv6.method disabled \
            bridge.stp no \
            ethernet.cloned-mac-address "$ETH_MAC"
    fi

    if nmcli connection show "$SLAVE_CON" &>/dev/null; then
        echo "Slave connection $SLAVE_CON already exists — skipping"
    else
        echo "Adding $ETH_IFACE as bridge member..."
        nmcli connection add \
            type ethernet \
            ifname "$ETH_IFACE" \
            con-name "$SLAVE_CON" \
            master br0
    fi

    echo "Activating br0 (brief network interruption expected)..."
    nmcli connection up "$SLAVE_CON"
    nmcli connection up br0

    # Disable the old standalone Ethernet connection so it won't compete
    OLD_CON=$(nmcli -g NAME,DEVICE connection show --active \
        | awk -F: -v iface="$ETH_IFACE" -v slave="$SLAVE_CON" \
            '$2 == iface && $1 != slave {print $1}' \
        | head -1 || true)
    if [[ -n "$OLD_CON" ]]; then
        echo "Disabling old connection: $OLD_CON"
        nmcli connection down "$OLD_CON" || true
        nmcli connection modify "$OLD_CON" connection.autoconnect no
    fi
fi
echo ""

# ── 4. rp_filter ─────────────────────────────────────────────────────────────
# rp_filter=2 (strict) drops bridged packets because bridge members have no IP.
echo "=== rp_filter (sysctl) ==="
SYSCTL_FILE="/etc/sysctl.d/99-libvirt-br0.conf"
if [[ -n "$ETH_IFACE" ]]; then
    sudo tee "$SYSCTL_FILE" > /dev/null <<EOF
# rp_filter for libvirt br0 bridge
net.ipv4.conf.${ETH_IFACE}.rp_filter = 0
net.ipv4.conf.br0.rp_filter = 1
EOF
    sudo sysctl -p "$SYSCTL_FILE"
    echo "Written: $SYSCTL_FILE"
else
    echo "Skipped (no wired interface detected)"
fi
echo ""

# ── 5. NetworkManager: do not manage vnet*/tap* ───────────────────────────────
# Without this NM detects vnetN when a VM starts, runs DHCP on it, and adds
# a low-metric default route through the guest tap → host loses internet.
echo "=== NetworkManager: unmanaged vnet*/tap* ==="
NM_CONF="/etc/NetworkManager/conf.d/90-libvirt-unmanaged.conf"
if [[ -f "$NM_CONF" ]]; then
    echo "Already exists: $NM_CONF — skipping"
else
    sudo mkdir -p /etc/NetworkManager/conf.d
    sudo tee "$NM_CONF" > /dev/null <<'EOF'
[keyfile]
unmanaged-devices=interface-name:vnet*;interface-name:tap*
EOF
    sudo systemctl reload NetworkManager
    echo "Written: $NM_CONF"
fi
echo ""

# ── 6. qemu-bridge-helper: allow br0 ─────────────────────────────────────────
echo "=== qemu bridge.conf ==="
QEMU_BRIDGE="/etc/qemu/bridge.conf"
if grep -q "^allow br0$" "$QEMU_BRIDGE" 2>/dev/null; then
    echo "Already present: 'allow br0' in $QEMU_BRIDGE"
else
    sudo mkdir -p /etc/qemu
    echo "allow br0" | sudo tee -a "$QEMU_BRIDGE" > /dev/null
    echo "Added 'allow br0' to $QEMU_BRIDGE"
fi
echo ""

# ── 7. e1000e TSO fix ─────────────────────────────────────────────────────────
# e1000e TX queue stalls under heavy traffic when TSO is on (kernel Bug #118721).
# Triggered by Ubuntu 22.04 guests (kernel 5.15 virtio-net).
echo "=== e1000e TSO fix ==="
E1000E_SERVICE="/etc/systemd/system/e1000e-fix.service"

if [[ -n "$ETH_IFACE" ]]; then
    ETH_DRIVER=$(readlink "/sys/class/net/${ETH_IFACE}/device/driver" 2>/dev/null \
        | xargs basename 2>/dev/null || true)
else
    ETH_DRIVER=""
fi

if [[ "$ETH_DRIVER" == "e1000e" ]]; then
    if [[ -f "$E1000E_SERVICE" ]]; then
        echo "e1000e-fix.service already exists — skipping"
    else
        echo "e1000e detected on $ETH_IFACE — creating TSO fix service..."
        sudo tee "$E1000E_SERVICE" > /dev/null <<EOF
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
        sudo systemctl daemon-reload
        sudo systemctl enable e1000e-fix.service
        sudo systemctl start e1000e-fix.service
        echo "e1000e-fix.service enabled and started"
    fi
else
    echo "Driver '${ETH_DRIVER:-unknown}' — e1000e fix not needed"
fi
echo ""

# ── Verify ────────────────────────────────────────────────────────────────────
sleep 2
echo "=== Bridge Status ==="
ip link show br0 2>/dev/null || echo "(br0 not available)"
ip -4 addr show br0 2>/dev/null | grep -E "inet " || echo "(no IPv4 on br0 yet)"

if ip link show br0 &>/dev/null; then
    echo ""
    echo "=== DNS (br0) ==="
    if command -v resolvectl &>/dev/null; then
        resolvectl status br0 2>/dev/null | grep "DNS Servers:" \
            || echo "  (Could not read DNS from resolvectl)"
    else
        echo "  /etc/resolv.conf nameservers:"
        sudo grep "nameserver" /etc/resolv.conf 2>/dev/null || true
    fi
fi

echo ""
echo "======================================="
echo "  Virtualization setup completed!"
echo "======================================="
echo ""
echo "NOTE: Log out and back in for libvirt group membership to take effect."
echo ""
