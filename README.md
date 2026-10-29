# arch/manjaro/cachyos Japanese Setup

arch系Linux の日本語環境を一括でセットアップする

```bash
curl -fsSL https://raw.githubusercontent.com/ykawa/arch-jp-setup/main/install.sh | bash
```

実行の最初に、インストールするパッケージグループを TUI（gum）で選択する。
選択は `~/.config/arch-jp-setup/selection` に保存され、再実行時の初期値になる。

リポジトリは `~/.local/share/arch-jp-setup` に `.git` 抜きでコピーされ、設定ファイルはそこへのリンクになる。
コピー側で変えた設定（アプリの画面で変えたものなど）は、次のコマンドで git の作業ディレクトリへ書き戻せる。
ユーザー名やホームディレクトリの絶対パスが含まれていると書き戻しは中止される。

```bash
bash ~/.local/share/arch-jp-setup/scripts/tools/writeback.sh <git の作業ディレクトリ>
```

## 📋 前提条件

- arch系linux （niri 推奨）がインストールされていること
  - GNOME / COSMIC / Cinnamon / niri を自動判別して設定を切り替える
  - niri 環境が最も設定が充実している（Noctalia シェル、waybar/wofi、クリップボード履歴など）
- sudo権限があること
- インターネット接続があること

---

## fcitx5 設定方針（Wayland 環境）

### 環境変数の設定場所

**`/etc/environment` は使用しない。** `~/.config/environment.d/fcitx5.conf` に設定する。

```
# ~/.config/environment.d/fcitx5.conf
XMODIFIERS=@im=fcitx
QT_IM_MODULE=wayland
```

`/etc/environment` は PAM 経由で読み込まれるため、systemd user session 配下のプロセスへの伝播が不確実（ディスプレイマネージャーの実装次第）。
`~/.config/environment.d/` は `systemd --user` が直接読み込むため、niri の `spawn-at-startup` で起動したプロセスを含む全プロセスに確実に伝播される。

### QT_IM_MODULE は `fcitx` ではなく `wayland`

`QT_IM_MODULE` は Qt がロードする入力コンテキストプラグインを選ぶ変数。
`wayland` を指定すると Qt 内蔵の Wayland 入力コンテキストが使われ、text-input-v3 プロトコル経由で fcitx5 と通信する。

- fcitx5 の Qt プラグイン (`libfcitx5platforminputcontextplugin.so`) をロードしないため、プラグイン起因のクラッシュが起きない
- XWayland / X11 専用の Qt アプリは text-input-v3 を使えないため、`XMODIFIERS=@im=fcitx` (XIM) 経由で入力する

### GTK_IM_MODULE は設定しない

Wayland 環境では `GTK_IM_MODULE=fcitx` をグローバルに設定しない。

- GTK4 アプリは Wayland text-input-v3 プロトコルをネイティブで使用するため不要
- グローバル設定すると候補ウィンドウの点滅など視覚的な不具合が発生する
- GNOME では代わりに `gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "{'Gtk/IMModule':<'fcitx'>}"` を使用

### Chrome・Slack・Electron 系アプリ

`GTK_IM_MODULE` の代わりに `--enable-wayland-ime` フラグで Wayland IM プロトコルを直接使用する。

| ファイル | 対象 |
|---|---|
| `~/.config/chrome-flags.conf` | Google Chrome |
| `~/.config/electron-flags.conf` | Electron 汎用 |
| `~/.config/typora/electron-flags.conf` | Typora |
| `~/.config/slack/command-line-flags` | Slack |

前 3 者は `dot.config/` からのシンボリックリンク。Slack だけは `~/.config/slack/` にアプリ生成ファイルが混在するため、`0190-fcitx5-base-setup.sh` がファイルを直接生成する。

```
--ozone-platform-hint=auto
--enable-wayland-ime
```

### JetBrains IDE

2026.1 以降は Wayland ネイティブ対応済み。`XMODIFIERS=@im=fcitx` のみで fcitx5 が動作する。

### fcitx5 の起動方法

**XDG autostart (`~/.config/autostart/org.fcitx.Fcitx5.desktop`) を使用する。**
systemd user service より安定しており、全デスクトップ環境で動作する。

ディストリビューションが `/etc/xdg/autostart/org.fcitx.Fcitx5.desktop` を提供している場合は、
`0190-fcitx5-base-setup.sh` はユーザー側のファイルを作らずスキップする。

### Noctalia との共存

Noctalia v5 (`noctalia` パッケージ) は Qt を使わないネイティブ C++ 実装で、
fcitx5 とは Wayland の text-input-v3 で直接やり取りする。そのため `QT_IM_MODULE` の値に関係なく競合しない。

```kdl
// dot.config/niri/cfg/autostart.kdl
spawn-at-startup "noctalia"
```

以前の v4 (`noctalia-shell` + `noctalia-qs`、Quickshell ベース) は `QT_IM_MODULE=fcitx` で
fcitx5 の Qt6 プラグインがクラッシュ (SIGSEGV) し、`env -u QT_IM_MODULE` での起動が必要だった。
v4 は開発終了しており、Arch のパッケージも v5 のソースが入っただけの壊れた状態のため導入しない。
