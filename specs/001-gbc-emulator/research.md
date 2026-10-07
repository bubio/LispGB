# Phase 0 調査結果: Game Boy Color エミュレーター（LispGB）

**作成日**: 2026-10-07
**対象仕様**: [spec.md](./spec.md)

開発環境で実測した値です（Ubuntu 26.04.1 LTS / aarch64、SBCL 2.6.0.debian、ASDF 3.3.1、
SDL2 2.32.10）。検証用の使い捨てスクリプトは scratchpad で実行し、リポジトリには
入れていません。

---

## R1. 処理系

- **Decision**: SBCL を使う（ユーザー指定、インストール済み）。CI とリリースのビルドは
  Ubuntu 24.04 の apt で入る SBCL で行う。そのため、ソースは **SBCL 2.3 系以降**で
  動くように書き、新しい版にしかない機能は使わない。
- **Rationale**: SBCL はネイティブコードを生成し、型宣言を付ければ数値計算を固定長の整数演算に
  落とせる。59.7fps（SC-004）を満たすのに十分な性能が見込める。
  `sb-ext:save-lisp-and-die` で単体の実行ファイルを作れる（FR-024）。
- **Alternatives considered**: CCL と ECL は ARM64 Linux での最適化と実行ファイル生成の
  成熟度で SBCL に劣る。ユーザーが SBCL を指定しているので、これ以上は検討しない。

## R2. マルチメディア層

- **Decision**: **SDL2**（`libSDL2-2.0.so.0`）を使う（ユーザー指定）。
- **Rationale**: Ubuntu 24.04 では `libsdl2-2.0-0` が標準リポジトリにあり、導入は
  `apt install` だけで済む。SDL3 は 24.04 の標準リポジトリにない。26.04 でも
  `libsdl2-2.0-0`（2.32.10）が入っていることを確認した。
- **Alternatives considered**: SDL3（RuxBoy と同じ）は 24.04 で導入の手間が大きいので
  見送る。GLFW + OpenAL は音声と映像で依存が2つに増える。

## R3. SDL2 との接続方法（FFI）

- **Decision**: SBCL 組み込みの FFI である **`sb-alien`** を使い、必要な SDL2 関数だけを
  自前で宣言する。共有ライブラリは起動時に `load-shared-object` で
  `"libSDL2-2.0.so.0"` を `:dont-save t` 付きで読み込む。失敗した場合は、日本語で
  導入手順を案内して終了する。
- **Rationale**:
  - 実測で、`sb-alien` から `SDL_Init(VIDEO|AUDIO)` が 0（成功）を返した。
    `save-lisp-and-die` で作った実行ファイルからも同様に初期化できた。
  - 外部の Lisp ライブラリ（CFFI、cl-sdl2、cl-autowrap）が要らないので、
    **Quicklisp も不要**になる（憲法 V「依存の最小化」）。
  - 使う SDL2 の API は 30 個前後（ウィンドウ、レンダラ、テクスチャ、イベント、
    キューイング方式の音声）に収まる。RuxBoy が SDL3 に対して同じやり方
    （最小限を自前で宣言）で実装できている。
- **Alternatives considered**:
  - cl-sdl2: cl-autowrap と c2ffi が生成する仕様ファイルに依存する。aarch64-linux 向けの
    仕様ファイルがない、または古いことがあり、ビルドが不安定になる。Quicklisp も必要になる。
  - CFFI のみ: `sb-alien` で足りるので、依存を1つ増やす理由がない。

## R4. 単体の実行ファイルと配布

- **Decision**: `sb-ext:save-lisp-and-die :executable t :compression t :toplevel #'lispgb:main`
  で単体の実行ファイル `lispgb` を作る。zip にはこの実行ファイル、README、LICENSE を
  入れる。
- **Rationale**:
  - 実測で、圧縮付きの実行ファイルは約10MB だった。実行時の依存は libzstd、libm、libc
    だけで、SDL2 は起動時に動的に読み込む。
  - 要求する glibc は最大で `GLIBC_2.38` だった（26.04 でビルドした場合）。Ubuntu 24.04 の
    glibc は 2.39 なので動く。ただし、より安全にするため、**リリースのビルドは CI の
    Ubuntu 24.04（`ubuntu-24.04-arm` ランナー）で行う**。古い glibc でビルドしたものは
    新しい環境でも動く。
  - 24.04 の apt 版 SBCL がコア圧縮（`:sb-core-compression`）に対応していない場合は、
    圧縮なしで作る（サイズが増えるだけで動作は同じ）。ビルドスクリプトで
    `*features*` を見て切り替える。
- **Alternatives considered**: ソースと起動スクリプトを配布する案は、clarify の Q2 で
  不採用になった。

## R5. ビルドシステムとテストフレームワーク

- **Decision**: SBCL に同梱の **ASDF** でシステムを定義する（`lispgb.asd`。
  `lispgb/core`、`lispgb`、`lispgb/tests` の3つ）。テストは **自前の最小フレームワーク**
  （`deftest` と `is` の2つのマクロ、それに合否集計）で書く。
- **Rationale**: ASDF は SBCL に同梱されているので、追加の導入が要らない。FiveAM などの
  テストライブラリは Quicklisp が必要になるうえ、必要な機能（真偽の判定と集計）が
  少ないので、自前の方が単純（憲法 V）。
- **Alternatives considered**: FiveAM、Parachute、Rove は導入経路が増えるので見送る。
  SBCL の contrib `sb-rt` は報告の形式が粗く、テスト ROM の合否一覧と混ぜにくい。

## R6. 性能を出すための実装方針（憲法 III）

