#!/bin/bash
# 公開リポジトリに入れてはいけない PC 固有の情報が含まれていないか検査する
#
#   bash check-private.sh <ファイル>...            作業ツリーのファイルを検査
#   bash check-private.sh --staged <ファイル>...   git のステージ済み内容を検査（pre-commit 用）
#
# 検出するもの:
#   - /home/<ユーザー名> の絶対パス
#   - 実行ユーザー名（$USER）
#   - ~/.config/arch-jp-setup/private-words に1行1語で書いた語（メールアドレス、ホスト名など）
# 次の行は許可する:
#   - github.com / raw.githubusercontent.com の <owner>/arch-jp-setup を指す URL
#   - users.noreply.github.com のアドレス
#   - "private-check: allow" を含む行
# 問題があれば該当行を表示して 1 で終了する。
set -e

PRIVATE_WORDS_FILE="$HOME/.config/arch-jp-setup/private-words"
ALLOW_REGEX='(github\.com|githubusercontent\.com)/[A-Za-z0-9-]+/arch-jp-setup|users\.noreply\.github\.com|private-check: allow'

staged=false
if [ "$1" = "--staged" ]; then
    staged=true
    shift
fi

patterns=('/home/[A-Za-z0-9._-]+')
if [ -n "$USER" ]; then
    patterns+=("(^|[^A-Za-z0-9])${USER}([^A-Za-z0-9]|$)")
fi
if [ -f "$PRIVATE_WORDS_FILE" ]; then
    while IFS= read -r word; do
        [ -n "$word" ] && [ "${word#\#}" = "$word" ] || continue
        # 正規表現として解釈されないようにエスケープする
        patterns+=("$(printf '%s' "$word" | sed 's/[][\.*^$+?(){}|/]/\\&/g')")
    done < "$PRIVATE_WORDS_FILE"
fi
pattern=$(IFS='|'; echo "${patterns[*]}")

read_content() {
    if $staged; then
        git show ":$1" 2>/dev/null
    else
        cat -- "$1"
    fi
}

found=0
for file in "$@"; do
    $staged || [ -f "$file" ] || continue
    # バイナリは検査しない
    if read_content "$file" | head -c 8000 | LC_ALL=C grep -qP '\x00'; then
        continue
    fi
    hits=$(read_content "$file" | grep -nE -- "$pattern" | grep -vE -- "$ALLOW_REGEX" || true)
    if [ -n "$hits" ]; then
        found=1
        while IFS= read -r line; do
            echo "$file:$line"
        done <<< "$hits"
    fi
done

if [ "$found" -ne 0 ]; then
    echo ""
    echo "PC 固有の情報（ユーザー名・ホームディレクトリの絶対パスなど）が含まれています。"
    echo "~ や \$HOME に置き換えるか、意図したものなら行に \"private-check: allow\" を付けてください。"
    exit 1
fi
