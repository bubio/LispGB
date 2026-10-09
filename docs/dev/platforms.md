# 環境の検証

## 2026-10-08

| 対象 | 結果 |
|---|---|
| Ubuntu 26.04.1 / arm64 / SBCL 2.6.0 | 全テスト、ビルド、実ウィンドウ、実音声、ヘッドレス、保存を検証済み |
| 環境変数のない実行 | `env -i PATH=/usr/bin:/bin ./build/lispgb --version` が `LispGB 0.1.0`、終了0 |
| SBCL を探索できない PATH | `PATH=/nonexistent` のみの環境でもバージョン表示、終了0 |
| Ubuntu 24.04 / arm64 / apt の SBCL 2.3系 | **未検証**。Docker / Podman が利用できず、コンテナ検証は実施できなかった |
| GitHub Actions の Ubuntu 24.04 arm64 | CI / Release にテスト・ビルド・実行ファイル検証を定義。未プッシュのため実行は未確認 |

実行ファイルは SBCL のランタイムとコアイメージを含み、外部の `sbcl` を起動しない。
`SBCL_HOME` 等への依存はなく、SDL2 は通常実行時に遅延ロードする。
`ldd` では libc、libm、libzstd、arm64 のローダーを参照した。
必要な GLIBC シンボルの最大バージョンは2.38だが、これは Ubuntu 24.04 上での実動作確認の代わりにはしない。

Ubuntu 24.04 の実行環境を用意できた時点で、ソースの全テストと、26.04 で作った実行ファイルの
バージョン・ヘッドレス実行を確認し、この表を更新する。

## 2026-10-09

ユーザーが Linux arm64 の動作と Linux amd64 のローカルビルド・動作を確認済み。
CI / Release は Ubuntu 24.04 の arm64 / amd64 を同じスクリプトで検証する。
amd64 は `ubuntu-24.04`、arm64 は `ubuntu-24.04-arm` を使い、ZIP の名前で区別する。

