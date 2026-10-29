#!/bin/bash
# GNOME拡張機能をインストールするスクリプト

set -euo pipefail

echo "Installing extension-manager and python-pipx..."
yay -S --noconfirm --needed \
  extension-manager \
  python-pipx

/usr/bin/pipx install gnome-extensions-cli --system-site-packages --force

# インストール確認ダイアログが出るということを伝える
gum confirm "To install Gnome extensions, you need to accept some confirmations. Ready?"

PATH="$HOME/.local/bin:$PATH"
gext install tactile@lundal.io
gext install blur-my-shell@aunetx
gext install space-bar@luchrioh
gext install undecorate@sun.wxg@gmail.com
gext install tophat@fflewddur.github.io
gext install AlphabeticalAppGrid@stuarthayhurst
gext install advanced-alt-tab@G-dH.github.com
gext install dash-to-panel@jderose9.github.com
gext enable dash-to-panel@jderose9.github.com
gext install clipboard-history@alexsaveau.dev

find ~/.local/share/gnome-shell/extensions/ -type f -print0 | grep --null-data -E '\.gschema\.xml$' | sudo xargs -0 cp -vt /usr/share/glib-2.0/schemas/
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

# Install new extensions
gsettings set org.gnome.shell.extensions.tactile grid-cols 5
gsettings set org.gnome.shell.extensions.tactile grid-rows 2
gsettings set org.gnome.shell.extensions.tactile col-0 3
gsettings set org.gnome.shell.extensions.tactile col-1 1
gsettings set org.gnome.shell.extensions.tactile col-2 1
gsettings set org.gnome.shell.extensions.tactile col-3 1
gsettings set org.gnome.shell.extensions.tactile col-4 3
gsettings set org.gnome.shell.extensions.tactile col-5 0
gsettings set org.gnome.shell.extensions.tactile row-0 2
gsettings set org.gnome.shell.extensions.tactile row-1 3
gsettings set org.gnome.shell.extensions.tactile row-2 0
gsettings set org.gnome.shell.extensions.tactile gap-size 0

# Configure Dash to Panel (customized layout)
gsettings set org.gnome.shell.extensions.dash-to-panel animate-appicon-hover false
gsettings set org.gnome.shell.extensions.dash-to-panel animate-appicon-hover-animation-extent "{'RIPPLE': 4, 'PLANK': 4, 'SIMPLE': 1}"
gsettings set org.gnome.shell.extensions.dash-to-panel appicon-margin 8
gsettings set org.gnome.shell.extensions.dash-to-panel dot-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-focused 'METRO'
gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-unfocused 'DASHES'
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps false
gsettings set org.gnome.shell.extensions.dash-to-panel hotkeys-overlay-combo 'TEMPORARILY'
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide false
gsettings reset org.gnome.shell.extensions.dash-to-panel panel-anchors
gsettings reset org.gnome.shell.extensions.dash-to-panel panel-element-positions
gsettings reset org.gnome.shell.extensions.dash-to-panel panel-lengths
gsettings set org.gnome.shell.extensions.dash-to-panel panel-position 'BOTTOM'
gsettings reset org.gnome.shell.extensions.dash-to-panel panel-positions
gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 36
gsettings set org.gnome.shell.extensions.dash-to-panel panel-sizes '{}'
gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-icon-file ''
gsettings set org.gnome.shell.extensions.dash-to-panel show-favorites false
gsettings set org.gnome.shell.extensions.dash-to-panel show-favorites-all-monitors false
gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-keep-dash false
gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-keep-top-panel false
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-title-position 'TOP'

# Configure Advanced Alt-Tab Window Switcher
gsettings set org.gnome.shell.extensions.advanced-alt-tab-window-switcher switcher-popup-preview-selected 2

# Configure Blur My Shell
gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.lockscreen blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.screenshot blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.window-list blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.panel blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.overview blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.overview pipeline 'pipeline_default'
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock brightness 0.6
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock sigma 30
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock style-dash-to-dock 0

# Configure Space Bar
gsettings set org.gnome.shell.extensions.space-bar.behavior smart-workspace-names false
gsettings set org.gnome.shell.extensions.space-bar.shortcuts enable-activate-workspace-shortcuts false
gsettings set org.gnome.shell.extensions.space-bar.shortcuts enable-move-to-workspace-shortcuts true
gsettings set org.gnome.shell.extensions.space-bar.shortcuts open-menu "@as []"

# Configure TopHat
gsettings set org.gnome.shell.extensions.tophat show-icons false
gsettings set org.gnome.shell.extensions.tophat show-cpu true
gsettings set org.gnome.shell.extensions.tophat show-disk false
gsettings set org.gnome.shell.extensions.tophat show-mem false
gsettings set org.gnome.shell.extensions.tophat show-fs false
gsettings set org.gnome.shell.extensions.tophat network-usage-unit bits

# Configure AlphabeticalAppGrid
gsettings set org.gnome.shell.extensions.alphabetical-app-grid folder-order-position 'start'
