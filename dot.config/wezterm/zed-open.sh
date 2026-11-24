#!/bin/bash
# 指定ディレクトリを Zed で開く。既に Zed が開いていれば既存ウィンドウを再利用する。
# Usage: zed-open.sh <dir> [zeditor の追加オプション...]
#
# Wayland では zeditor -e が既存ウィンドウを前面に出せず urgent になるだけなので、
# niri では urgent になった Zed ウィンドウへ明示的にフォーカスを移す。
set -u

dir="${1:?usage: zed-open.sh <dir>}"
shift
[ "$dir" = / ] || dir="${dir%/}"

zed_windows() {
    niri msg --json windows 2>/dev/null | jq -c '[.[] | select(.app_id == "dev.zed.Zed")]'
}

if [ -z "${NIRI_SOCKET:-}" ] || ! command -v jq >/dev/null; then
    exec zeditor -e "$@" "$dir"
fi

before="$(zed_windows)"
before="${before:-[]}"
zeditor -e "$@" "$dir" || exit

# 既存ウィンドウが無ければ、新規ウィンドウに niri がフォーカスを移す
[ "$(jq length <<<"$before")" -gt 0 ] || exit 0

focus() {
    exec niri msg action focus-window --id "$1"
}

# 新たに urgent になったウィンドウが、Zed が再利用先に選んだウィンドウ
now="$before"
for _ in {1..15}; do
    now="$(zed_windows)"
    id="$(jq -r --argjson b "$before" '
        ([$b[] | select(.is_urgent) | .id]) as $old
        | [.[] | select(.is_urgent and (.id as $i | $old | index($i) | not))][0].id // empty
    ' <<<"$now")"
    [ -z "$id" ] || focus "$id"
    # 新規ウィンドウが開いた、または既に Zed がフォーカスされている
    jq -e 'any(.[]; .is_focused)' <<<"$now" >/dev/null && exit 0
    sleep 0.1
done

# 以前から urgent だった場合などは、タイトル一致 → 最後に使ったウィンドウの順で選ぶ
id="$(jq -r --arg n "$(basename "$dir")" '
    (sort_by([.focus_timestamp.secs // 0, .focus_timestamp.nanos // 0]) | reverse)
    | ([.[] | select(.title == $n or ((.title // "") | startswith($n + " — ")))] + .)[0].id // empty
' <<<"$now")"
[ -z "$id" ] || focus "$id"
