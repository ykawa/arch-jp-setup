#!/bin/bash
set -e

REPO_URL="https://github.com/ykawa/arch-jp-setup.git"

echo "==================================================="
echo "  arch/manjaro/cachyos linux Japanese Setup Boot"
echo "==================================================="
echo ""

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "Error: git is required but not installed."
    echo "Please install git first: sudo pacman -S git"
    exit 1
fi

# 一時ディレクトリに clone する。setup.sh が ~/.local/share/arch-jp-setup へ
# .git 抜きでコピー（既存のコピーは上書き）してから、そちらで実行し直す
CLONE_DIR="$(mktemp -d /tmp/arch-jp-setup.XXXXXX)"

# Clone the repository
echo "Downloading arch-jp-setup..."
if git clone --depth 1 "$REPO_URL" "$CLONE_DIR"; then
    echo "Repository downloaded successfully"
else
    echo "Failed to download repository"
    exit 1
fi

echo ""
echo "Repository downloaded to: $CLONE_DIR"
echo ""

cd "$CLONE_DIR"

echo ""
echo "Starting setup process..."
echo "================================"
echo ""

# Run the main setup script
exec bash setup.sh
