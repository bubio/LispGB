# アーキテクチャ

## 境界

ASDF の `lispgb/core` は ROM のバイト列と入力状態を受け取り、フレームバッファと音声を返す。
SDL2、時計、ファイル I/O は `lispgb` に置く。テストとヘッドレス起動は SDL2 をロードしない。
外部 Lisp ライブラリは使わず、ASDF、SBCL の FFI と実行ファイル生成を使う。

## Common Lisp の設計

状態は型付き `defstruct`、メモリは専用要素型の単純配列で持つ。CPU は命令の規則から
マクロで256個の通常命令と256個の CB 命令の関数を生成し、関数ベクタで実行する。
レジスタ対の読み書きもマクロで生成し、AF の下位ビットの制約を一か所に置く。

セーブステートは `define-state-codec` のスロット宣言を共通に使い、保存・復元・サイズ計算の
走査を生成する。真偽値は1バイト、レジスタは幅に応じた整数、時間の端数は符号付き64bitで
固定順に保存する。マジック、バージョン、ROM 識別、長さを確認した後、別マシンへ復号し、
内部値の検証を通過した場合だけ公開マシンの状態を入れ替える。出力音声は復元せず0クリアする。
形式の詳細と順序は `src/core/savestate.lisp` と仕様の `contracts/savestate-format.md` を参照。

## 時間と周辺機器

CPU のメモリアクセスは4 Tサイクル単位で Timer、PPU、APU、DMA を進める。
倍速では Timer は CPU クロック、映像と音源はドットクロックで進む。フレームは70224ドットの
累積目標で区切り、命令境界の端数を次へ引き継ぐ。

PPU はモード境界でスキャンラインを描き、DMG の X優先と CGB の OAM優先を切り替える。
タイル属性、VRAM バンク、パレット、ウィンドウの内部行番号を扱う。STAT は信号の
立ち上がりで要求する。OAM DMA は160バイト、VRAM DMA は16バイトずつ転送する。
VRAM DMA の停止時間は1ブロック32ドットで、参照実装の8 Tサイクルから修正した。
[Pan Docs の転送時間](https://gbdev.io/pandocs/CGB_Registers.html#transfer-timings)を根拠とした。

APU は波形、フレームシーケンサー、48kHz のサンプル境界までまとめて積分する。
Blargg の音源12本に合わせ、長さカウンタ、周期0のスイープ、DMG の波形 RAM アクセス窓と
再トリガー時の破壊を検証した。リングバッファはステレオ S16 の8192フレームを持つ。

MBC は1つの構造体で ROM-only / MBC1 / MBC2 / MBC3 / MBC5 を扱う。
RTC の現在時刻はアプリが渡すため、コアの実行は OS の時計を読まない。

## SDL2 と保存

`sb-alien` から SDL2 を遅延ロードする。関数署名は環境の SDL2 ヘッダと照合し、イベントの
サイズ・オフセットと音声構造体は C の `sizeof` / `offsetof` でも検証した。
映像と音声の単純配列を `with-pinned-objects` で固定し、コピーを増やさずに FFI へ渡す。
音声はキュー方式で、4フレーム分を超えたら待つ。デバイス不在時は性能カウンタで速度を保つ。

`.sav` は書き込みのない60フレーム後と終了時に保存する。F1 / F3 は `.state` を保存・復元し、
復元後に SDL の音声キューを消去する。ファイルは同じディレクトリの一時ファイルを書き終えて
から rename する。設定・履歴は XDG の場所に置き、テストは専用ディレクトリを使う。

## ビルドと検証

`scripts/test.sh` は `:lispgb-safe` と `build/fasl-safe/` を使用する。
通常ビルドは `build/fasl/` を使用し、異なる最適化指定のキャッシュを混ぜない。
`save-lisp-and-die` の `:save-runtime-options t` で `--help` 等を SBCL に解釈させず、
アプリへ渡す。コア圧縮は処理系の対応時だけ指定する。

ローカルと CI は同じ取得・テスト・ビルド・実行ファイル検証・ZIP生成のスクリプトを使う。
CI と Release の YAML は構文確認済みだが、GitHub へのプッシュ・公開は実施していない。
Actions の記法は [checkout](https://github.com/actions/checkout)、
[upload-artifact](https://github.com/actions/upload-artifact)、
[action-gh-release](https://github.com/softprops/action-gh-release) の公式 README と照合した。