CI 整備時のローカル回帰検証: 合格128件、不合格0件、既知の不合格3件。
actionlint とシェル構文検査も合格。コミット `43f3729` の [CI](https://github.com/bubio/LispGB/actions/runs/37875115004) で
arm64 / amd64 とも全ステップ合格（テスト、ビルド、ヘッドレス120フレーム、ZIP、artifact）。

### macOS Apple Silicon

macOS 27.0.1 / arm64、SBCL 2.6.9、Homebrew SDL2 で検証。

| 検証 | 結果 |
|---|---|
| 全回帰テスト | 合格131件、不合格0件、既知の不合格3件 |
| ソースからのビルド | 成功、`LispGB 0.1.0` |
| ヘッドレス120フレーム | BMP 69,174バイト、SDL のドライバー指定が不正でも成功 |
| 配布ZIP | `LispGB-0.1.0-macos-arm64.zip`、実行ファイル・README2種・LICENSE・libzstd とそのライセンス |
| SBCL を探索できない PATH | `env -i PATH=/nonexistent ./build/lispgb --version` 成功 |
| 実ウィンドウ | cgb-acid2 の顔と文字列を目視確認。UI ツールの Esc 送信後に正常終了 |
| 実音声デバイス | `scripts/smoke_sdl.sh` で開き、120フレームを出力。聴感での音質は未検証 |
| SDL 入力イベント | B、F1 保存、F3 復元、Esc を検証。復元後の全状態一致と音声キューの消去を確認 |
| 設定・履歴 | `Library/Application Support/LispGB/` 以下に生成。XDG は Linux だけで使用 |
| macOS Intel | ライブラリ探索と ZIP 名は対応、実ビルド・実動作は未検証 |

macOS の Cocoa 初期化は、SBCL の浮動小数点例外設定によって invalid / overflow 例外に
なることを実測した。macOS の SDL FFI 呼び出し中だけ invalid / divide-by-zero / overflow
をマスクし、呼び出し後は元の設定を復元する。コアと Linux の FFI には適用しない。
Lisp のエントリポイントからは `SDL_SetMainReady` を呼ぶ。
SDL2 は dylib 名、Homebrew の arm64 / Intel 標準パス、システムの Framework の順で探索する。

UI 操作ツールで識別するため、検証時だけ一時的な .app に実行ファイルをコピーした。
配布は仕様どおり CLI の ZIP。保存・復元と B 入力は SDL イベントによる自動検証で、
物理キーによるゲーム操作は別途確認する。
T075 / T076 の検証結果はローカル環境のもの。macOS CI は T077 で別途追加した。

相対パスの ROM で F1 を使うと rename の宛先ディレクトリが二重になる不具合も確認した。
アトミック書き込みとサイズ不一致セーブの退避で、rename の宛先を絶対パスへ解決し、
相対パスの保存・上書き・バックアップの回帰テストを追加した。

Homebrew の SBCL は `libzstd.1.dylib` をリンクしているため、macOS の ZIP に zstd と BSD
ライセンスを同梱する。配布実行ファイルの参照を `@executable_path/libzstd.1.dylib` に直し、
コアを連結する前に SBCL ランタイムの参照を変更し、ランタイムと dylib をアドホック署名する。公証・Developer ID 署名は行っていない。

ZIP を別ディレクトリへ展開し、`otool -L` が zstd を実行ファイルと同じ場所から参照する
ことを確認。SBCL を探索できない環境でバージョン表示とヘッドレス120フレームが成功した。

### macOS の再ビルド（T076）

Homebrew の読み取り専用 zstd をコピーすると、その権限が残り、次のビルドの `cp` が
Permission denied で止まった。`cp -f` でコピー先を置き換え、所有者の書き込み権限を付ける。
コピー先を読み取り専用にした状態からのビルドと、続けての再ビルドを確認。
バージョン表示・ヘッドレス120フレーム・ZIP作成が成功し、全回帰テストは131件合格、
不合格0件、既知の不合格3件。

### macOS CI（T077）

ユーザーが Apple Silicon 環境でのソースビルドと動作を確認済み。
Linux の `ci.yml` と分け、`.github/workflows/ci-macos.yml` に macOS 用の CI を定義する。
[GitHub のランナー一覧](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
に従い、Apple Silicon は `macos-15`、Intel は `macos-15-intel` を使う。

| 対象 | ZIP / artifact |
|---|---|
| Apple Silicon | `LispGB-<version>-macos-arm64.zip` / `LispGB-macos-arm64` |
| Intel | `LispGB-<version>-macos-amd64.zip` / `LispGB-macos-amd64` |

各ランナーで Homebrew の SBCL / SDL2 を導入し、全テスト、ビルド、ヘッドレス120フレーム、
ZIP作成と展開後の実行を検証する。`scripts/verify_macos_package.sh` は `lipo -archs` で
実行ファイルと同梱 dylib が対象 CPU だけを持つことを確認する。ユニバーサルバイナリは作らない。
Intel の CI はヘッドレス検証であり、実ウィンドウ・実音声でのプレイ確認とは区別する。
実行結果と ZIP は GitHub Actions の「CI macOS」から参照する。

## Windows 11 x86_64（2026-10-09、T081 / T082）

SBCL 2.6.9、PowerShell 5.1、SDL2 2.32.10 x64 で検証した。
全テストは139件合格、不合格0件、既知の不合格3件。両 acid2 のハッシュも一致した。
Windows の描画処理が SBCL のゼロ除算例外を発生させたため、SDL の FFI 呼び出し中だけ
浮動小数点例外を抑制する。終了後に Lisp の例外設定が戻ることも確認した。

| 検証 | 結果 |
|---|---|
| ネイティブ描画・音声デバイス | cgb-acid2 を120フレーム描画、48kHzステレオ音声を送信、成功 |
| 入力・保存復元 | SDL キューへ B / Esc / F1 / F3 を注入し、イベント処理と状態復元、音声キュー消去を確認 |
| CI 用 dummy ドライバー | 同じ SDL スモークが合格 |
| ヘッドレス | SDL ドライバーを無効にして120フレーム、BMP は69174バイト |
| 単体実行ファイル | PATH を Windows system32 のみにし、SBCL_HOME を除去して version / help / headless が成功 |
| 配布 ZIP | 展開後に version / headless と PE の x64 machine 値を確認 |
| 性能 | cpu_instrs.gb、3000フレーム、7.3085秒、410.48fps、測定区間の割当0バイト |
| Windows CI / Release | 定義済み。未プッシュのため GitHub 上では未実行 |

実際の聞こえ方、長時間プレイ時の音切れ、物理キーボード操作は自動テストでは判定していない。
商用ゲーム ROM は使用していない。

```powershell
powershell -ExecutionPolicy Bypass -File scripts/fetch_test_roms.ps1
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -ExecutionPolicy Bypass -File scripts/fetch_sdl2.ps1
powershell -ExecutionPolicy Bypass -File scripts/smoke.ps1
powershell -ExecutionPolicy Bypass -File scripts/smoke_sdl.ps1
powershell -ExecutionPolicy Bypass -File scripts/bench.ps1
powershell -ExecutionPolicy Bypass -File scripts/package_zip.ps1
powershell -ExecutionPolicy Bypass -File scripts/verify_windows_package.ps1
```

ROM 取得のみ Git for Windows が必要。通常のビルド・テスト・配布は PowerShell と SBCL で行う。
日本語を含む .ps1 は Windows PowerShell 5.1 で読める UTF-8 BOM 形式。
SDL2 は [公式配布](https://libsdl.org/release/) の固定 ZIP を SHA256 で照合し、zlib ライセンスを同梱する。

### Windows CI の終了コード修正（T083）

[失敗した実行](https://github.com/bubio/LispGB/actions/runs/37887812343) は、ヘッドレス検証が
合格と表示した後にステップが失敗した。最後に検証した意図的な使用方法エラーの
終了コード2が LASTEXITCODE に残り、GitHub Actions の PowerShell ラッパーへ渡っていた。
通常の powershell -File による確認ではこの値がプロセス終了コードへ伝わらなかった。

エラーケースの後で --recent の正常終了と ROM 履歴を検証するようにした。
PowerShell 5.1 / 7 の両方で、スクリプトをドットソースして LASTEXITCODE を返す
CI と同じ呼び出しが終了コード0となることを確認した。実行ファイル欠落時は終了コード1。
修正後の GitHub CI は未プッシュのため未実行。
