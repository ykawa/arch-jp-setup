#!/bin/bash
# 入れたアプリ・テーマの中から既定を決める（入れていないものは設定に書かない）
#
# グループのスクリプトに
#   # @provides: <パッケージ名> <種類> <値> [<.desktop ファイル名>]
# を書くと、そのパッケージを入れたときに <種類> の候補になる。種類は次のとおり。
#   gtk / icon / cursor … GTK テーマ・アイコン・カーソル（値はテーマ名）
#   terminal            … ターミナル（値はコマンド名）。2つ以上入れると副ターミナル terminal2 も選ぶ
#                         （副ターミナルは入れたターミナル全部から選べる。初期値は主ターミナル以外の先頭）
#   filer / browser     … ファイラー・ブラウザ（値はコマンド名）
# 種類ごとに、候補が1つならそれ、2つ以上なら TUI で選んだものを既定にして
# ~/.config/arch-jp-setup/defaults に "<種類> <値>" で保存する。候補がなければ保存しない
# （テーマは Adwaita、それ以外は各デスクトップ環境の既定のまま）。

DEFAULTS_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$DEFAULTS_LIB_DIR/package-groups.sh"

DEFAULTS_SETTING_FILE="$HOME/.config/arch-jp-setup/defaults"
DEFAULT_KINDS=(gtk icon cursor terminal terminal2 filer browser)
THEME_FALLBACK="Adwaita"

declare -A DEFAULT_KIND_LABELS=(
    [gtk]="GTK テーマ"
    [icon]="アイコン"
    [cursor]="カーソル"
    [terminal]="主ターミナル（Mod+Return）"
    [terminal2]="副ターミナル（Mod+Shift+Return）"
    [filer]="ファイラー（Mod+E）"
    [browser]="ブラウザ（Mod+B）"
)

# @provides 行を "<パッケージ名> <種類> <値> [<.desktop>]" で1行ずつ出力する
provides_entries() {
    sed -n 's/^# @provides:[[:space:]]*//p' "$1"
}

# 入れると選ばれている @provides を "<種類> <値> <パッケージ名> [<.desktop>]" で出力する
selected_provides() {
    local repo_root="$1" script pkg kind value desktop
    while IFS= read -r script; do
        is_group_selected "$script" || continue
        while read -r pkg kind value desktop; do
            [ "$(item_state "$script" "$(group_items "$script" | awk -v p="$pkg" '$1 == p')")" = "on" ] || continue
            echo "$kind $value $pkg $desktop"
        done < <(provides_entries "$script")
    done < <(list_group_scripts "$repo_root")
}

# 保存した既定（なければ空）
default_value() {
    [ -f "$DEFAULTS_SETTING_FILE" ] || return 0
    awk -v kind="$1" '$1 == kind { print $2 }' "$DEFAULTS_SETTING_FILE"
}

# 既定の値に対応する .desktop ファイル名（@provides の4列目）
default_desktop_file() {
    local repo_root="$1" kind="$2" value
    value=$(default_value "$kind")
    [ -n "$value" ] || return 0
    [ "$kind" = "terminal2" ] && kind="terminal"
    while IFS= read -r script; do
        provides_entries "$script" | awk -v k="$kind" -v v="$value" '$2 == k && $3 == v { print $4; exit }'
    done < <(list_group_scripts "$repo_root") | head -n1
}

