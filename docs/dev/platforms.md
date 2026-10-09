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
actionlint とシェル構文検査も合格。CI 上のビルド・ZIP 検証はプッシュ後に確認する。
