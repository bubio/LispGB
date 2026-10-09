# LispGB

[English](README.md) | **日本語**

Common Lisp（SBCL）で書いた Game Boy / Game Boy Color エミュレーターです。映像・音声・入力に SDL2 を使うコマンドラインアプリで、ブート ROM は不要です。

コアは [RuxBoy](https://github.com/bubio/ruxboy) を参照して実装しました。RuxBoy のコアの移植元は BubiBoy Lite（MIT License）です。

[![Release](https://img.shields.io/github/v/release/bubio/LispGB)](https://github.com/bubio/LispGB/releases/latest)
[![CI Linux](https://github.com/bubio/LispGB/actions/workflows/ci-linux.yml/badge.svg)](https://github.com/bubio/LispGB/actions/workflows/ci-linux.yml)
[![CI macOS](https://github.com/bubio/LispGB/actions/workflows/ci-macos.yml/badge.svg)](https://github.com/bubio/LispGB/actions/workflows/ci-macos.yml)
[![CI Windows](https://github.com/bubio/LispGB/actions/workflows/ci-windows.yml/badge.svg)](https://github.com/bubio/LispGB/actions/workflows/ci-windows.yml)
[![License](https://img.shields.io/github/license/bubio/LispGB)](LICENSE)

## 機能

- Game Boy（DMG）と Game Boy Color（CGB）の画面・4チャンネルのステレオ音声
- MBC1 / MBC2 / MBC3（RTC）/ MBC5
- バッテリーセーブ、F1 / F3 によるセーブステートの保存・復元
- 表示倍率、フルスクリーン、拡大時の補間、設定ファイル、最近使った ROM の一覧
- ウィンドウと音声デバイスを使わないヘッドレス実行、BMP スクリーンショット

Blargg の CPU・音源テストと dmg-acid2 / cgb-acid2 に合格しています。Mooneye の3件（`rapid_toggle`、`reti_timing`、`stat_lyc_onoff`）は既知のタイミング差として残っています。

## 対応プラットフォーム

| 環境 | 選択する ZIP |
|---|---|
| Ubuntu 24.04 以降（amd64 / x86_64） | `LispGB-1.0.0-linux-amd64.zip` |
| Ubuntu 24.04 以降（arm64 / aarch64） | `LispGB-1.0.0-linux-arm64.zip` |
| macOS（Apple Silicon） | `LispGB-1.0.0-macos-arm64.zip` |
| macOS（Intel） | `LispGB-1.0.0-macos-amd64.zip` |
| Windows 11（x64） | `LispGB-1.0.0-windows-amd64.zip` |

macOS Intel の GUI 動作は未確認です。

## インストール

[Releases](https://github.com/bubio/LispGB/releases) から対応する ZIP をダウンロードして展開してください。実行に SBCL や Quicklisp は不要です。ROM は付属しません。

### Linux

SDL2 のランタイムを導入し、展開したディレクトリで起動します。

```sh
sudo apt install libsdl2-2.0-0
./lispgb game.gbc
```

### macOS

Homebrew または MacPorts で SDL2 を導入し、展開したディレクトリで起動します。実行ファイルと同梱の `.dylib` は同じディレクトリに置いてください。

```sh
brew install sdl2
# または: sudo port install libsdl2
./lispgb game.gbc
```

### Windows

SDL2.dll は ZIP に同梱されています。`lispgb.exe` と同じディレクトリに置いたまま、PowerShell から起動します。

```powershell
.\lispgb.exe game.gbc
```

ヘッドレス実行、`--help`、`--version`、`--recent` では SDL2 を読み込みません。

## ソースからビルド

Git でソースを取得し、リポジトリのディレクトリへ移動します。外部の Lisp パッケージやサブモジュールの取得は不要です。

```sh
git clone https://github.com/bubio/LispGB.git
cd LispGB
```

### Linux（Ubuntu 24.04 以降）

```sh
sudo apt install sbcl libsdl2-dev
sh scripts/build.sh
./build/lispgb game.gbc
```

### macOS

```sh
brew install sbcl sdl2
# または: sudo port install sbcl libsdl2
sh scripts/build.sh
./build/lispgb game.gbc
```

### Windows

x64 版 SBCL を導入し、`sbcl` を PATH に追加してから PowerShell で実行します。SDL2 の取得にはインターネット接続が必要です。

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -ExecutionPolicy Bypass -File scripts/fetch_sdl2.ps1
.\build\lispgb.exe game.gbc
```

実行ファイルは Linux / macOS では `build/lispgb`、Windows では `build/lispgb.exe` に生成されます。

## 使い方

```text
lispgb [オプション] <ROMファイル>

  -h, --help          使い方を表示
  -v, --version       バージョンを表示
  --scale N           拡大率1〜8（既定4、9以上は8に丸める）
  --fullscreen        フルスクリーン表示（--scale は無視）
  --shader KIND       nearest / smooth（既定 nearest）
  --recent            最近使った ROM の一覧を表示して終了
  --headless          ウィンドウ・音声なしで実行
  --frames N          ヘッドレスの実行フレーム数（必須）
  --screenshot PATH   終了時の画面を BMP で保存
```

```sh
./lispgb --scale 2 --shader smooth game.gbc
./lispgb --headless --frames 120 --screenshot frame.bmp game.gbc
```

Windows では `./lispgb` の代わりに `.\lispgb.exe` を使います。

### キー操作（ROM 実行中）

| キー | 機能 |
|---|---|
| 矢印キー | 十字キー |
| Z / X | B / A |
| Enter | Start |
| 右Shift | Select |
| F1 | セーブステートを保存 |
| F3 | セーブステートを復元 |
| Esc | 終了 |

### セーブ

バッテリーセーブは `<ROM名>.sav`、セーブステートは `<ROM名>.state` として ROM と同じ場所に保存します。セーブステートのスロットは1つです。別 ROM の状態や不正なデータの復元は拒否します。

サイズの違うバッテリーセーブは `.sav.bak` に退避し、既存のバックアップは残します。大切なセーブはバックアップを取ってください。RTC の終了中の経過時間は保存しません。

### 設定

初回起動時に、次の場所に `config.txt` を生成します。同じ場所の `recent.txt` に最近使った ROM を最大10件記録します。

| OS | 保存先 |
|---|---|
| Linux | `$XDG_CONFIG_HOME/LispGB/`（未設定・空の場合は `~/.config/LispGB/`） |
| macOS | `~/Library/Application Support/LispGB/` |
| Windows | `%APPDATA%\LispGB\` |

```text
scale = 4
fullscreen = false
shader = nearest
volume = 100
```

音量は0〜100です。CLI の指定が設定ファイルより優先されます。`#` 以降はコメントで、不正な項目は無視します。

## ライセンス

[MIT License](LICENSE)
