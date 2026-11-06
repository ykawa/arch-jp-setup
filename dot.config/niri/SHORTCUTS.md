# キーボードショートカット一覧

`Mod` は TTY 上の niri では Super、winit ウィンドウでは Alt に対応します。
以下は `cfg/keybinds.kdl` の `binds` セクションに定義されているショートカットの一覧です。

## ヘルプ
- `Mod+Shift+/`, `Mod+Shift+Esc` — ホットキー一覧を表示

## アプリケーション & ランチャー
- `Mod+T`, `Mod+Return`, `Super+Return` — 主ターミナルを起動（setup.sh で選んだもの。未選択なら Alacritty）
- `Mod+Shift+Return` — 副ターミナルを起動（ターミナルを2つ以上選んだとき）
- `Mod+D`, `Super+Space`, `Mod+Ctrl+Return` — Noctalia ランチャーを開く
- `Mod+B` — 選んだブラウザを起動（未選択なら何もしない）
- `Mod+E` — 選んだファイラーを起動（既定は Nautilus）
- `Mod+Shift+N` — 主ターミナルで Neovim を起動
- `Mod+Shift+Ctrl+A` — 主ターミナルで Claude Code を起動（`~/Work` で開始）
- `Mod+Alt+L` — 画面をロック（Noctalia）
- `Alt+Ctrl+H` — クリップボード履歴を開く（Noctalia）

## オーディオ・メディア・輝度
いずれも Noctalia の IPC 経由。ロック中も有効（`allow-when-locked`）。

- `XF86AudioRaiseVolume`, `XF86AudioLowerVolume` — 音量調整
- `XF86AudioMute`, `XF86AudioMicMute` — 出力とマイクのミュート切替
- `XF86AudioNext`, `XF86AudioPrev` — 曲送り / 曲戻し
- `XF86AudioPlay`, `XF86AudioPause`, `XF86AudioStop` — 再生 / 一時停止
- `XF86MonBrightnessUp`, `XF86MonBrightnessDown` — 輝度調整

## Overview & ウィンドウ操作
- `Mod+O` — Overview を開閉
- `Mod+Q`, `Alt+F4` — フォーカス中ウィンドウを閉じる

## フォーカス移動
- `Mod+←/→`, `Mod+H/L` — 列を左右にフォーカス
- `Mod+↑/↓`, `Mod+K/J` — ウィンドウを上下にフォーカス
- `Mod+Home`, `Mod+End` — 列の先頭 / 末尾へフォーカス
- `Mod+Shift+←/→/↑/↓`, `Mod+Shift+H/J/K/L` — モニター間でフォーカス移動

## 列・ウィンドウの移動
- `Mod+Ctrl+←/→`, `Mod+Ctrl+H/L` — 列を左右へ移動
- `Mod+Ctrl+↑/↓`, `Mod+Ctrl+K/J` — ウィンドウを上下へ移動
- `Mod+Ctrl+Home`, `Mod+Ctrl+End` — 列を先頭 / 末尾へ移動
- `Mod+Shift+Ctrl+←/→/↑/↓`, `Mod+Shift+Ctrl+H/J/K/L` — 列をモニター間で移動

## ワークスペース操作
- `Mod+PageDown` / `Mod+U`, `Mod+PageUp` / `Mod+I` — ワークスペースを上下へフォーカス
- `Mod+Ctrl+PageDown` / `Mod+Ctrl+U`, `Mod+Ctrl+PageUp` / `Mod+Ctrl+I` — 列を上下のワークスペースへ移動
- `Mod+Shift+PageDown` / `Mod+Shift+U`, `Mod+Shift+PageUp` / `Mod+Shift+I` — ワークスペース自体を上下へ移動
- `Mod+Tab` — 直前のワークスペースへ戻る
- `Mod+1`〜`Mod+9` — 指定ワークスペースへフォーカス
- `Mod+Ctrl+1`〜`Mod+Ctrl+9` — 列を指定ワークスペースへ移動
- `Mod+WheelScrollDown/Up` — ワークスペースをスクロール（150ms のクールダウン付き）
- `Mod+Ctrl+WheelScrollDown/Up` — 列をワークスペース間で移動（150ms のクールダウン付き）

## 列構成 & サイズ
- `Mod+[`, `Mod+]` — 列にウィンドウを取り込み / 追い出し
- `Mod+,` — ウィンドウを列に取り込む / `Mod+.` — 列から追い出す
- `Mod+R` — 列幅プリセット切替
- `Mod+Shift+R` — ウィンドウ高さプリセット切替
- `Mod+Ctrl+R` — ウィンドウ高さリセット
- `Mod+F`, `Mod+Shift+F` — 列の最大化 / ウィンドウの全画面化
- `Mod+Ctrl+F` — 列を残りスペースいっぱいに拡張
- `Mod+C`, `Mod+Ctrl+C` — 列 / 可視列を中央寄せ
- `Mod+;`, `Mod+:` — 列幅を 10% 単位で縮小 / 拡大
- `Mod+Shift+;`, `Mod+Shift+:` — ウィンドウ高さを 10% 単位で縮小 / 拡大
- `Mod+V`, `Mod+Shift+V` — ウィンドウをフロート化 / フロートとタイルのフォーカス切替
- `Mod+W` — 列のタブ表示切替

## スクロールベースの列操作
- `Mod+WheelScrollRight/Left` — 列を左右にフォーカス
- `Mod+Ctrl+WheelScrollRight/Left` — 列を左右へ移動
- `Mod+Shift+WheelScrollDown/Up` — 列フォーカスを右 / 左へ移動
- `Mod+Ctrl+Shift+WheelScrollDown/Up` — 列を右 / 左へ移動

## スクリーンショット
- `Print`, `Ctrl+Print`, `Alt+Print` — スクリーンショット UI / 画面全体 / ウィンドウ
- `Ctrl+Shift+1`, `Ctrl+Shift+2`, `Ctrl+Shift+3` — 上記と同じ（Print キーのない環境向け）
- 保存先は `cfg/misc.kdl` の `screenshot-path`（`~/Pictures/Screenshots/`）

## セッション & その他
- `Mod+Escape`, `Mod+Shift+Q` — Noctalia セッションメニューを開く
- `Mod+Shift+P` — モニターの電源を切る
- `Mod+Shift+E` — キーボードショートカット抑止の切替（全画面アプリにキー入力を奪われた際の脱出用）
- `Ctrl+Alt+Delete` — niri を終了
