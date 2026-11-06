#!/usr/bin/env bash
# fix-e1000e.sh — Disable TSO/GSO on Intel e1000e NIC to prevent Hardware Unit Hang
#
# Root cause (kernel.org Bug #118721):
#   e1000e TX queue stalls under heavy traffic when TSO is enabled, triggering
#   an adapter reset and causing the host to lose network connectivity.
#   Ubuntu 22.04 guests (kernel 5.15) generate packet patterns that reliably
#   trigger this; newer guest kernels (7.0+) do not.
#
# Symptom:
#   dmesg shows: "e1000e ... Detected Hardware Unit Hang"
#                "NETDEV WATCHDOG: ... transmit queue 0 timed out"
#                "e1000e ... Reset adapter"
#
# Fix: disable TSO/GSO/GRO/SG on the host's e1000e interface via a
#      oneshot systemd service that runs at every boot.
#
# Usage:
#   sudo ./fix-e1000e.sh              # auto-detect e1000e interface
#   sudo ./fix-e1000e.sh enp0s31f6    # specify interface explicitly
#   sudo ./fix-e1000e.sh --dry-run    # show what would change, without touching anything
#   sudo ./fix-e1000e.sh --undo       # disable and remove the systemd service

set -euo pipefail

# ── argument handling ────────────────────────────────────────────────────────
DRY_RUN=false
UNDO=false
IFACE_ARG=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --undo) UNDO=true ;;
        --*)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
        *) IFACE_ARG="$arg" ;;
    esac
done

# ── helpers ──────────────────────────────────────────────────────────────────
die() {
    echo "ERROR: $*" >&2
    exit 1
}
info() { echo "[fix-e1000e] $*"; }
run() { $DRY_RUN && echo "  [DRY RUN] $*" || "$@"; }

[[ $EUID -eq 0 ]] || die "Run as root (sudo $0)"

command -v ethtool &>/dev/null || die "ethtool not found. Install with: apt install ethtool"

SERVICE_NAME="e1000e-fix"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# ── undo ─────────────────────────────────────────────────────────────────────
if $UNDO; then
    info "=== Removing ${SERVICE_NAME}.service ==="
    if systemctl is-enabled "${SERVICE_NAME}.service" &>/dev/null; then
        run systemctl disable "${SERVICE_NAME}.service"
        info "Disabled."
    else
        info "Service not enabled — skipping disable."
    fi
    if systemctl is-active "${SERVICE_NAME}.service" &>/dev/null; then
        run systemctl stop "${SERVICE_NAME}.service"
        info "Stopped."
    fi
    if [[ -f "$SERVICE_FILE" ]]; then
        run rm -f "$SERVICE_FILE"
        run systemctl daemon-reload
        info "Removed $SERVICE_FILE"
    else
        info "Not found: $SERVICE_FILE — nothing to remove."
    fi
    echo
    info "Note: TSO/GSO offload settings applied this session remain until reboot."
    info "To restore immediately:"
    # Try to detect the interface from the removed service for the hint
    info "  sudo ethtool -K <iface> tso on gso on gro on sg on"
    exit 0
fi

# ── detect e1000e interface ──────────────────────────────────────────────────
if [[ -n "$IFACE_ARG" ]]; then
    IFACE="$IFACE_ARG"
else
    IFACE=""
    for dev in /sys/class/net/*/; do
        name=$(basename "$dev")
        driver=$(readlink "${dev}device/driver" 2>/dev/null | xargs basename 2>/dev/null || true)
        if [[ "$driver" == "e1000e" ]]; then
            IFACE="$name"
            break
        fi
    done
fi

[[ -n "$IFACE" ]] || die "No e1000e interface detected. Specify one explicitly: $0 <iface>"

DRIVER=$(readlink "/sys/class/net/${IFACE}/device/driver" 2>/dev/null | xargs basename 2>/dev/null || true)
if [[ "$DRIVER" != "e1000e" ]]; then
    info "Warning: $IFACE driver is '${DRIVER:-unknown}', not 'e1000e'. Proceeding anyway."
fi

info "Target interface : $IFACE  (driver: ${DRIVER:-unknown})"
echo

# ── show current offload state ───────────────────────────────────────────────
info "Current offload state on $IFACE:"
ethtool -k "$IFACE" 2>/dev/null \
    | grep -E "tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload|scatter-gather" \
    || true
echo

# ── create service file ──────────────────────────────────────────────────────
info "=== Creating ${SERVICE_FILE} ==="

if [[ -f "$SERVICE_FILE" ]]; then
    info "Already exists — overwriting."
fi

if $DRY_RUN; then
    echo "  [DRY RUN] write $SERVICE_FILE with contents:"
    cat <<EOF
  [Unit]
  Description=Disable TSO/GSO on ${IFACE} (e1000e Hardware Unit Hang fix)
  After=network.target

  [Service]
  Type=oneshot
  ExecStart=/sbin/ethtool -K ${IFACE} tso off gso off gro off sg off
  RemainAfterExit=true

  [Install]
  WantedBy=multi-user.target
EOF
    echo "  [DRY RUN] systemctl daemon-reload"
    echo "  [DRY RUN] systemctl enable ${SERVICE_NAME}.service"
    echo "  [DRY RUN] systemctl start ${SERVICE_NAME}.service"
else
    tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=Disable TSO/GSO on ${IFACE} (e1000e Hardware Unit Hang fix)
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ethtool -K ${IFACE} tso off gso off gro off sg off
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}.service"
    systemctl start "${SERVICE_NAME}.service"
    info "Service enabled and started."
fi
echo

# ── verify ───────────────────────────────────────────────────────────────────
if ! $DRY_RUN; then
    info "=== Verification ==="
    systemctl status "${SERVICE_NAME}.service" --no-pager || true
    echo
    info "Offload state after fix:"
    ethtool -k "$IFACE" 2>/dev/null \
        | grep -E "tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload|scatter-gather" \
        || true
    echo
    info "Done. Start a guest VM with heavy traffic to verify."
    info "Monitor for hangs: sudo dmesg -w | grep -i 'e1000e\|hang\|watchdog'"
    info "To undo: sudo $0 --undo"
fi
