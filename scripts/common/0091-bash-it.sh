#!/bin/bash
# bash-it（bash のプラグイン・補完・エイリアス集）
# @group: bash-it (bash のプラグイン集)
set -e

echo "================================"
echo "  bash-it Installation"
echo "================================"
echo ""

BASH_IT="$HOME/.bash_it"

if [ ! -d "$BASH_IT" ]; then
    echo "Installing bash-it..."
    git clone --depth=1 https://github.com/Bash-it/bash-it.git "$BASH_IT"
    "$BASH_IT/install.sh" --silent --no-modify-config
else
    echo "Updating bash-it..."
    git -C "$BASH_IT" pull --prune || true
fi

echo ""
echo "Enabling plugins, completions and aliases..."
export BASH_IT
# bash_it.sh は対話シェル向けで途中のコマンドが失敗することがあるため set -e を外す
set +e
# shellcheck source=/dev/null
source "$BASH_IT/bash_it.sh"
bash-it enable plugin git ssh history npm docker
bash-it enable completion git ssh npm docker
bash-it enable alias git docker
set -e

echo ""
echo "bash-it installation completed!"
echo "================================"
echo ""