- **Decision**:
  - コアは `(declaim (optimize (speed 3) (safety 0) (debug 0)))` で**コアのファイルだけ**
    コンパイルする。テストビルドでは、ロードの前に `*features*` に `:lispgb-safe` を追加し、
    fasl の置き場所を分けて `(safety 1)` でコンパイルする（tasks T007、T008）。
  - メモリは `(simple-array (unsigned-byte 8) (*))`、フレームバッファは
    `(simple-array (unsigned-byte 32) (23040))` にする。状態は**型付きスロットの
    `defstruct`** で持つ（`(unsigned-byte 8)`、`(unsigned-byte 16)`、`fixnum`）。
  - 命令ディスパッチは、256 要素（と CB 接頭辞用の256 要素）の**関数ベクタ**にする。
    各命令の関数はマクロで生成し、デコードの分岐を実行時に残さない。
  - 汎用関数（CLOS の総称関数）はホットパスで使わない。
  - 実測で目標に届かない場合は、`sb-sprof` でプロファイルし、根拠を開発文書に記録して
    から直す（憲法 III）。
- **Rationale**: SBCL は型が確定した `fixnum` / `(unsigned-byte N)` の演算と、単純配列への
  アクセスをインラインの機械語にする。境界チェックと汎用算術を除けば、C に近い速度が
  出る。
- **Alternatives considered**: CPU を1つの巨大な `case` にする案は、コンパイル時間が長く、
  命令ごとのテストもしにくい。

## R7. 音声出力とペース配分

- **Decision**: SDL2 の**キューイング方式**（`SDL_OpenAudioDevice` にコールバックなしで
  `SDL_QueueAudio` を使う）にする。48,000Hz、ステレオ、符号付き16bit。キューに残っている
  量（`SDL_GetQueuedAudioSize`）が目標値を超えている間は待ち、下回ったら次のフレームを
  実行する（**音声駆動のペース配分**、FR-009）。
  音声デバイスが開けないときは、`SDL_GetPerformanceCounter` を使った壁時計ペースに
  切り替え、無音で動かし続ける（エッジケース）。
- **Rationale**: コールバック方式は SDL のスレッドから Lisp を呼ぶ必要があり、
  `sb-alien` のコールバックとスレッドの扱いが複雑になる。キューイング方式なら、
  メインスレッドだけで完結する。RuxBoy も同じ方式（キューの量を見るペース配分）。
- **Alternatives considered**: 22,050Hz（RuxBoy の値）。デバイスの多くは 48kHz で動くので、
  SDL 側でのリサンプリングを避けるため 48kHz にした。

## R8. 正確性の検証（憲法 I、SC-001〜003）

- **Decision**:
  - テスト ROM は、RuxBoy の `scripts/fetch_test_roms.sh` と**同じ取得元とコミット**
    （retrio/gb-test-roms `c240dd7`、Mooneye ROM ミラー `6745fe8`、mattcurrie acid2 v1.0）
    から `tests/roms/` に取得する（`.gitignore` 対象）。
  - Blargg はシリアル出力を見て `Passed` / `Failed` で判定する。`dmg_sound` は
    メモリ `$A000` の結果コードで判定する。
  - Mooneye は、`LD B,B` に到達した時点のレジスタがフィボナッチ数列
    （B=3, C=5, D=8, E=13, H=21, L=34）かどうかで判定する。
  - acid2 は、規定のフレーム数を実行したあとのフレームバッファの FNV-1a 64bit ハッシュを
    期待値と比べる。フレームバッファの形式（ARGB8888）と色変換は RuxBoy / BubiBoy Lite と
    **同じ**にし、RuxBoy のテストにある期待ハッシュを流用する。ハッシュが一致しない場合は、
    `--headless --screenshot` で出した BMP を参照画像と目視で比べて原因を調べる。
- **Rationale**: 業界で標準的な判定方法で、RuxBoy とまったく同じ基準で「同等」を示せる。
- **Alternatives considered**: acid2 の参照 PNG とピクセル単位で比べる案は、PNG を
  デコードする依存（zlib 等）が要るので見送る。ハッシュの期待値自体は、参照画像と
  目視で照合済みのもの。

## R9. ファイル形式

- **Decision**:
  - 設定ファイル: RuxBoy と同じ `key = value` の行指向テキスト（`config.txt`）。
    パースは自前で書く（[contracts/config-format.md](./contracts/config-format.md)）。
  - 最近使った ROM の一覧: 1行に1パス（`recent.txt`）。
  - セーブ RAM: 外部 RAM の生バイト列（`<ROM名>.sav`）。他のエミュレーターと互換性がある。
  - セーブステート: LispGB 独自のバイナリ形式。マジックは `LGBS`
    （[contracts/savestate-format.md](./contracts/savestate-format.md)）。
  - スクリーンショット: 非圧縮 24bit BMP（依存なしで書ける）。
  - 書き込みはすべて、一時ファイルに書いてから `rename` する（中断しても壊れない）。
- **Rationale**: 依存がなく、RuxBoy と挙動がそろう。
- **Alternatives considered**: s-expression の設定ファイルは Lisp らしいが、利用者に
  とってなじみが薄く、RuxBoy と同等にならない。

## R10. CI / CD

- **Decision**: GitHub Actions で `ubuntu-24.04-arm` ランナーを使い、
  `apt install sbcl libsdl2-dev` → `scripts/fetch_test_roms.sh` → `scripts/test.sh` →
  `scripts/build.sh` → `scripts/package_zip.sh` の順に、ローカルと同じスクリプトを呼ぶ。
  タグをプッシュしたらリリースする。
- **Rationale**: 憲法の「ローカルと CI で同じ手順」と、R4 の glibc 互換性を両方満たす。
- **注意**: ワークフローのファイルは用意するが、プッシュ（＝CI の実行）はユーザーの
  明示的な指示があるまで行わない。
