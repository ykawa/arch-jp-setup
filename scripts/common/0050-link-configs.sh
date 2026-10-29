#!/bin/bash
# dot.config/ 配下と dot.* をホームディレクトリにシンボリックリンクする
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/lib/link-config.sh"
source "$REPO_ROOT/lib/install-copy.sh"
source "$REPO_ROOT/lib/local-settings.sh"

echo "================================"
echo "  Linking dot.config/ → ~/.config/"
echo "================================"
echo ""

mkdir -p "$HOME/.config"

# 個人用の gitignore パターンは INSTALL_DIR のコピーにだけ書き込む
if [ "$REPO_ROOT" = "$INSTALL_DIR" ]; then
    apply_git_ignore_local "$REPO_ROOT/dot.config/git/ignore"
fi

# dot.config/<name> → ~/.config/<name>
# mozc は 0190-fcitx5-base-setup.sh が cp で処理するためスキップ
for item in "$REPO_ROOT/dot.config/"*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    [ "$name" = "mozc" ] && continue
    link_dotconfig "$name" "$REPO_ROOT"
done

# dot.<name> → ~/.<name>  (e.g. dot.cinnamon/ → ~/.cinnamon/, dot.zshrc → ~/.zshrc)
for item in "$REPO_ROOT/dot."*; do
    [ -e "$item" ] || continue
    basename="$(basename "$item")"
    # skip dot.config (handled above)
    [ "$basename" = "dot.config" ] && continue
    dirname="${basename#dot.}"
    link_dothome "$dirname" "$REPO_ROOT"
done

echo ""
echo "================================"
echo "  All configs linked!"
echo "================================"
echo ""
