#!/bin/bash
# PC ごとの設定（リポジトリには入れず、INSTALL_DIR のコピーにだけ反映する値）
#
# 選んだ値は ~/.config/arch-jp-setup/ に保存し、再実行時の初期値にする。
#   avatar                     … "<種類> <値>"（github <アカウント> / url <URL> / file <パス> / none）
#   zed-file-scan-inclusions   … Zed の file_scan_inclusions に入れる glob（カンマ区切り）
#   git-ignore-local           … グローバル gitignore に足す個人用パターン（1行1パターン）

LOCAL_SETTINGS_DIR="$HOME/.config/arch-jp-setup"
AVATAR_SETTING_FILE="$LOCAL_SETTINGS_DIR/avatar"
ZED_INCLUSIONS_SETTING_FILE="$LOCAL_SETTINGS_DIR/zed-file-scan-inclusions"
GIT_IGNORE_LOCAL_SETTING_FILE="$LOCAL_SETTINGS_DIR/git-ignore-local"

# dot.config/git/ignore の中で PC ごとのパターンに置き換える範囲
GIT_IGNORE_LOCAL_BEGIN="# >>> local patterns"
GIT_IGNORE_LOCAL_END="# <<< local patterns"

# INSTALL_DIR 配下の画像（dot.config/noctalia/config.toml がこのパスを参照する）
AVATAR_IMAGE_RELPATH="images/avatar.png"

_can_prompt() {
    command -v gum &>/dev/null && { : </dev/tty; } 2>/dev/null
}

_write_setting() {
    mkdir -p "$LOCAL_SETTINGS_DIR"
    echo "$2" > "$1"
}

_read_setting() {
    [ -f "$1" ] && cat "$1"
    return 0
}

# Noctalia のアバター画像の取得元を選ぶ
select_avatar_source() {
    local saved kind value choice
    saved=$(_read_setting "$AVATAR_SETTING_FILE")

    if ! _can_prompt; then
        [ -n "$saved" ] || _write_setting "$AVATAR_SETTING_FILE" "none"
        return 0
    fi

    kind="${saved%% *}"
    value=""
    [ "$kind" = "$saved" ] || value="${saved#* }"

    local -A labels=(
        [github]="GitHub アカウントのアイコン"
        [url]="URL を指定"
        [file]="ローカルファイル"
        [none]="設定しない"
    )
    choice=$(gum choose \
        --header "Noctalia のアバター画像（現在: ${saved:-未設定}）" \
        --selected "${labels[${kind:-none}]:-${labels[none]}}" \
        "${labels[github]}" "${labels[url]}" "${labels[file]}" "${labels[none]}" </dev/tty) || return 1

    case "$choice" in
        "${labels[github]}")
            [ "$kind" = "github" ] || value=""
            value=$(gum input --header "GitHub アカウント名" --value "$value" </dev/tty) || return 1
            _write_setting "$AVATAR_SETTING_FILE" "github $value"
            ;;
        "${labels[url]}")
            [ "$kind" = "url" ] || value=""
            value=$(gum input --header "画像の URL" --placeholder "https://..." --value "$value" </dev/tty) || return 1
            _write_setting "$AVATAR_SETTING_FILE" "url $value"
            ;;
        "${labels[file]}")
            [ "$kind" = "file" ] || value=""
            # shellcheck disable=SC2088  # プレースホルダーとして表示するだけ
            value=$(gum input --header "画像ファイルのパス" --placeholder "~/Pictures/avatar.png" --value "$value" </dev/tty) || return 1
            _write_setting "$AVATAR_SETTING_FILE" "file $value"
            ;;
        *)
            _write_setting "$AVATAR_SETTING_FILE" "none"
            ;;
    esac
}

