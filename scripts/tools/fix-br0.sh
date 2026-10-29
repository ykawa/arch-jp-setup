#!/usr/bin/env bash
# fix-br0.sh - Fix br0 bridge configuration issues for libvirt
#
# Root causes addressed:
#   1. rp_filter=2 (strict) on br0 and bridge member → drops packets under load
#   2. br0 uses a random MAC → bridge adopts guest VM MAC on start → ARP poisoning
#   3. NetworkManager manages vnet* tap devices → adds a lower-metric default route
#      via vnet0 (the guest's tap) the moment a VM starts → host loses internet
#   4. /etc/qemu/bridge.conf lacks br0 → qemu-bridge-helper rejects the bridge
#   5. e1000e TSO enabled → TX queue stalls under heavy guest traffic (kernel Bug #118721)
#      Triggered by Ubuntu 22.04 guests; only applies when bridge member uses e1000e
#
# Usage:
#   sudo ./fix-br0.sh              # auto-detect br0 and bridge member
#   sudo ./fix-br0.sh --dry-run    # show what would change, without touching anything
#   sudo ./fix-br0.sh --undo       # revert all changes made by this script

set -euo pipefail

# ── argument handling ────────────────────────────────────────────────────────
DRY_RUN=false
UNDO=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --undo)    UNDO=true ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

# ── helpers ──────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "[fix-br0] $*"; }
run()  { $DRY_RUN && echo "  [DRY RUN] $*" || "$@"; }

[[ $EUID -eq 0 ]] || die "Run as root (sudo $0)"

SYSCTL_FILE="/etc/sysctl.d/99-libvirt-br0.conf"
NM_CONF="/etc/NetworkManager/conf.d/90-libvirt-unmanaged.conf"
QEMU_BRIDGE="/etc/qemu/bridge.conf"
BR_IFACE="br0"

# ── undo ─────────────────────────────────────────────────────────────────────
if $UNDO; then
    info "=== Undo Fix 1: rp_filter ==="
    [[ -f "$SYSCTL_FILE" ]] && run rm -f "$SYSCTL_FILE" && info "Removed $SYSCTL_FILE" \
        || info "Not found: $SYSCTL_FILE"

    info "=== Undo Fix 2: br0 MAC ==="
    if nmcli connection show br0 &>/dev/null; then
        run nmcli connection modify br0 ethernet.cloned-mac-address ""
        info "Cleared cloned-mac-address. Apply: sudo nmcli connection up br0"
    else
        info "NM connection 'br0' not found."
    fi

    info "=== Undo Fix 3: NM unmanaged vnet* ==="
    [[ -f "$NM_CONF" ]] && run rm -f "$NM_CONF" && run systemctl reload NetworkManager \
        && info "Removed $NM_CONF" || info "Not found: $NM_CONF"

    info "=== Undo Fix 4: qemu bridge.conf ==="
    if [[ -f "$QEMU_BRIDGE" ]]; then
        run sed -i '/^allow br0$/d' "$QEMU_BRIDGE"
        info "Removed 'allow br0' from $QEMU_BRIDGE"
    fi

    info "=== Undo Fix 5: e1000e TSO ==="
    E1000E_SERVICE="/etc/systemd/system/e1000e-fix.service"
    if [[ -f "$E1000E_SERVICE" ]]; then
        systemctl is-enabled e1000e-fix.service &>/dev/null && run systemctl disable e1000e-fix.service
        systemctl is-active  e1000e-fix.service &>/dev/null && run systemctl stop    e1000e-fix.service
        run rm -f "$E1000E_SERVICE"
        run systemctl daemon-reload
        info "Removed $E1000E_SERVICE"
    else
        info "Not found: $E1000E_SERVICE"
    fi
    exit 0
fi

# ── detect bridge member ──────────────────────────────────────────────────────
ETH_IFACE=$(bridge link show 2>/dev/null \
    | awk -v br="$BR_IFACE" 'index($0, "master "br) {gsub(/:$/, "", $2); print $2}' \
    | grep -v '^vnet' | head -1)
