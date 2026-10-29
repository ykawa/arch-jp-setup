# トラブルシューティング

## デスクトップ環境が検出できない

### メッセージ
```
WARNING: Could not detect current desktop environment session
Supported environments: GNOME, COSMIC, Cinnamon, niri

Checking session info:
  XDG_CURRENT_DESKTOP: not set
  XDG_SESSION_DESKTOP: not set

Only common setup scripts will be executed.
```

これはエラーではなく警告で、setup.sh は中断しない。ただし Phase 2（`scripts/desktop/<DE>/` のデスクトップ固有設定）が丸ごとスキップされ、Phase 1（`scripts/common/`）と Phase 3（`scripts/final/`）だけが実行される。

### 原因

この警告は以下の状況で発生します：

1. **SSH経由で実行**: リモートからSSH接続して実行した場合、デスクトップ環境の環境変数やプロセスにアクセスできません
2. **sudo/root実行**: `sudo bash setup.sh` で実行すると、環境変数が引き継がれません
3. **GUI起動前の実行**: システム起動直後など、デスクトップ環境が完全に起動していない
4. **TTYコンソールから実行**: Ctrl+Alt+F2などでTTYに切り替えて実行した場合

### 解決方法

#### 1. GUIセッション内のターミナルで実行（推奨）

デスクトップ環境にログインした状態で、ターミナルアプリを開いて実行してください：

```bash
cd ~/.local/share/arch-jp-setup
bash setup.sh
```

#### 2. SSH経由で実行する場合

SSH経由で実行する必要がある場合は、環境変数を明示的に設定してください：

```bash
# GNOME環境の場合
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_TYPE=wayland
bash setup.sh

# niri環境の場合
export XDG_CURRENT_DESKTOP=niri
export XDG_SESSION_TYPE=wayland
bash setup.sh

# COSMIC環境の場合
export XDG_CURRENT_DESKTOP=COSMIC
export XDG_SESSION_TYPE=wayland
bash setup.sh

# Cinnamon環境の場合
export XDG_CURRENT_DESKTOP=X-Cinnamon
export XDG_SESSION_TYPE=wayland  # またはx11
bash setup.sh
```

### デバッグ情報の確認

検出に失敗した場合、ログファイルに以下の情報が記録されます：

```bash
cat ~/setup.log
```

- `XDG_CURRENT_DESKTOP`: デスクトップ環境名
- `XDG_SESSION_DESKTOP`: セッション名

どちらも `not set` の場合、`lib/desktop-detect.sh` はプロセス検出（`gnome-shell` / `cosmic-comp` / `cosmic-panel` / `cinnamon` / `niri`）にフォールバックしている。

### 手動でのデスクトップ環境確認

現在のデスクトップ環境を手動で確認するには：

```bash
# 環境変数を確認
echo "XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP"
echo "XDG_SESSION_DESKTOP: $XDG_SESSION_DESKTOP"
echo "XDG_SESSION_TYPE: $XDG_SESSION_TYPE"

# プロセスを確認
ps aux | grep -E "(gnome-shell|cosmic-comp|cinnamon|niri)" | grep -v grep

# 検出スクリプトをテスト
cd ~/.local/share/arch-jp-setup
source lib/desktop-detect.sh
detect_desktop_environment
```

## その他の問題

### スクリプトの実行権限エラー

エラー: `Permission denied`

**解決方法**: このプロジェクトのスクリプトは`bash`コマンドで実行するため、実行権限は不要です。

```bash
# ❌ これはエラーになる可能性があります
./setup.sh

# ✅ 正しい実行方法
bash setup.sh
```

### パッケージのインストールエラー

エラー: `error: failed to prepare transaction`

**解決方法**:
1. パッケージデータベースを更新
   ```bash
   sudo pacman -Sy
   ```

2. キーリングを更新（Manjaro/CachyOSの場合）
   ```bash
   # Manjaroの場合
   sudo pacman -S manjaro-keyring

   # CachyOSの場合
   sudo pacman -S cachyos-keyring
   ```

3. 再度setup.shを実行

### fcitx5が動作しない

**症状**: 日本語入力ができない

**解決方法**:
1. システムを再起動
   ```bash
   sudo reboot
   ```

2. fcitx5が起動しているか確認
   ```bash
   ps aux | grep fcitx5
   ```

3. 手動で起動
   ```bash
   fcitx5 &
   ```

4. 環境変数を確認
   ```bash
   echo $QT_IM_MODULE
   echo $XMODIFIERS
   ```
