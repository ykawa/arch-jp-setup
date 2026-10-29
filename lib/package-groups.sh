#!/bin/bash
# インストールグループの選択（gum TUI）と判定
#
# scripts/common/ と scripts/final/ のスクリプトのうち、先頭コメントに
#   # @group: <表示名>
#   # @default: on|off   （省略時は on）
# を持つものが選択対象になる。@group のないスクリプトは常に実行される。
# グループIDはファイル名から番号と拡張子を除いたもの（例: 0115-neovim-install.sh → neovim-install）。

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

# 保存済みの on/off（未保存なら空）
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

# TUI でグループを選択し、結果を GROUP_SELECTION_FILE に保存する。
# 端末が使えない（または gum がない）場合は保存済みの選択、なければ @default を使う。
# TUI がキャンセルされたら 1 を返す。
select_groups() {
    local repo_root="$1"
    local -a scripts labels preselected chosen
    local script id label state selected

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
    done

    if command -v gum &>/dev/null && { : </dev/tty; } 2>/dev/null; then
        local selected_csv output
        selected_csv=$(IFS=,; echo "${preselected[*]}")
        # curl | bash 経由では標準入力がパイプなので、端末は /dev/tty から読む
        output=$(gum choose --no-limit \
            --height 30 \
            --header "インストールするグループを選択（space: 切替 / ctrl+a: 全選択 / enter: 決定）" \
            --selected "$selected_csv" \
            "${labels[@]}" </dev/tty) || return 1
        mapfile -t chosen <<< "$output"
    else
        echo "TUI を表示できないため、保存済みの選択（なければ既定値）を使います"
        chosen=("${preselected[@]}")
    fi

    mkdir -p "$(dirname "$GROUP_SELECTION_FILE")"
    : > "$GROUP_SELECTION_FILE"
    for script in "${scripts[@]}"; do
        label=$(group_label "$script")
        state="off"
        for selected in "${chosen[@]}"; do
            if [ "$selected" = "$label" ]; then
                state="on"
                break
            fi
        done
        echo "$(group_id "$script") $state" >> "$GROUP_SELECTION_FILE"
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