[[ -n "$ETH_IFACE" ]] || die "No physical bridge member found for $BR_IFACE. Is br0 up?"

ETH_MAC=$(cat /sys/class/net/"$ETH_IFACE"/address)
[[ -n "$ETH_MAC" ]] || die "Could not read MAC from $ETH_IFACE"

info "Bridge interface : $BR_IFACE"
info "Bridge member    : $ETH_IFACE  (MAC: $ETH_MAC)"
echo

# ════════════════════════════════════════════════════════════════════════════
# Fix 1: rp_filter
# ════════════════════════════════════════════════════════════════════════════
info "=== Fix 1: rp_filter ==="
info "Problem : rp_filter=2 (strict) drops bridged packets under heavy VM traffic."
info "          Bridge members have no IP, so reverse-path checks are meaningless."
CUR_ETH=$(sysctl -n "net.ipv4.conf.${ETH_IFACE}.rp_filter" 2>/dev/null || echo "?")
CUR_BR=$(sysctl  -n "net.ipv4.conf.${BR_IFACE}.rp_filter"  2>/dev/null || echo "?")
info "Current : ${ETH_IFACE}=${CUR_ETH}  ${BR_IFACE}=${CUR_BR}"
info "Target  : ${ETH_IFACE}=0  ${BR_IFACE}=1"
echo

if $DRY_RUN; then
    echo "  [DRY RUN] write $SYSCTL_FILE"
else
    tee "$SYSCTL_FILE" > /dev/null <<EOF
# rp_filter for libvirt br0 bridge
net.ipv4.conf.${ETH_IFACE}.rp_filter = 0
net.ipv4.conf.${BR_IFACE}.rp_filter = 1
EOF
    sysctl -p "$SYSCTL_FILE"
fi
echo

# ════════════════════════════════════════════════════════════════════════════
# Fix 2: br0 MAC address
# ════════════════════════════════════════════════════════════════════════════
info "=== Fix 2: br0 MAC address ==="
info "Problem : br0 random MAC < guest VM MAC → bridge adopts guest MAC on start"
info "          → sends Gratuitous ARP claiming host IP → router routes host"
info "            return traffic to guest → host loses external connectivity."
info "Fix     : Pin br0 MAC = physical NIC MAC so it never changes."
CUR_BR_MAC=$(cat /sys/class/net/"$BR_IFACE"/address)
info "Current br0 MAC : $CUR_BR_MAC"
info "Target  br0 MAC : $ETH_MAC"
echo

if [[ "$CUR_BR_MAC" == "$ETH_MAC" ]]; then
    info "MAC already correct — skipping."
else
    info "Applying (brief network interruption) ..."
    run nmcli connection modify "$BR_IFACE" ethernet.cloned-mac-address "$ETH_MAC"
    run nmcli connection up br0
    $DRY_RUN || { sleep 2; info "New br0 MAC: $(cat /sys/class/net/br0/address)"; }
fi
echo

# ════════════════════════════════════════════════════════════════════════════
# Fix 3: NetworkManager — do not manage vnet* tap devices
# ════════════════════════════════════════════════════════════════════════════
info "=== Fix 3: NetworkManager unmanaged vnet* ==="
info "Problem : When libvirt creates vnetN (guest VM tap), NM detects it and runs"
info "          DHCP on it. NM adds a default route via vnetN with metric 100"
info "          (lower than br0's metric 425). Host traffic immediately routes"
info "          through vnetN into the guest VM, which drops it → instant internet"
info "          connectivity loss on the host the moment a VM starts."
info "Fix     : Mark vnet* and tap* as unmanaged in NetworkManager."

if [[ -f "$NM_CONF" ]]; then
    info "Already exists: $NM_CONF — skipping."
elif $DRY_RUN; then
    echo "  [DRY RUN] write $NM_CONF"
    echo "  [DRY RUN] systemctl reload NetworkManager"
else
    mkdir -p /etc/NetworkManager/conf.d
    tee "$NM_CONF" > /dev/null <<'EOF'
