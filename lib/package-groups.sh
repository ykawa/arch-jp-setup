#!/bin/bash
# インストールグループの選択（gum TUI）と判定
#
# scripts/common/ と scripts/final/ のスクリプトのうち、先頭コメントに
#   # @group: <表示名>
#   # @default: on|off   （省略時は on）
# を持つものが選択対象になる。@group のないスクリプトは常に実行される。
# グループIDはファイル名から番号と拡張子を除いたもの（例: 0115-neovim-install.sh → neovim-install）。
#
# 機能が重なるパッケージを持つグループは、さらに
#   # @item: <パッケージ名> [説明] [@off]   （@off を付けると既定で入れない）
# を並べると、グループを選んだあとに入れるものを個別に選べる。
# スクリプトは install_selected_items "$0" で選ばれたパッケージだけを入れる。
# 選択は GROUP_SELECTION_FILE に "<グループID>:<パッケージ名> on|off" として保存される。

GROUP_SELECTION_FILE="$HOME/.config/arch-jp-setup/selection"

group_id() {
    local name
    name=$(basename "$1" .sh)
    echo "${name#[0-9][0-9][0-9][0-9]-}"
}

group_label() {
    sed -n 's/^# @group:[[:space:]]*//p' "$1" | head -n1
}

group_default() {
    local value
    value=$(sed -n 's/^# @default:[[:space:]]*//p' "$1" | head -n1)
    if [ "$value" = "off" ]; then
        echo "off"
    else
        echo "on"
    fi
}

# @item 行（"<パッケージ名> [説明] [@off]"）を1行ずつ出力する
group_items() {
    sed -n 's/^# @item:[[:space:]]*//p' "$1"
}

# @item 行の TUI 表示名（@off を除いたもの。先頭の単語がパッケージ名）
item_display() {
    local line="$1"
    echo "${line% @off}"
}

item_default() {
    case "$1" in
        *" @off") echo "off" ;;
        *) echo "on" ;;
    esac
}

# 保存済みの on/off（未保存なら空）。アイテムは "<グループID>:<パッケージ名>" で引く
saved_group_state() {
    [ -f "$GROUP_SELECTION_FILE" ] || return 0
    awk -v id="$1" '$1 == id { print $2 }' "$GROUP_SELECTION_FILE"
}

