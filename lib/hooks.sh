#!/bin/bash
# 外部フック（プライベートな設定など、このリポジトリに入れない処理）の実行
#
# ~/.config/arch-jp-setup/hooks.d/*.sh を名前順に bash で実行する。
# setup.sh と scripts/link-configs.sh の最後に呼ばれ、フックには次の環境変数を渡す。
#   INSTALL_DIR            … ~/.local/share/arch-jp-setup（リンク元のコピー）
#   ARCH_JP_SETUP_CALLER   … setup / link-configs
# フックは ~/.config/arch-jp-setup/ の値ファイル（lib/local-settings.sh 参照）を書いてよく、
# 実行後にそれらの値をコピーへ反映し直す。フックが失敗しても全体は止めない。

HOOKS_DIR="$HOME/.config/arch-jp-setup/hooks.d"

run_hooks() {
    local repo_root="$1" caller="$2" hook

    for hook in "$HOOKS_DIR"/*.sh; do
        [ -e "$hook" ] || continue
        echo "Running hook: $(basename "$hook")"
        if ! INSTALL_DIR="$repo_root" ARCH_JP_SETUP_CALLER="$caller" bash "$hook"; then
            echo "WARNING: hook failed: $hook"
        fi
    done

    # フックが書いた値をコピーへ反映する（リンクはコピーを指しているので即時に効く）
    apply_local_settings "$repo_root"
}