# Prevent NetworkManager from managing libvirt/qemu tap interfaces.
# Without this, NM runs DHCP on vnetN and installs a low-metric default
# route via the guest VM's tap device, breaking the host's internet
# connectivity the instant a VM starts.
[keyfile]
unmanaged-devices=interface-name:vnet*;interface-name:tap*
EOF
    systemctl reload NetworkManager
    info "Created $NM_CONF and reloaded NetworkManager."
fi
echo

# ════════════════════════════════════════════════════════════════════════════
# Fix 4: Allow br0 in qemu-bridge-helper
# ════════════════════════════════════════════════════════════════════════════
info "=== Fix 4: /etc/qemu/bridge.conf ==="
info "Problem : Only 'virbr0' is listed. qemu-bridge-helper refuses br0,"
info "          forcing QEMU to fall back to privileged operations or fail."

if grep -q "^allow br0$" "$QEMU_BRIDGE" 2>/dev/null; then
    info "Already present: 'allow br0' in $QEMU_BRIDGE — skipping."
else
    info "Adding 'allow br0' to $QEMU_BRIDGE"
    run bash -c "echo 'allow br0' >> $QEMU_BRIDGE"
fi
echo

# ════════════════════════════════════════════════════════════════════════════
# Fix 5: e1000e TSO offload
# ════════════════════════════════════════════════════════════════════════════
info "=== Fix 5: e1000e TSO offload ==="
E1000E_SERVICE="/etc/systemd/system/e1000e-fix.service"
ETH_DRIVER=$(readlink "/sys/class/net/${ETH_IFACE}/device/driver" 2>/dev/null | xargs basename 2>/dev/null || true)
info "Driver  : ${ETH_DRIVER:-unknown}"

if [[ "$ETH_DRIVER" != "e1000e" ]]; then
    info "$ETH_IFACE does not use e1000e — skipping."
else
    info "Problem : e1000e TX queue stalls under heavy guest traffic when TSO is on"
    info "          → host loses network connectivity (kernel.org Bug #118721)."
    info "          Triggered by Ubuntu 22.04 guests (kernel 5.15 virtio-net)."
    info "Fix     : Disable TSO/GSO/GRO/SG via oneshot systemd service at boot."

    if [[ -f "$E1000E_SERVICE" ]]; then
        info "Already exists: $E1000E_SERVICE — skipping."
    elif $DRY_RUN; then
        echo "  [DRY RUN] write $E1000E_SERVICE"
        echo "  [DRY RUN] systemctl daemon-reload"
        echo "  [DRY RUN] systemctl enable --now e1000e-fix.service"
    else
        tee "$E1000E_SERVICE" > /dev/null <<SVCEOF
[Unit]
Description=Disable TSO/GSO on ${ETH_IFACE} (e1000e Hardware Unit Hang fix)
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ethtool -K ${ETH_IFACE} tso off gso off gro off sg off
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
SVCEOF
        systemctl daemon-reload
        systemctl enable e1000e-fix.service
        systemctl start e1000e-fix.service
        info "e1000e-fix.service enabled and started."
    fi
fi
echo

# ════════════════════════════════════════════════════════════════════════════
# Verify
# ════════════════════════════════════════════════════════════════════════════
if ! $DRY_RUN; then
    info "=== Verification ==="
    sysctl "net.ipv4.conf.${ETH_IFACE}.rp_filter" \
           "net.ipv4.conf.${BR_IFACE}.rp_filter"
    echo "br0 MAC   : $(cat /sys/class/net/br0/address)"
    echo "br0 IP    : $(ip -4 addr show br0 | awk '/inet /{print $2}')"
    echo "NM conf   : $NM_CONF"
    echo "QEMU conf : $(grep 'allow' $QEMU_BRIDGE | tr '\n' ' ')"
    if [[ -f "$E1000E_SERVICE" ]]; then
        echo "e1000e    : $(systemctl is-enabled e1000e-fix.service 2>/dev/null) ($(systemctl is-active e1000e-fix.service 2>/dev/null))"
    else
        echo "e1000e    : not applicable (driver: ${ETH_DRIVER:-unknown})"
    fi
    info "Done. Start a guest VM to verify connectivity."
fi