# 選択対象のスクリプトを1行ずつ出力する
list_group_scripts() {
    local repo_root="$1" script
    for script in "$repo_root"/scripts/common/*.sh "$repo_root"/scripts/final/*.sh; do
        if [ -n "$(group_label "$script")" ]; then
            echo "$script"
        fi
    done
}

# アイテムの on/off（保存済み、なければ @off の有無）
item_state() {
    local script="$1" line="$2" state
    state=$(saved_group_state "$(group_id "$script"):${line%% *}")
    [ -n "$state" ] || state=$(item_default "$line")
    echo "$state"
}

# TUI を使えるか
tui_available() {
    command -v gum &>/dev/null && { : </dev/tty; } 2>/dev/null
}

# TUI でグループを選択し、結果を GROUP_SELECTION_FILE に保存する。
# 選んだグループのうち @item を持つものは、続けて入れるパッケージを選ぶ。
# 端末が使えない（または gum がない）場合は保存済みの選択、なければ @default / @off を使う。
# TUI がキャンセルされたら 1 を返す。
select_groups() {
    local repo_root="$1"
    local -a scripts labels preselected chosen lines item_lines
    local script id label state selected line selected_csv output
    local -A group_on item_on

    mapfile -t scripts < <(list_group_scripts "$repo_root")
    for script in "${scripts[@]}"; do
        id=$(group_id "$script")
        label=$(group_label "$script")
        state=$(saved_group_state "$id")
        [ -n "$state" ] || state=$(group_default "$script")
        labels+=("$label")
        if [ "$state" = "on" ]; then
            preselected+=("$label")
        fi
        mapfile -t lines < <(group_items "$script")
        for line in "${lines[@]}"; do
            item_on["$id:${line%% *}"]=$(item_state "$script" "$line")
        done
    done

    if tui_available; then
        selected_csv=$(IFS=,; echo "${preselected[*]}")
        # curl | bash 経由では標準入力がパイプなので、端末は /dev/tty から読む
        output=$(gum choose --no-limit \
            --height 30 \
            --header "インストールするグループを選択（tab または x: 切替 / ctrl+a: 全選択 / enter: 決定）" \
            --selected "$selected_csv" \
            "${labels[@]}" </dev/tty) || return 1
        mapfile -t chosen <<< "$output"
    else
        echo "TUI を表示できないため、保存済みの選択（なければ既定値）を使います"
        chosen=("${preselected[@]}")
    fi

    for script in "${scripts[@]}"; do
        id=$(group_id "$script")
        label=$(group_label "$script")
        group_on["$id"]="off"
        for selected in "${chosen[@]}"; do
            if [ "$selected" = "$label" ]; then
                group_on["$id"]="on"
                break
            fi
        done

        # 選んだグループのアイテムを選ぶ（選ばなかったグループのアイテムは前回の値のまま）
        [ "${group_on[$id]}" = "on" ] && tui_available || continue
        mapfile -t lines < <(group_items "$script")
        [ ${#lines[@]} -gt 0 ] || continue
        local -a displays=() item_preselected=() item_chosen=()
        for line in "${lines[@]}"; do
            displays+=("$(item_display "$line")")
            if [ "${item_on[$id:${line%% *}]}" = "on" ]; then
                item_preselected+=("$(item_display "$line")")
            fi
        done
        selected_csv=$(IFS=,; echo "${item_preselected[*]}")
        output=$(gum choose --no-limit \
            --height 30 \
            --header "${label}: 入れるものを選択（tab または x: 切替 / enter: 決定）" \
            --selected "$selected_csv" \
            "${displays[@]}" </dev/tty) || return 1
        mapfile -t item_chosen <<< "$output"
        for line in "${lines[@]}"; do
            item_on["$id:${line%% *}"]="off"
            for selected in "${item_chosen[@]}"; do
                if [ "${selected%% *}" = "${line%% *}" ]; then
                    item_on["$id:${line%% *}"]="on"
                    break
                fi
            done
        done
    done

    mkdir -p "$(dirname "$GROUP_SELECTION_FILE")"
    : > "$GROUP_SELECTION_FILE"
    for script in "${scripts[@]}"; do
        id=$(group_id "$script")
        echo "$id ${group_on[$id]}" >> "$GROUP_SELECTION_FILE"
        mapfile -t lines < <(group_items "$script")
        for line in "${lines[@]}"; do
            echo "$id:${line%% *} ${item_on[$id:${line%% *}]}" >> "$GROUP_SELECTION_FILE"
        done
    done
}

# スクリプトを実行すべきなら 0 を返す（@group なしは常に実行）
is_group_selected() {
    local script="$1" state
    [ -n "$(group_label "$script")" ] || return 0
    state=$(saved_group_state "$(group_id "$script")")
    [ -n "$state" ] || state=$(group_default "$script")
    [ "$state" = "on" ]
}

# 選ばれた @item のパッケージ名を1行ずつ出力する
selected_items() {
    local script="$1" line
    while IFS= read -r line; do
        if [ "$(item_state "$script" "$line")" = "on" ]; then
            echo "${line%% *}"
        fi
    done < <(group_items "$script")
}

# 選ばれた @item のパッケージを入れる（追加の paru オプションは引数で渡す）。
# 失敗しても止めない（入れられないパッケージが1つあっても全体を止めないため）
install_selected_items() {
    local script="$1"
    shift
    local -a packages
    mapfile -t packages < <(selected_items "$script")
    if [ ${#packages[@]} -eq 0 ]; then
        echo "選択されたパッケージがありません"
        return 0
    fi
    echo "Installing: ${packages[*]}"
    paru -S --needed --noconfirm "$@" "${packages[@]}" || true
}