# 種類ごとの既定を決めて保存する。候補が複数ある種類は TUI で選ぶ（キャンセルで 1 を返す）
select_defaults() {
    local repo_root="$1" kind source_kind value pkg desktop saved choice preselected i line entry_kind
    local -a provided candidates labels
    local -A chosen

    mapfile -t provided < <(selected_provides "$repo_root")

    for kind in "${DEFAULT_KINDS[@]}"; do
        source_kind="$kind"
        [ "$kind" = "terminal2" ] && source_kind="terminal"
        candidates=()
        labels=()
        for line in "${provided[@]}"; do
            read -r entry_kind value pkg desktop <<<"$line"
            [ "$entry_kind" = "$source_kind" ] || continue
            candidates+=("$value")
            labels+=("$value（$pkg）")
        done
        # 副ターミナルはターミナルを2つ以上入れるときだけ
        if [ "$kind" = "terminal2" ] && [ ${#candidates[@]} -lt 2 ]; then
            candidates=()
        fi

        saved=$(default_value "$kind")
        case ${#candidates[@]} in
            0) chosen[$kind]="" ;;
            1) chosen[$kind]="${candidates[0]}" ;;
            *)
                chosen[$kind]="${candidates[0]}"
                # 副ターミナルの初期値は主ターミナル以外の先頭
                if [ "$kind" = "terminal2" ]; then
                    for value in "${candidates[@]}"; do
                        [ "$value" != "${chosen[terminal]}" ] && {
                            chosen[$kind]="$value"
                            break
                        }
                    done
                fi
                for value in "${candidates[@]}"; do
                    [ "$value" = "$saved" ] && chosen[$kind]="$saved"
                done
                if tui_available; then
                    preselected=""
                    for i in "${!candidates[@]}"; do
                        [ "${candidates[$i]}" = "${chosen[$kind]}" ] && preselected="${labels[$i]}"
                    done
                    choice=$(gum choose \
                        --header "${DEFAULT_KIND_LABELS[$kind]}を選択（enter: 決定）" \
                        --selected "$preselected" \
                        "${labels[@]}" </dev/tty) || return 1
                    chosen[$kind]="${choice%%（*}"
                fi
                ;;
        esac
    done

    mkdir -p "$(dirname "$DEFAULTS_SETTING_FILE")"
    : >"$DEFAULTS_SETTING_FILE"
    for kind in "${DEFAULT_KINDS[@]}"; do
        [ -n "${chosen[$kind]}" ] || continue
        echo "$kind ${chosen[$kind]}" >>"$DEFAULTS_SETTING_FILE"
    done
}

# テーマがこの PC に入っているか（カーソルは cursors ディレクトリがあるもの）
theme_installed() {
    local kind="$1" name="$2" dir
    local -a dirs
    if [ "$kind" = "gtk" ]; then
        dirs=(/usr/share/themes "$HOME/.local/share/themes" "$HOME/.themes")
    else
        dirs=(/usr/share/icons "$HOME/.local/share/icons" "$HOME/.icons")
    fi
    for dir in "${dirs[@]}"; do
        if [ "$kind" = "cursor" ]; then
            [ -d "$dir/$name/cursors" ] && return 0
        else
            [ -d "$dir/$name" ] && return 0
        fi
    done
    return 1
}

# 設定ファイルに書くテーマ名。保存した既定（なければ第2引数の今の値）が入っていなければ Adwaita
theme_value() {
    local kind="$1" name
    name=$(default_value "$kind")
    [ -n "$name" ] || name="$2"
    if [ -n "$name" ] && theme_installed "$kind" "$name"; then
        echo "$name"
    else
        echo "$THEME_FALLBACK"
    fi
}

# INSTALL_DIR のコピーにある GTK の設定へテーマ名を書き込む
apply_theme_settings() {
    local install_dir="$1" gtk icon cursor file current
    current="$install_dir/dot.config/gtk-3.0/settings.ini"
    gtk=$(theme_value gtk "$(sed -n 's/^gtk-theme-name=//p' "$current" 2>/dev/null)")
    icon=$(theme_value icon "$(sed -n 's/^gtk-icon-theme-name=//p' "$current" 2>/dev/null)")
    cursor=$(theme_value cursor "$(sed -n 's/^gtk-cursor-theme-name=//p' "$current" 2>/dev/null)")

    for file in "$install_dir"/dot.config/gtk-3.0/settings.ini "$install_dir"/dot.config/gtk-4.0/settings.ini; do
        [ -f "$file" ] || continue
        sed -i \
            -e "s|^gtk-theme-name=.*|gtk-theme-name=$gtk|" \
            -e "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=$icon|" \
            -e "s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=$cursor|" \
            "$file"
    done
}