# Zed の file_scan_inclusions（.gitignore されていても検索対象にする glob）を入力する
select_zed_file_scan_inclusions() {
    local saved value
    saved=$(_read_setting "$ZED_INCLUSIONS_SETTING_FILE")

    if ! _can_prompt; then
        [ -f "$ZED_INCLUSIONS_SETTING_FILE" ] || _write_setting "$ZED_INCLUSIONS_SETTING_FILE" ""
        return 0
    fi

    value=$(gum input \
        --header "Zed: .gitignore されていても検索対象にする glob（カンマ区切り、空なら無し）" \
        --placeholder "*memo*, *.local.md" \
        --value "$saved" </dev/tty) || return 1
    _write_setting "$ZED_INCLUSIONS_SETTING_FILE" "$value"
}

# 保存した取得元から INSTALL_DIR/images/avatar.png を用意する（失敗しても止めない）
fetch_avatar_image() {
    local install_dir="$1" saved kind value dest
    saved=$(_read_setting "$AVATAR_SETTING_FILE")
    kind="${saved%% *}"
    value="${saved#* }"
    dest="$install_dir/$AVATAR_IMAGE_RELPATH"

    mkdir -p "$(dirname "$dest")"
    rm -f "$dest"

    case "$kind" in
        github)
            curl -fsSL -o "$dest" "https://github.com/${value}.png?size=512" \
                || echo "WARNING: GitHub のアイコンを取得できませんでした: $value"
            ;;
        url)
            curl -fsSL -o "$dest" "$value" \
                || echo "WARNING: 画像を取得できませんでした: $value"
            ;;
        file)
            value="${value/#\~/$HOME}"
            cp -f "$value" "$dest" \
                || echo "WARNING: 画像ファイルをコピーできませんでした: $value"
            ;;
        *)
            echo "アバター画像は設定しません"
            ;;
    esac
    return 0
}

# INSTALL_DIR のコピーにある Zed の settings.json へ file_scan_inclusions を書き込む
apply_zed_file_scan_inclusions() {
    local settings="$1" saved json item
    local -a items
    saved=$(_read_setting "$ZED_INCLUSIONS_SETTING_FILE")

    json=""
    IFS=',' read -ra items <<< "$saved"
    for item in "${items[@]}"; do
        item="$(echo "$item" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        [ -n "$item" ] || continue
        json+="${json:+, }\"${item//\"/\\\"}\""
    done

    json="${json//\\/\\\\}"
    json="${json//|/\\|}"
    json="${json//&/\\&}"
    sed -i "s|^\([[:space:]]*\"file_scan_inclusions\":\).*|\1 [${json}],|" "$settings"
}

# グローバル gitignore に足す個人用パターン（自分の名前を含むメモファイルなど）を入力する
select_git_ignore_local() {
    local saved value
    saved=$(_read_setting "$GIT_IGNORE_LOCAL_SETTING_FILE")

    if ! _can_prompt; then
        [ -f "$GIT_IGNORE_LOCAL_SETTING_FILE" ] || _write_setting "$GIT_IGNORE_LOCAL_SETTING_FILE" ""
        return 0
    fi

    value=$(gum write \
        --header "git: 全リポジトリで無視する個人用パターン（1行1パターン、空なら無し。ctrl+d で決定）" \
        --placeholder "*.memo" \
        --value "$saved" </dev/tty) || return 1
    _write_setting "$GIT_IGNORE_LOCAL_SETTING_FILE" "$value"
}

# INSTALL_DIR のコピーにある dot.config/git/ignore のマーカー間を保存したパターンで置き換える
apply_git_ignore_local() {
    local ignore_file="$1" patterns_file
    patterns_file="$GIT_IGNORE_LOCAL_SETTING_FILE"
    [ -f "$patterns_file" ] || patterns_file=/dev/null

    awk -v begin="$GIT_IGNORE_LOCAL_BEGIN" -v end="$GIT_IGNORE_LOCAL_END" -v patterns="$patterns_file" '
        $0 == begin {
            print
            while ((getline line < patterns) > 0) {
                if (line != "") print line
            }
            skip = 1
            next
        }
        $0 == end { skip = 0 }
        !skip { print }
    ' "$ignore_file" > "$ignore_file.tmp"
    mv "$ignore_file.tmp" "$ignore_file"
}
