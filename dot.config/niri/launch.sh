#!/bin/bash
# niri のキーから、setup.sh で選んだ既定のアプリを起動する
#
#   launch.sh terminal  [-d <ディレクトリ>] [--class <名前>] [--bare] [-- <コマンド>...]   主ターミナル
#   launch.sh terminal2 [同上]                                                    副ターミナル
#   launch.sh filer | browser
#
# --bare はタブバー・スクロールバー・余白・透過をなくす（スクリーンセーバー用。wezterm のみ効く）
#
# 既定は ~/.config/arch-jp-setup/defaults（lib/defaults.sh が書く）。
# 主ターミナルが未設定なら niri の既定の alacritty を使い、ほかが未設定なら何もしない。

DEFAULTS_FILE="$HOME/.config/arch-jp-setup/defaults"

default_value() {
    [ -f "$DEFAULTS_FILE" ] || return 0
    awk -v kind="$1" '$1 == kind { print $2 }' "$DEFAULTS_FILE"
}

role="$1"
shift
app=$(default_value "$role")

case "$role" in
    filer | browser)
        [ -n "$app" ] || exit 0
        exec "$app" "$@"
        ;;
    terminal | terminal2)
        if [ -z "$app" ]; then
            [ "$role" = "terminal" ] || exit 0
            app="alacritty"
        fi
        ;;
    *)
        echo "Usage: $0 terminal|terminal2|filer|browser" >&2
        exit 1
        ;;
esac

dir=""
class=""
bare=false
while [ $# -gt 0 ]; do
    case "$1" in
        -d) dir="$2"; shift 2 ;;
        --class) class="$2"; shift 2 ;;
        --bare) bare=true; shift ;;
        --) shift; break ;;
        *) break ;;
    esac
done

# ターミナルごとに、ディレクトリ・クラス（app-id）・実行コマンドの渡し方が違う
args=()
case "$app" in
    alacritty)
        args=(--option "window.startup_mode='Windowed'")
        [ -n "$class" ] && args+=(--class "$class")
        [ -n "$dir" ] && args+=(--working-directory "$dir")
        [ $# -gt 0 ] && args+=(-e "$@")
        ;;
    foot)
        [ -n "$class" ] && args+=(--app-id "$class")
        [ -n "$dir" ] && args+=(-D "$dir")
        args+=("$@")
        ;;
    wezterm)
        if $bare; then
            args=(--config enable_tab_bar=false --config enable_scroll_bar=false
                --config window_background_opacity=1.0
                --config 'window_padding={left=0,right=0,top=0,bottom=0}')
        fi
        args+=(start)
        [ -n "$class" ] && args+=(--class "$class")
        [ -n "$dir" ] && args+=(--cwd "$dir")
        [ $# -gt 0 ] && args+=(-- "$@")
        ;;
    kitty)
        [ -n "$class" ] && args+=(--class "$class")
        [ -n "$dir" ] && args+=(-d "$dir")
        args+=("$@")
        ;;
    ghostty)
        [ -n "$class" ] && args+=("--class=$class")
        [ -n "$dir" ] && args+=("--working-directory=$dir")
        [ $# -gt 0 ] && args+=(-e "$@")
        ;;
    *)
        args+=("$@")
        ;;
esac

exec "$app" "${args[@]}"
