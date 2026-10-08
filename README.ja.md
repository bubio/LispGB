# LispGB

[English](README.md) | **日本語**

Common Lisp（SBCL）で書いた Game Boy / Game Boy Color エミュレーターです。映像・音声・入力には SDL2 を使います。コマンドラインから起動し、ブート ROM は不要です。

## 現状

実験的な実装です。DMG / CGB の描画、4チャンネルのステレオ音声、MBC1/2/3/5、バッテリーセーブ、セーブステートに対応しています。Blargg の CPU・音源テストと acid2 は合格し、Mooneye の細かなタイミング差3件が既知の不合格として残っています。大切なセーブはバックアップを残してください。

コアは [RuxBoy](https://github.com/bubio/ruxboy) を参照して実装しました。RuxBoy のコアの移植元は BubiBoy Lite です。

## 対応プラットフォーム

Linux arm64。Ubuntu 24.04 以降を対象としています。ローカルでは Ubuntu 26.04 で動作確認済みで、配布ビルドは Ubuntu 24.04 向けに設定しています。

## インストール

配布 ZIP を展開し、SDL2 の実行時ライブラリを導入してください。

```sh
sudo apt install libsdl2-2.0-0
./lispgb --version
```

実行には SBCL は不要です。ヘッドレス実行、使い方、バージョン、最近使った ROM の一覧表示では SDL2 も不要です。

## ソースからビルド

```sh
sudo apt install sbcl libsdl2-dev
sh scripts/build.sh
./build/lispgb --version
```

Quicklisp のパッケージは不要です。

## 使い方

```text
lispgb [オプション] game.gbc

  -h, --help          使い方を表示
  -v, --version       バージョンを表示
  --scale N           拡大率1〜8（既定4、9以上は8に丸める）
  --fullscreen        フルスクリーン表示
  --shader KIND       nearest / smooth（既定 nearest）
  --recent            最近使った ROM の一覧
  --headless          ウィンドウ・音声なしで実行
  --frames N          ヘッドレスの実行フレーム数（必須）
  --screenshot PATH   終了時の画像を BMP で保存
```

```sh
./lispgb --scale 4 game.gbc
./lispgb --headless --frames 120 --screenshot frame.bmp game.gbc
```

### キー操作

| キー | 機能 |
|---|---|
| 矢印キー | 十字キー |
| Z / X | B / A |
| Enter | Start |
| 右Shift | Select |
| F1 | セーブステートを保存 |
| F3 | セーブステートを復元 |
| Esc | 終了 |

バッテリーセーブは `<ROM名>.sav`、セーブステートは `<ROM名>.state` として ROM と同じ場所に保存します。サイズの違うセーブは `.sav.bak` に退避してから、新しいセーブを保存します。既存のバックアップは残します。別 ROM のセーブステートは拒否します。

### 設定

初回起動で `$XDG_CONFIG_HOME/LispGB/config.txt` を生成します。環境変数が未設定または空の場合は `~/.config/LispGB/config.txt` です。

```text
scale = 4
fullscreen = false
shader = nearest
volume = 100
```

音量は0〜100です。CLI の指定が設定ファイルより優先されます。`#` 以降はコメントで、不正な項目は無視します。同じ場所の `recent.txt` には最大10件の ROM のパスを保存します。

## ライセンス

MIT。[LICENSE](LICENSE) を参照してください。
