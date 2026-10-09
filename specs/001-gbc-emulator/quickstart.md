# クイックスタート（動作検証ガイド）

この仕様を実装したあとに、エンドツーエンドで動作を確認する手順です。
詳細な仕様は [contracts/](./contracts/) と [data-model.md](./data-model.md) を参照してください。

## 前提

- Linux amd64 / arm64（Ubuntu 24.04 以降）、または macOS Apple Silicon
- `sudo apt install sbcl libsdl2-dev curl zip`（実行するだけなら `libsdl2-2.0-0` で足りる）
- macOS は `brew install sbcl sdl2`（実行するだけなら `sdl2` で足りる）
- Quicklisp は不要

## 1. テスト ROM を取得して全テストを実行する（SC-001〜003）

```sh
sh scripts/fetch_test_roms.sh
sh scripts/test.sh
```

**期待される結果**: 単体テストとテスト ROM（Blargg、Mooneye、acid2）の合否が一覧表示され、
最後に `全テスト合格` と出て、終了コード 0 で終わる。ただし、既知の不合格として登録した
Mooneye の3件（`rapid_toggle`、`reti_timing`、`stat_lyc_onoff`）は、もし不合格でも
「既知」と表示され、全体の合否には含めない。

## 2. 実行ファイルをビルドする

```sh
sh scripts/build.sh
./build/lispgb --version
```

**期待される結果**: `build/lispgb` が生成され、`LispGB 0.1.0` のようにバージョンが表示される。

## 3. ヘッドレスで描画を確かめる（US4）

```sh
./build/lispgb --headless --frames 120 --screenshot /tmp/cgb-acid2.bmp tests/roms/acid2/cgb-acid2.gbc
```

**期待される結果**: ウィンドウは開かず、すぐに終了コード 0 で終わる。BMP を開くと、
cgb-acid2 の参照画像と同じ顔が描かれている。

## 4. ウィンドウでプレイする（US1）

```sh
./build/lispgb --scale 4 tests/roms/acid2/cgb-acid2.gbc
```

**期待される結果**: 640×576 のウィンドウが開いて画面が表示され、Esc で終了する。
音声と入力の確認には、入力を受け付けるフリーの ROM を使う（市販の ROM を使う場合は、
事前にユーザーに相談する）。

## 5. セーブを確かめる（US2）

- バッテリー付きのテスト ROM（`tests/roms/mooneye/emulator-only/mbc1/ram_64kb.gb` のコピー）を
  `--headless --frames 600` で実行する。`<ROM名>.sav` が RAM のサイズ（8192 バイト）で
  作られることを確認する。もう一度起動して、エラーにならないことも確認する。
- ウィンドウで実行中に F1 を押してから F3 を押し、状態が戻ることを確認する。別の ROM の
  `.state` をコピーしてから F3 を押した場合は、拒否されて実行が続くことを確認する。

## 6. CLI と設定ファイルを確かめる（US3）

```sh
./build/lispgb --help                  # 終了コード 0
./build/lispgb --scale abc x.gbc       # 終了コード 2、日本語のエラーと使い方を表示
./build/lispgb no-such-file.gbc        # 終了コード 1
./build/lispgb --recent                # 起動した ROM が新しい順に表示される
cat ~/.config/LispGB/config.txt        # 既定値で生成されている
```

## 7. 速度を確かめる（SC-004）

```sh
sh scripts/bench.sh tests/roms/blargg/cpu_instrs/cpu_instrs.gb
```

**期待される結果**: ヘッドレスで 3 倍速以上（180fps 以上）と表示される。

## 8. 配布物を作る（FR-024）

```sh
sh scripts/package_zip.sh
```

**期待される結果**: arm64 では `dist/LispGB-<version>-linux-aarch64.zip`、x86_64 では
`dist/LispGB-<version>-linux-x86_64.zip` ができる。SBCL が入っていない
Ubuntu 24.04 で、`libsdl2-2.0-0` を入れれば展開してすぐ起動できる。

## macOS のローカル検証

`sh scripts/smoke.sh` でヘッドレス実行を検証する。
`sh scripts/smoke_sdl.sh` は実ウィンドウと音声デバイスを使用し、120フレームの描画・音声出力、
SDL イベントキューを通じた入力・保存・復元・終了を検証する（物理キーの入力とは別）。
設定と保存先は一時ディレクトリに隔離する。
macOS の通常の設定先は `~/Library/Application Support/LispGB/`、
ZIP は Apple Silicon では `dist/LispGB-<version>-macos-apple-silicon.zip`、Intel では
`dist/LispGB-<version>-macos-intel.zip`。

## Windows 11 x64

Windows では、シェル版の代わりに同名の PowerShell スクリプトを使う。
全テストは `powershell -ExecutionPolicy Bypass -File scripts/test.ps1`、
ビルドは `powershell -ExecutionPolicy Bypass -File scripts/build.ps1`。
SDL2 の導入後、次のコマンドで cgb-acid2 を起動する。

```powershell
powershell -ExecutionPolicy Bypass -File scripts/fetch_test_roms.ps1
powershell -ExecutionPolicy Bypass -File scripts/fetch_sdl2.ps1
.\build\lispgb.exe tests/roms/acid2/cgb-acid2.gbc
```

設定と履歴は `%APPDATA%\LispGB\`、保存データは ROM と同じ場所に作られる。
配布 ZIP は `scripts/package_zip.ps1`、展開後の検証は `scripts/verify_windows_package.ps1`。
詳しい開発手順と検証範囲は `docs/dev/platforms.md` を参照する。
