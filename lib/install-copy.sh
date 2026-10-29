#!/bin/bash
# 配布物のコピー先（設定ファイルのリンク元）
#
# setup.sh はリポジトリを INSTALL_DIR に .git 抜きでコピーし、そこから実行し直す。
# dot.config/ などのシンボリックリンクはすべて INSTALL_DIR を指すので、
# PC ごとの値（アバター画像、Zed の検索パターンなど）はコピー側にだけ書き込まれ、
# git の作業ディレクトリには影響しない。コピー側の変更は scripts/tools/writeback.sh で書き戻す。

INSTALL_DIR="$HOME/.local/share/arch-jp-setup"

# src の内容で INSTALL_DIR を置き換える（既存のコピーは上書き）
# git 管理下なら追跡ファイル + ignore されていない未追跡ファイルだけを対象にする
copy_to_install_dir() {
    local src="$1" tmp
    src="$(cd "$src" && pwd)"

    if [ "$src" = "$INSTALL_DIR" ]; then
        return 0
    fi

    mkdir -p "$(dirname "$INSTALL_DIR")"
    tmp="$(mktemp -d "${INSTALL_DIR}.new.XXXXXX")"
    if git -C "$src" rev-parse --is-inside-work-tree &>/dev/null; then
        git -C "$src" ls-files -z --cached --others --exclude-standard \
            | while IFS= read -r -d '' path; do
                # 作業ツリーで削除済みの追跡ファイルは除く
                if [ -e "$src/$path" ] || [ -L "$src/$path" ]; then
                    printf '%s\0' "$path"
                fi
            done \
            | tar -C "$src" --null -T - -cf - \
            | tar -C "$tmp" -xf -
    else
        tar -C "$src" --exclude=.git -cf - . | tar -C "$tmp" -xf -
    fi

    rm -rf "$INSTALL_DIR"
    mv "$tmp" "$INSTALL_DIR"
}
