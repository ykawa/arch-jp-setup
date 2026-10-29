#!/bin/bash
# dot.config/ 配下と dot.* をホームディレクトリにシンボリックリンクする
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$REPO_ROOT/lib/link-config.sh"
source "$REPO_ROOT/lib/install-copy.sh"
source "$REPO_ROOT/lib/local-settings.sh"
source "$REPO_ROOT/lib/hooks.sh"

# リンク元は INSTALL_DIR のコピー（リポジトリから実行されたらコピーしてから実行し直す）
if [ "$REPO_ROOT" != "$INSTALL_DIR" ]; then
    echo "Copying $REPO_ROOT to $INSTALL_DIR ..."
    copy_to_install_dir "$REPO_ROOT"
    exec bash "$INSTALL_DIR/scripts/link-configs.sh" "$@"
fi

echo "================================"
echo "  Linking dot.config/ → ~/.config/"
echo "================================"
echo ""

mkdir -p "$HOME/.config"

# コピーし直すと PC ごとの値が消えるので、保存済みの設定から再適用する
apply_local_settings "$REPO_ROOT"
if [ -f "$AVATAR_SETTING_FILE" ]; then
    fetch_avatar_image "$REPO_ROOT"
fi

# dot.config/<name> → ~/.config/<name>
for item in "$REPO_ROOT/dot.config/"*; do
    [ -e "$item" ] || continue
    link_dotconfig "$(basename "$item")" "$REPO_ROOT"
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
run_hooks "$REPO_ROOT" link-configs

echo ""
echo "================================"
echo "  All configs linked!"
echo "================================"
echo ""
