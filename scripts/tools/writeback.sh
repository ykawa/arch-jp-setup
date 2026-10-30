#!/bin/bash
# ~/.local/share/arch-jp-setup（INSTALL_DIR）の変更を git の作業ディレクトリへ書き戻す
#
#   bash writeback.sh <git の作業ディレクトリ>
#   例: bash ~/.local/share/arch-jp-setup/scripts/tools/writeback.sh ~/Study/arch-jp-setup
#
# - 書き戻し先に未コミットの変更があれば中止する（git で確認・取り消しができるように）
# - 書き戻し先の .gitignore（グローバル ignore 含む）で除外されるファイルは対象外
# - PC ごとの値（Zed の file_scan_inclusions、gitignore の個人用パターン）は書き戻し先の値のまま残す
# - INSTALL_DIR で削除されたファイルは書き戻し先からも削除する
# - 書き戻す内容に PC 固有の情報があれば、何も書き換えずに中止する（check-private.sh）
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../../lib/install-copy.sh"
source "$SCRIPT_DIR/../../lib/local-settings.sh"

# PC ごとの値を持つ行（<ファイル> <行の正規表現>）。書き戻し先にある同じ行で置き換える
LOCAL_LINES=(
    'dot.config/zed/settings.json ^[[:space:]]*"file_scan_inclusions":'
    'dot.config/gtk-3.0/settings.ini ^gtk-theme-name='
    'dot.config/gtk-3.0/settings.ini ^gtk-icon-theme-name='
    'dot.config/gtk-3.0/settings.ini ^gtk-cursor-theme-name='
    'dot.config/gtk-4.0/settings.ini ^gtk-theme-name='
    'dot.config/gtk-4.0/settings.ini ^gtk-icon-theme-name='
    'dot.config/gtk-4.0/settings.ini ^gtk-cursor-theme-name='
)

# PC ごとの値を持つ範囲（マーカー行の間）。書き戻し先にある同じ範囲で置き換える
LOCAL_BLOCKS=(
    'dot.config/git/ignore'
)

DEST="$1"
if [ -z "$DEST" ]; then
    echo "Usage: bash $0 <git の作業ディレクトリ>"
    exit 1
fi
DEST="$(cd "$DEST" && pwd)"
SRC="$INSTALL_DIR"

echo "======================================="
echo "  Write Back"
echo "  $SRC → $DEST"
echo "======================================="
echo ""

if [ ! -d "$SRC" ]; then
    echo "Error: $SRC がありません"
    exit 1
fi
if [ "$(git -C "$DEST" rev-parse --show-toplevel 2>/dev/null)" != "$DEST" ] || [ ! -f "$DEST/setup.sh" ]; then
    echo "Error: $DEST は arch-jp-setup の git 作業ディレクトリではありません"
    exit 1
fi
if [ -n "$(git -C "$DEST" status --porcelain)" ]; then
    echo "Error: $DEST に未コミットの変更があります。コミットするか退避してから実行してください"
    git -C "$DEST" status --short
    exit 1
fi

# コミット時の検査を有効にする
git -C "$DEST" config core.hooksPath .githooks

# 書き戻し対象（INSTALL_DIR のファイルのうち、書き戻し先で ignore されないもの）
mapfile -t src_files < <(cd "$SRC" && find . \( -type f -o -type l \) -printf '%P\n' | sort)
mapfile -t ignored < <(printf '%s\n' "${src_files[@]}" | git -C "$DEST" check-ignore --no-index --stdin || true)
mapfile -t files < <(comm -23 <(printf '%s\n' "${src_files[@]}") <(printf '%s\n' "${ignored[@]}" | sort))

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

(cd "$SRC" && printf '%s\0' "${files[@]}" | tar --null -T - -cf -) | tar -C "$STAGE" -xf -

# PC ごとの値を書き戻し先の値に戻す
for entry in "${LOCAL_LINES[@]}"; do
    file="${entry%% *}"
    regex="${entry#* }"
    [ -f "$STAGE/$file" ] && [ -f "$DEST/$file" ] || continue
    dest_line=$(grep -m1 -E -- "$regex" "$DEST/$file" || true)
    [ -n "$dest_line" ] || continue
    awk -v re="$regex" -v line="$dest_line" '$0 ~ re { print line; next } { print }' \
        "$STAGE/$file" > "$STAGE/$file.tmp"
    mv "$STAGE/$file.tmp" "$STAGE/$file"
done

for file in "${LOCAL_BLOCKS[@]}"; do
    [ -f "$STAGE/$file" ] && [ -f "$DEST/$file" ] || continue
    awk -v begin="$GIT_IGNORE_LOCAL_BEGIN" -v end="$GIT_IGNORE_LOCAL_END" -v dest="$DEST/$file" '
        BEGIN {
            while ((getline line < dest) > 0) {
                if (line == begin) { inside = 1; continue }
                if (line == end) { inside = 0; continue }
                if (inside) block[++n] = line
            }
        }
        $0 == begin { print; for (i = 1; i <= n; i++) print block[i]; skip = 1; next }
        $0 == end { skip = 0 }
        !skip { print }
    ' "$STAGE/$file" > "$STAGE/$file.tmp"
    mv "$STAGE/$file.tmp" "$STAGE/$file"
done

# 変更されるファイルだけを検査する
changed=()
for file in "${files[@]}"; do
    if [ ! -e "$DEST/$file" ] || ! cmp -s "$STAGE/$file" "$DEST/$file"; then
        changed+=("$file")
    fi
done
if [ ${#changed[@]} -gt 0 ]; then
    echo "Checking for private information..."
    if ! (cd "$STAGE" && bash "$SCRIPT_DIR/check-private.sh" "${changed[@]}"); then
        echo ""
        echo "書き戻しを中止しました（$DEST は変更していません）"
        exit 1
    fi
fi

# 書き戻し
for file in "${changed[@]}"; do
    mkdir -p "$(dirname "$DEST/$file")"
    rm -f "$DEST/$file"
    cp -a "$STAGE/$file" "$DEST/$file"
done

# INSTALL_DIR で削除された追跡ファイルを削除
mapfile -t tracked < <(git -C "$DEST" ls-files | sort)
mapfile -t removed < <(comm -23 <(printf '%s\n' "${tracked[@]}") <(printf '%s\n' "${src_files[@]}"))
for file in "${removed[@]}"; do
    [ -n "$file" ] || continue
    rm -f "$DEST/$file"
    rmdir -p --ignore-fail-on-non-empty "$(dirname "$DEST/$file")" 2>/dev/null || true
done

echo ""
echo "Write back completed."
git -C "$DEST" status --short
