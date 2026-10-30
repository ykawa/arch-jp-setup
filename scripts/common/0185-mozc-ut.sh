#!/bin/bash
# Mozc を UT 辞書入り（mozc-ut + fcitx5-mozc-ut、AUR で mozc 本体ごとビルド）にする
# @group: Mozc UT 辞書 (mozc-ut / ビルドに時間がかかる)
# @default: off
set -e

echo "================================"
echo "  Mozc UT Dictionary Installation"
echo "================================"
echo ""

# 辞書は mozc 本体（mozc-ut）に組み込まれる。fcitx5-mozc-ut は fcitx5 との接続部分だけ。
# 公式の fcitx5-mozc や UT なしの mozc とは競合するため、置き換えの確認を paru の --useask で自動承認する。
# 失敗しても止めず、0190-fcitx5-base-setup.sh が公式の fcitx5-mozc を入れる。
echo "Building and installing mozc-ut and fcitx5-mozc-ut (this takes a while)..."
if ! paru -S --needed --noconfirm --useask mozc-ut fcitx5-mozc-ut; then
    echo "WARNING: mozc-ut could not be installed; the official fcitx5-mozc will be used instead"
fi

echo ""
echo "Mozc UT dictionary installation completed!"
echo "================================"
echo ""
