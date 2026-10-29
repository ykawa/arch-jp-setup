#!/bin/bash
# パスワードロックアウトを無効化する設定
set -e

echo "================================"
echo "  Faillock Configuration"
echo "================================"
echo ""

FAILLOCK_CONF="/etc/security/faillock.conf"

# Check if faillock.conf exists
if [ ! -f "$FAILLOCK_CONF" ]; then
    echo "Warning: $FAILLOCK_CONF not found. Skipping faillock configuration."
    echo ""
    exit 0
fi

# Check if deny = 0 is already set
if grep -q "^deny = 0$" "$FAILLOCK_CONF"; then
    echo "Faillock is already configured (deny = 0). Skipping."
    echo ""
    exit 0
fi

echo "Configuring faillock to disable account lockout (deny = 0)..."

# Backup the original file
sudo cp "$FAILLOCK_CONF" "$FAILLOCK_CONF.backup.$(date +%Y%m%d-%H%M%S)"

# Replace or add deny = 0 setting
if grep -q "^deny =" "$FAILLOCK_CONF"; then
    # Replace existing deny setting
    sudo sed -i 's/^deny = .*/deny = 0/' "$FAILLOCK_CONF"
elif grep -q "^# deny =" "$FAILLOCK_CONF"; then
    # Uncomment and set to 0
    sudo sed -i 's/^# deny = .*/deny = 0/' "$FAILLOCK_CONF"
else
    # Add deny = 0 to the file
    echo "deny = 0" | sudo tee -a "$FAILLOCK_CONF" > /dev/null
fi

echo "Faillock configuration updated successfully."
echo ""

echo "================================"
echo "  Faillock setup completed!"
echo "================================"
echo ""
