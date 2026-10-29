#!/bin/bash
# 必要なパッケージをインストール
set -e

# lib32パッケージは使わないので全て削除する
pacman -Q | grep -E '^lib32-' | cut -f1 -d' ' | sudo xargs --no-run-if-empty pacman -Rns --noconfirm

# pacmanのパッケージを更新する（初回はエラーを無視する）
sudo pacman --noconfirm -Syu || true

# pacman-keyringを更新する
sudo pacman -S --needed --noconfirm archlinux-keyring

# manjaro系linuxの場合
if [ -f /etc/manjaro-release ]; then
    sudo pacman -S --needed --noconfirm manjaro-keyring
    sudo pacman-mirrors -c Japan
fi

# cachyos系linuxの場合
if [ -f /etc/cachyos-release ]; then
    sudo pacman -S --needed --noconfirm cachyos-keyring
fi

# パッケージを更新する
sudo pacman --noconfirm -Syu

# base-devel をインストールする
sudo pacman -S --needed --noconfirm base-devel

# yay をインストールする
sudo pacman -S --needed --noconfirm yay

# yayのパッケージを更新する
yay --noconfirm -Syu

# paru をインストールする
yay -S --needed --noconfirm paru

# paruのパッケージを更新する
paru --noconfirm -Syu

# NTP時刻同期を有効化する
sudo timedatectl set-ntp true
sudo systemctl enable --now systemd-timesyncd.service
