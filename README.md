# arch-jp-setup

自分用の Arch 系 Linux（Arch / Manjaro / CachyOS）日本語環境セットアップスクリプト。

## セットアップ

```bash
curl -fsSL https://raw.githubusercontent.com/ykawa/arch-jp-setup/main/install.sh | bash
```

clone 済みなら `bash setup.sh`。最初に入れるパッケージと既定のアプリ・テーマを選ぶ画面が出る
（選んだ内容は `~/.config/arch-jp-setup/` に保存され、次回の初期値になる）。

## 開発・設定の編集

Git の作業ディレクトリは、どの PC でも `~/Projects/arch-jp-setup` に統一する。
新しい PC に開発用のリポジトリを用意する場合は、次の場所へ clone する。

```bash
mkdir -p ~/Projects
git clone https://github.com/ykawa/arch-jp-setup.git ~/Projects/arch-jp-setup
cd ~/Projects/arch-jp-setup
```

dotfiles のインストール先は `~/.local/share/arch-jp-setup`。
設定ファイルのシンボリックリンクは、このインストール用コピーを参照する。
作業ディレクトリでの編集を反映する場合は、フルセットアップではなく
`bash scripts/link-configs.sh` を使う。

利用中の設定（インストール用コピー）を編集した場合は、次のコマンドで作業ディレクトリへ書き戻す。
書き戻し先に未コミットの変更がある場合は中止するため、先にコミットまたは退避しておく。

```bash
bash ~/.local/share/arch-jp-setup/scripts/tools/writeback.sh ~/Projects/arch-jp-setup
```

## ツール

| コマンド | 内容 |
| --- | --- |
| `bash scripts/link-configs.sh` | `~/.local/share/arch-jp-setup` へコピーし直して dotfiles を張り直す（`setup.sh` は実行しない） |
| `bash ~/.local/share/arch-jp-setup/scripts/tools/writeback.sh <作業ディレクトリ>` | コピー側で編集した内容を git の作業ディレクトリへ書き戻す（書き戻し先に未コミットの変更があれば中止） |
| `bash scripts/tools/check-private.sh <ファイル>...` | 個人情報（`/home/<ユーザー>`、ユーザー名、`~/.config/arch-jp-setup/private-words` の語）が含まれていないか検査する |
| `sudo bash scripts/tools/setup-br0.sh [<インターフェース>]` | 有線 LAN の上に libvirt 用のブリッジ `br0` を作る |
| `sudo bash scripts/tools/teardown-br0.sh [--dry-run]` | `br0` を消して有線 LAN の直接接続に戻す |
| `sudo bash scripts/tools/fix-br0.sh [--dry-run\|--undo]` | VM 起動時にホストのネットワークが切れるなど、`br0` の不具合をまとめて直す |
| `sudo bash scripts/tools/fix-e1000e.sh [<インターフェース>] [--dry-run\|--undo]` | Intel e1000e の TSO/GSO を起動時に無効にして、通信の停止（Hardware Unit Hang）を防ぐ |

`--dry-run` は変更内容を表示するだけ、`--undo` はそのスクリプトの変更を元に戻す。
