---

description: "LispGB（Game Boy Color エミュレーター）の実装タスク一覧"
---

# Tasks: Game Boy Color エミュレーター（LispGB）

**Input**: Design documents from `specs/001-gbc-emulator/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: 必須です。憲法 II（テスト先行と回帰防止）と、spec の US4 と FR-021〜022 で要求されています。
各コンポーネントのテストは、実装より先に書き、実装前に失敗することを確認します。

**Organization**: ユーザーストーリーごとにまとめています。エミュレーションのコアは US1（プレイ）が
成り立つための中身そのものなので、US1 の中でコンポーネントごとに分けています。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列に実行できる（別ファイルで、未完了のタスクに依存しない）
- **[Story]**: どのユーザーストーリーのタスクか（US1〜US4）

## 全タスク共通の約束

- **参照実装**: RuxBoy（`~/Develop/ruxboy`）。各タスクの「移植元」は、そこにあるファイルの
  ロジックを Common Lisp に書き直すという意味です。RuxBoy の移植元（BubiBoy Lite）は
  `~/dev/_Emu/BubiBoyLite/` ですが、このマシンにあるとは限らないので、RuxBoy を優先します。
- **コアの最適化宣言**: `src/core/*.lisp` の先頭では、`src/core/types.lisp` で定義する
  `+core-optimize+` を使います（research R6）。
- **言語**: コメント、docstring、ユーザー向けメッセージは日本語。識別子は英語の kebab-case。
- **ユーザー名を残さない**: パスは `~` / `$HOME` で書きます。
- **タスクが1つ完了するごとにコミットする**（1タスク＝1コミット。テストが合格してから。
  メッセージの1行目は `T012: Bus とメモリマップを実装` のようにタスク ID で始める）。
- **プッシュはしない**（ユーザーの明示的な指示があるまで）。
- **テスト先行と「全テスト合格でコミット」の両立**（憲法 II と v1.1.0 のコミット規定）: テストを
  先に書くタスクでは、新しく書いたテストを実行して**想定どおり失敗すること**を確かめたうえで、
  `register-pending` で実装するタスクの ID を指定して登録し、`scripts/test.sh` が合格する状態で
  コミットする。実装するタスクでは、該当の `register-pending` を消して合格させてからコミットする。
  対応は次のとおり。

  | テストを書くタスク | 実装して印を外すタスク |
  |---|---|
  | T013（Bus） | T012（T012 が先に終わっていれば印は不要） |
  | T014（CPU） | T016 |
  | T020（Timer） | T021 |
  | T023（PPU） | T024 |
  | T027（MBC） | T028 |
  | T030（APU） | T031 |
  | T033（CGB） | T034 |
  | T036（ジョイパッド） | T037 |
  | T046（セーブステート） | T047 |
  | T053（BMP） | T054 |
  | T058（CLI） | T060 |
  | T059（設定・一覧） | T061（設定）、T062（一覧） |

  テスト ROM のスイート（T018、T022、T026、T029、T032、T035）は、対応する実装が終わってから
  書くので、印は不要。合格しない ROM があれば、`register-known-failure`（RuxBoy でも不合格の
  3件）か、原因を直すまでタスクを完了扱いにしない。
- 実際のパスはリポジトリルート `~/Develop/LispGB/` からの相対パスです。

---

## Phase 1: Setup（共通の基盤）

**Purpose**: リポジトリの骨組み、ビルド定義、スクリプト

- [X] T001 plan.md の Project Structure どおりにディレクトリを作る（`src/core/`、`src/app/`、`tests/unit/`、`tests/suites/`、`tests/roms/`、`scripts/`、`.github/workflows/`、`docs/dev/`、`build/`、`dist/`）。`.gitignore` に `tests/roms/`、`build/`、`dist/`、`*.fasl`、`*.sav`、`*.state` を書く。最後に `git init -b main` し、既存の `.specify/`、`.claude/`、`specs/` を含めて、最初のコミット「T001: プロジェクトの骨組みを作成」を作る
- [X] T002 ASDF の定義を `lispgb.asd` に書く。システムは3つ: `lispgb/core`（`src/core/` を plan の順で `:serial t`）、`lispgb`（`lispgb/core` と `src/app/` に依存）、`lispgb/tests`（両方と `tests/` に依存）。外部の依存は書かない（research R5）
- [ ] T003 [P] `scripts/get_version.sh` を作る。`lispgb.asd` の `:version`（初期値 `"0.1.0"`）を標準出力に出す
- [ ] T004 [P] テスト ROM の取得スクリプト `scripts/fetch_test_roms.sh` を作る。`~/Develop/ruxboy/scripts/fetch_test_roms.sh` から、**取得元、コミットハッシュ、ROM の一覧をそのまま**移す（Blargg `cpu_instrs`（個別と統合）、`instr_timing`、`dmg_sound`。Mooneye の acceptance（timer / interrupts / ppu ほか）と emulator-only の mbc1 / mbc2 / mbc5。dmg-acid2 と cgb-acid2）。保存先は `tests/roms/`。再実行しても安全にする（取得済みならスキップ）
- [ ] T005 [P] `LICENSE`（MIT。年は 2026、著作者名は RuxBoy の LICENSE と同じ表記）を作る

---

## Phase 2: Foundational（全ストーリーの前提）

**Purpose**: テストフレームワーク、テスト ROM の判定基盤、コアの型と骨組み

**⚠️ CRITICAL**: これが終わるまで、ユーザーストーリーの作業は始めない

- [ ] T006 自前のテストフレームワークを `tests/framework.lisp` に書く。`(deftest name () ...)` で登録し、`(is form &optional message)` で判定する。`(run-tests &key only)` は全テストを実行して `PASS`/`FAIL` と名前を1行ずつ出し、失敗数を返す。`(register-known-failure name reason)` で既知の不合格を登録でき、そのテストは失敗しても `KNOWN` と表示して失敗数に数えない。`(register-pending name until-task)` で実装待ちのテストを登録でき、そのテストは失敗しても `PENDING (T016 待ち)` のように表示して失敗数に数えない。ただし、実装待ちのテストが**合格した**場合は `PENDING だが合格: 登録を外すこと` と警告する（印の外し忘れを防ぐため）
- [ ] T007 `scripts/test.sh` を作る。`sbcl --non-interactive` で、ロードの前に `(push :lispgb-safe *features*)` を実行する。さらに、コンパイル済みファイル（fasl）の置き場所を `build/fasl-safe/` に分けてから（`asdf:initialize-output-translations` を使う）、`lispgb/tests` をロードし、`run-tests` を実行する。通常のビルド（T044）は `build/fasl/` を使い、両者の fasl が混ざらないようにする。失敗数が 0 なら `全テスト合格` と出して終了コード 0、そうでなければ 1 で終わる。`tests/roms/` がない場合は ROM のテストをスキップし、その旨を表示する
- [ ] T008 コアのパッケージと型を `src/core/package.lisp` と `src/core/types.lisp` に書く。パッケージは `lispgb.core`。型は `u8`、`u16`、`u32`、`octets` = `(simple-array (unsigned-byte 8) (*))`。最適化の指定は、関数 `core-optimize-spec` が**読み込み時**に `*features*` を見て決める（実行時に変数を束縛しても、コンパイル済みのコードには効かないため）。`:lispgb-safe` があれば `(optimize (speed 1) (safety 1) (debug 2))`、なければ `(optimize (speed 3) (safety 0) (debug 0))` を返す。各コアファイルの先頭で `(declaim #.(lispgb.core::core-optimize-spec))` のように使う。インラインのビット操作（`bit-set-p`、`set-bit`、`wrap8`、`wrap16`）も定義する。あわせて、公開 API の**空の関数**を `src/core/machine.lisp` に作る（`make-machine`、`run-frame`、`machine-framebuffer`、`machine-serial-log`、`machine-cpu-registers`（a〜l、sp、pc を plist で返す）、`machine-ld-b-b-hit-p`、`machine-read-byte`、`set-buttons`、`drain-audio`）。中身は「未実装」というエラーを通知するだけにし、`lispgb.core` から export する
- [ ] T009 カートリッジのヘッダ解析を `src/core/cartridge.lisp` に書く。data-model.md の CartridgeHeader（title、cgb-flag、cartridge-type、rom-size、ram-size、header-checksum、global-checksum）を持つ構造体を作る。cartridge-type から mbc-kind（`:rom-only` / `:mbc1` / `:mbc2` / `:mbc3` / `:mbc5`）と、RAM・バッテリー・RTC の有無を引く表を、`~/Develop/ruxboy/Packages/Core/Src/Cartridge.rux` から移す。「ROM のサイズが 0x150 未満ならエラー」「未対応の cartridge-type ならエラー」（条件型 `unsupported-cartridge` と `invalid-rom`）。ヘッダのチェックサムが不一致なら警告の条件を通知する
- [ ] T010 [P] ヘッダ解析の単体テストを `tests/unit/cartridge-test.lisp` に書く（合成した ROM バイト列で、各 cartridge-type、サイズ不足、未対応の種別、チェックサム不一致をテストする）
- [ ] T011 テスト ROM の判定ヘルパーを `tests/suites/harness.lisp` に書く。`(run-rom path &key max-frames until)` でヘッドレスのマシンを動かす。`blargg-serial-result`（シリアルログに `Passed` / `Failed` が出るまで動かす）、`blargg-memory-result`（`$A000` 方式。`dmg_sound` 用）、`mooneye-result`（`LD B,B` に達したらレジスタがフィボナッチ数列 B=3,C=5,D=8,E=13,H=21,L=34 か判定する）、`framebuffer-fnv1a64`（ARGB を u32 のリトルエンディアンでハッシュする）、`dump-framebuffer-ppm (machine path)`（調査用の P6 形式の画像書き出し。依存なしで書ける）を用意する。**T008 で export した公開 API だけを使い、Bus や CPU の構造体には直接触れない**。US1 のコアが実装されるまでは、これを使うテストは「未実装」エラーで失敗するのが正しい

**Checkpoint**: `sh scripts/test.sh` が動き、カートリッジのテストが合格する

---

## Phase 3: User Story 1 - ROM を起動してゲームをプレイする (Priority: P1) 🎯 MVP

**Goal**: `lispgb game.gbc` でウィンドウが開き、画面、音、キー入力が正しく動く

**Independent Test**: テスト ROM（Blargg、Mooneye、acid2）がすべて合格する（RuxBoy の既知の不合格3件を除く）。cgb-acid2 をウィンドウで表示し、Esc で終了できる

### 3-A. メモリバスと CPU

- [ ] T012 [US1] Bus の構造体とメモリマップを `src/core/bus.lisp` に書く。data-model.md の Bus（WRAM 32KiB と SVBK、VRAM 16KiB と VBK、OAM、HRAM、IO 128B、IE / IF）を持つ。`bus-read` と `bus-write` で 0x0000〜0xFFFF をカートリッジ、VRAM、外部 RAM、WRAM、エコー領域、OAM、使用不可領域、IO、HRAM、IE に振り分ける。IO の書き込みは Timer、PPU、APU、Joypad の関数に振り分ける（この時点では空の関数でよい）。シリアル（SB / SC）は、SC に 0x81 が書かれたら SB を `serial-log` に追加する（FR-008）
- [ ] T013 [P] [US1] Bus の単体テストを `tests/unit/bus-test.lisp` に書く（エコー領域、WRAM / VRAM のバンク切り替え、使用不可領域の読み出し値、シリアルログ）
- [ ] T014 [P] [US1] CPU の単体テストを `tests/unit/cpu-test.lisp` に書く（主要命令のフラグ計算: ADD / ADC / SUB / SBC / DAA / INC / DEC / ADD HL / ADD SP,e8 / ローテート / CB 命令。PUSH / POP AF で F の下位4bit が 0 になること。条件分岐の T サイクル数）
- [ ] T015 [US1] CPU の状態と実行の枠組みを `src/core/cpu.lisp` に書く。data-model.md の Cpu（a〜l、sp、pc、ime、ime-pending、halted、halt-bug、stopped、cycles）。BIOS なしで起動した直後のレジスタ値（CGB モードと DMG モードの両方）は `~/Develop/ruxboy/Packages/Core/Src/Cpu.rux` から移す。`cpu-step` は割り込みを処理し（優先順は VBlank > STAT > Timer > Serial > Joypad、20 T サイクル）、HALT と HALT バグを扱い、関数ベクタで命令を実行する。メモリアクセスごとに4 T サイクル進める `tick` フックで、Timer / PPU / APU / DMA を進める（Mooneye の timing テストに必要）
- [ ] T016 [US1] 命令をマクロで生成し、256 + 256（CB）要素の関数ベクタを `src/core/opcodes.lisp` に作る。全命令の動作とサイクル数は `~/Develop/ruxboy/Packages/Core/Src/Cpu.rux` から移す。不正なオペコード（0xD3 など）を実行したら CPU を停止させる。`LD B,B`（0x40）で `debug-ld-b-b-hit` を立てる
- [ ] T017 [US1] T008 で作った `src/core/machine.lisp` の空の関数に中身を実装する。`make-machine (rom-bytes)`、`run-frame (machine)`（70224 ドット分実行する）、`machine-framebuffer`、`machine-serial-log`、`machine-cpu-registers`、`machine-ld-b-b-hit-p`、`machine-read-byte`（`set-buttons` は T037、`drain-audio` は T031 で実装する）
- [ ] T018 [US1] Blargg の CPU テストを `tests/suites/blargg.lisp` に書く（`cpu_instrs` の11個と統合版、`instr_timing`）。T011 のヘルパーを使う
- [ ] T019 [US1] `scripts/bench.sh` を作り、`cpu_instrs.gb` をヘッドレスで 3000 フレーム実行して fps を表示する。結果を `docs/dev/performance.md` に記録する。この時点では PPU と APU のコストが入っていないので、目安は **400fps 以上**とする（最終判定の 180fps は T071 で行う）。400fps 未満なら、`sb-sprof` でプロファイルし、原因と対策を同じファイルに書いてから先に進む（憲法 III）

### 3-B. 割り込みとタイマー

- [ ] T020 [P] [US1] Timer の単体テストを `tests/unit/timer-test.lisp` に書く（DIV のリセット、TAC のビット選択、TIMA のオーバーフローと遅延再ロード、DIV への書き込みでの立ち下がり検出）
- [ ] T021 [US1] Timer を `src/core/timer.lisp` に書く。data-model.md の Timer（div-counter u16、tima、tma、tac、overflow-delay）。`~/Develop/ruxboy/Packages/Core/Src/Bus.rux` の該当部分（Timer）から移す
- [ ] T022 [US1] Mooneye の timer / interrupts テストを `tests/suites/mooneye.lisp` に書く。`tests/roms/mooneye/acceptance/` 以下の ROM をすべて列挙して実行する。`rapid_toggle`、`reti_timing`、`stat_lyc_onoff` は、RuxBoy でも不合格の既知の失敗として `register-known-failure` する

### 3-C. PPU（DMG）

- [ ] T023 [P] [US1] PPU の単体テストを `tests/unit/ppu-test.lisp` に書く（モード遷移のタイミング: OAM 80 ドット → 描画 → HBlank、ライン 144 で VBlank、LY=LYC での STAT 割り込み、LCD を off にしたときの LY=0、タイルの 2bpp デコード）
- [ ] T024 [US1] PPU（DMG 部分）を `src/core/ppu.lisp` に書く。data-model.md の Ppu。スキャンライン単位で BG、ウィンドウ（内部ラインカウンタを使う）、スプライト（1ライン10個まで、X 座標による優先順位）を描く。STAT 割り込みの立ち上がりを `stat-line` で判定する。framebuffer は ARGB8888 で、DMG の色の値は `~/Develop/ruxboy/Packages/Core/Src/Ppu.rux` と**同じ値**にする（acid2 のハッシュを流用するため。research R8）
- [ ] T025 [US1] OAM DMA を `src/core/bus.lisp` に追加する（FF46。160 バイトを 640 T サイクルかけて転送し、転送中は OAM の読み出しが 0xFF になる）
- [ ] T026 [US1] dmg-acid2 のテストを `tests/suites/acid2.lisp` に書く。期待ハッシュとフレーム数は `~/Develop/ruxboy/Tests/Packages/Core/Acid2/Src/Main.rux` からそのまま移す。ハッシュが一致しない場合は、`dump-framebuffer-ppm` で画像を書き出し、参照画像（mattcurrie/dmg-acid2 リポジトリの `img/reference-dmg.png`）と目視で比べる。色の計算式の違いだけが原因なら、RuxBoy に合わせて直す。Mooneye の ppu テストも T022 のファイルに追加する

### 3-D. カートリッジと MBC

- [ ] T027 [P] [US1] MBC の単体テストを `tests/unit/mbc-test.lisp` に書く（MBC1 のバンク 0 → 1 補正と上位ビットのモード、MBC2 の 4bit RAM とアドレスビット 8 による切り替え、MBC3 のバンク切り替えと RTC のラッチ、MBC5 の 9bit ROM バンク、RAM 無効時の読み出しが 0xFF）
- [ ] T028 [US1] MBC を `src/core/mbc.lisp` に書く。data-model.md の Cartridge と Mbc（フラットな1つの構造体）。`~/Develop/ruxboy/Packages/Core/Src/Mbc.rux` から移す。外部 RAM に書き込んだら `ram-dirty` を立てる。MBC3 の RTC は `mbc-sync-wall-clock (cart unix-seconds)` で前回からの経過秒だけ進める（コアは時計を直接読まない。憲法 IV）
- [ ] T029 [US1] Mooneye の emulator-only/mbc1、mbc2、mbc5 のテストを `tests/suites/mooneye.lisp` に追加する

### 3-E. APU

- [ ] T030 [P] [US1] APU の単体テストを `tests/unit/apu-test.lisp` に書く（NR52 を off にするとレジスタがクリアされること、長さカウンタ、エンベロープ、スイープのオーバーフローでチャンネルが無効になること、波形 RAM の読み書き、出力が 48kHz でサンプル数が期待どおりになること）
- [ ] T031 [US1] APU を `src/core/apu.lisp` に書く。data-model.md の Apu（ch1〜ch4、フレームシーケンサー、NR50 / NR51、ステレオのリングバッファ）。`~/Develop/ruxboy/Packages/Core/Src/Apu.rux` から移すが、出力のサンプルレートは **48,000Hz**（RuxBoy は 22,050Hz）。`drain-audio (machine dst)` を `machine.lisp` から export する
- [ ] T032 [US1] Blargg `dmg_sound` のテスト（`$A000` 方式）を `tests/suites/blargg.lisp` に追加する

### 3-F. CGB の機能

- [ ] T033 [P] [US1] CGB の単体テストを `tests/unit/cgb-test.lisp` に書く（KEY1 と STOP による倍速の切り替え、BCPS / OCPS の自動インクリメント、VRAM バンク 1 の BG 属性、GDMA の転送量、HBlank ごとの HDMA、DMG 専用 ROM で DMG 互換モードになること）
- [ ] T034 [US1] CGB の機能を追加する。PPU（`src/core/ppu.lisp`）には、カラーパレット RAM、BG 属性（バンク、パレット、反転、優先度）、BG とスプライトの優先順位、RGB555 → ARGB8888 の色変換（`~/Develop/ruxboy/Packages/Core/Src/Ppu.rux` と**同じ式**）を追加する。Bus（`src/core/bus.lisp`）には、倍速、HDMA / GDMA、SVBK / VBK、OPRI を追加する。CPU（`src/core/cpu.lisp`）には、STOP での倍速切り替えを追加する
- [ ] T035 [US1] cgb-acid2 のテストを `tests/suites/acid2.lisp` に追加する（期待ハッシュは RuxBoy の Acid2 テストから）。ハッシュが一致しない場合は、T026 と同じ手順で、mattcurrie/cgb-acid2 リポジトリの `img/reference.png` と目視で比べる

### 3-G. ジョイパッド

- [ ] T036 [P] [US1] ジョイパッドの単体テストを `tests/unit/joypad-test.lisp` に書く（P14 / P15 の選択による読み出し、押下の瞬間だけ IF の bit4 が立つこと）
- [ ] T037 [US1] ジョイパッドを `src/core/joypad.lisp` に書き、FF00 を Bus に配線する。`set-buttons (machine button-set)` を `machine.lisp` から export する。ボタンはキーワードのリスト（`:right :left :up :down :a :b :select :start`）

### 3-H. フロントエンド（最小限のプレイ）

- [ ] T038 [US1] アプリのパッケージを `src/app/package.lisp` に書く（`lispgb`。`main` を export する）
- [ ] T039 [US1] SDL2 の最小限の宣言を `src/app/sdl2.lisp` に `sb-alien` で書く。宣言する関数: `SDL_Init`、`SDL_Quit`、`SDL_GetError`、`SDL_CreateWindow`、`SDL_DestroyWindow`、`SDL_SetWindowFullscreen`、`SDL_CreateRenderer`、`SDL_DestroyRenderer`、`SDL_RenderSetLogicalSize`、`SDL_SetHint`、`SDL_CreateTexture`、`SDL_UpdateTexture`、`SDL_RenderClear`、`SDL_RenderCopy`、`SDL_RenderPresent`、`SDL_PollEvent`、`SDL_OpenAudioDevice`、`SDL_PauseAudioDevice`、`SDL_QueueAudio`、`SDL_GetQueuedAudioSize`、`SDL_ClearQueuedAudio`、`SDL_CloseAudioDevice`、`SDL_GetPerformanceCounter`、`SDL_GetPerformanceFrequency`、`SDL_Delay`。署名は **`/usr/include/SDL2/*.h` を grep して確認する**。`SDL_Event` は 56 バイトのバッファとして持ち、type、keysym.sym、repeat を固定のオフセットで読む（オフセットはヘッダから確認する）。`load-sdl2` は `(load-shared-object "libSDL2-2.0.so.0" :dont-save t)` を呼び、失敗したら contracts/cli.md の日本語メッセージを出して終了コード 1 で終わる
- [ ] T040 [US1] 映像を `src/app/video.lisp` に書く。ウィンドウ（160×scale、144×scale）、レンダラ、ストリーミングテクスチャ（ARGB8888）を作り、フレームバッファを毎フレーム転送して表示する
- [ ] T041 [US1] 音声を `src/app/audio.lisp` に書く（research R7）。48kHz、ステレオ、S16 のキューイング方式。キューの量が「4フレーム分」を超えている間は `SDL_Delay(1)` で待つ（音声駆動のペース配分）。デバイスを開けなかったら、警告を出して `SDL_GetPerformanceCounter` による 59.7fps のペースに切り替え、無音で続ける
- [ ] T042 [US1] 入力を `src/app/input.lisp` に書く。固定のキー割り当て（矢印 = 十字キー、Z = B、X = A、Enter = Start、右Shift = Select）でボタン集合を更新する。F1 / F3 / Esc はイベントとして返す（F1 / F3 の処理は US2 で実装する）
- [ ] T043 [US1] エントリポイントとメインループを `src/app/main.lisp` に書く。手順: 引数から ROM のパスを受け取る（この段階では位置引数1つだけ。オプションは US3 で追加する）→ ROM を読む → `make-machine` → SDL2 を読み込む → イベント処理 → `set-buttons` → `mbc-sync-wall-clock`（毎フレーム）→ `run-frame` → 描画 → 音声 → ペース配分。Esc とウィンドウの close で終わる。エラーは日本語で標準エラー出力に出し、contracts/cli.md の終了コード（実行時エラーは 1、使い方の誤りは 2）で終わる（FR-020）
- [ ] T044 [US1] `scripts/build.sh` を作る。SBCL で `lispgb` をロードし、`save-lisp-and-die "build/lispgb" :executable t :toplevel #'lispgb:main` で実行ファイルを作る。`:sb-core-compression` が `*features*` にあるときだけ `:compression t` を付ける（research R4）。fasl の置き場所は `build/fasl/` とし、テスト用の `build/fasl-safe/`（T007）と混ぜない
- [ ] T045 [US1] 動作を確認する。`sh scripts/test.sh` で US1 のテストが全部合格すること（既知の3件を除く）。`build/lispgb tests/roms/acid2/cgb-acid2.gbc` でウィンドウに表示され、Esc で終了すること。`scripts/bench.sh` の結果を `docs/dev/performance.md` に追記する

**Checkpoint**: US1 が単独で動く（MVP）

---

## Phase 4: User Story 2 - ゲームの進行を保存・再開する (Priority: P2)

**Goal**: `.sav` で電池付きのセーブを永続化し、F1 / F3 でセーブステートを保存・復元する

**Independent Test**: 電池付きの ROM で `.sav` が作られ、再起動しても引き継がれる。F1 → F3 で状態が戻る。別の ROM の `.state` は拒否される

- [ ] T046 [P] [US2] セーブステートの単体テストを `tests/unit/savestate-test.lisp` に書く。(1) 保存してから数フレーム進め、復元すると、フレームバッファと全レジスタが保存時と一致する（SC-006: 100回繰り返す）。(2) マジック、バージョン、チェックサムが違うもの、長さが足りないものは拒否され、マシンが**一切変わらない**（スナップショットを取って比較する）。(3) リングバッファにゴミ値を入れてから復元すると、0 クリアされている（FR-013）。(4) `savestate-size` と実際に書いたバイト数が一致する
- [ ] T047 [US2] セーブステートを `src/core/savestate.lisp` に書く。形式は contracts/savestate-format.md のとおり（マジック `LGBS`、バージョン u32 = 1、グローバルチェックサム、data-model.md で SS が ○ の要素を記載の順に、リトルエンディアンで）。`save-state (machine) → octets`、`load-state (machine octets)`。検証はマジック → バージョン → チェックサム → サイズの順に行い、全部通過してから書き込む。失敗したら条件 `savestate-error`（理由のキーワード付き）を通知する
- [ ] T048 [P] [US2] アトミックな書き込みを `src/app/fileio.lisp` に書く。`write-file-atomically (path octets)` は `<path>.tmp` に書いてから `rename` する。`read-file-octets (path)` も用意する
- [ ] T049 [P] [US2] パスの計算を `src/app/paths.lisp` に書く。ROM のパスから `.sav` と `.state` のパスを作る（拡張子を置き換える）
- [ ] T050 [US2] セーブ RAM の永続化を `src/app/main.lisp` に組み込む。起動時に `.sav` を読み込む（サイズが RAM のサイズと一致しなければ読み込まず、警告を出し、既存のファイルを `<名前>.sav.bak` に退避する）。毎フレーム `ram-dirty` を確認し、最後の書き込みから 60 フレーム何も起きなければ保存する。終了時は必ず保存する（FR-010）。電池なしのカートリッジでは何もしない
- [ ] T051 [US2] F1 / F3 を `src/app/main.lisp` に組み込む。F1 で `save-state` を `.state` にアトミックに書く。F3 で読み込んで `load-state` し、成功したら音声のキューをクリアする（`SDL_ClearQueuedAudio`）。失敗したら日本語で理由を標準エラー出力に出し、実行を続ける
- [ ] T052 [US2] quickstart.md の手順5で確認する（`ram_64kb.gb` のコピーで `.sav` が 8192 バイトで作られること。F1 / F3 の動作）

**Checkpoint**: US1 と US2 がどちらも動く

---

## Phase 5: User Story 4 - 正確性を自動で検証する (Priority: P2)

**Goal**: `--headless --frames N --screenshot PATH` と、一括テストで正確性を確かめられる

**Independent Test**: `sh scripts/test.sh` が合否一覧を出して終了コード 0 で終わる。ヘッドレスで出した BMP が acid2 の参照画像と一致する

- [ ] T053 [P] [US4] BMP 書き出しの単体テストを `tests/unit/bmp-test.lisp` に書く（2×2 の画像で、ヘッダの各フィールド、行のパディング、下から上への行順、BGR の順を確認する）
- [ ] T054 [P] [US4] 24bit 非圧縮 BMP の書き出しを `src/app/bmp.lisp` に書く（`write-bmp (path argb-pixels width height)`）
- [ ] T055 [US4] ヘッドレスモードを `src/app/main.lisp` に追加する。`--headless --frames N [--screenshot PATH]` のときは SDL2 を**読み込まずに** N フレーム実行し、スクリーンショットを保存して終了コード 0 で終わる。`--frames` がないとエラーにする（contracts/cli.md）。オプションの解析は、US3 の T058 で作る `src/app/cli.lisp` に移すので、ここでは最小限でよい
- [ ] T056 [US4] テスト一覧の出力を整え、`tests/suites/` の各テストがスイート名ごとにまとまって表示されるようにし、最後に「合格 / 不合格 / 既知の不合格」の件数を出す（`tests/framework.lisp`）。既知の不合格の一覧と理由を `docs/dev/known-failures.md` に書く（憲法 I）
- [ ] T057 [US4] quickstart.md の手順1と3で確認する

**Checkpoint**: US1、US2、US4 が動く

---

## Phase 6: User Story 3 - 表示と起動の挙動をカスタマイズする (Priority: P3)

**Goal**: CLI オプション、設定ファイル、最近使った ROM の一覧

**Independent Test**: `--scale`、`--fullscreen`、`--shader`、`--recent`、`--help`、`--version` が contracts/cli.md どおりに動く。設定ファイルが自動で作られ、既定値として使われる

- [ ] T058 [P] [US3] CLI の解析の単体テストを `tests/unit/cli-test.lisp` に書く（全オプション、`--scale 9` → 8、`--scale 0` / `abc` → 使い方の誤り、値がない、未知のオプション、ROM の指定がない、`--recent` では ROM が不要、`--headless` で `--frames` がない）
- [ ] T059 [P] [US3] 設定ファイルと一覧の単体テストを `tests/unit/config-test.lisp` に書く（既定値での生成、コメントと空白の扱い、未知の key と不正な値の無視、`XDG_CONFIG_HOME` が空のときの `~/.config`、一覧の先頭への移動・重複の除去・10件での切り詰め）
- [ ] T060 [US3] CLI の解析を `src/app/cli.lisp` に書く。`parse-args (list) → cli-options` は、contracts/cli.md のオプション表のとおり。使い方の誤りは条件 `usage-error` にする。`--help` の文言は日本語で、RuxBoy の README の「使い方」と同じ構成にする。T055 の仮の解析をこれに置き換える
- [ ] T061 [US3] 設定ファイルを `src/app/config.lisp` に書く。contracts/config-format.md のとおり（置き場所は `$XDG_CONFIG_HOME/LispGB/config.txt`、未設定または空なら `~/.config/LispGB/config.txt`。key は scale、fullscreen、shader、volume。ファイルがなければ既定値で生成し、ディレクトリを作れなければ警告を出して既定値で続ける）。優先順位は CLI > 設定ファイル > 既定値
- [ ] T062 [US3] 最近使った ROM の一覧を `src/app/recent.lisp` に書く（`recent.txt`、絶対パス、新しい順、重複なし、最大10件、アトミックな書き込み）。`--recent` で表示して終了し、ROM を起動するたびに更新する
- [ ] T063 [US3] 表示の設定を `src/app/video.lisp` に反映する。`--scale`（ウィンドウのサイズ）、`--fullscreen`（`SDL_WINDOW_FULLSCREEN_DESKTOP` と論理サイズ 160×144）、`--shader`（`SDL_HINT_RENDER_SCALE_QUALITY` を `"0"` / `"1"` にしてからテクスチャを作る）。`volume` は `src/app/audio.lisp` でサンプルに掛ける
- [ ] T064 [US3] `--version`（`LispGB <version>`。バージョンは `lispgb.asd` から取得し、ビルド時に埋め込む）と `--help` を `src/app/main.lisp` に組み込む
- [ ] T065 [US3] quickstart.md の手順6で確認する

**Checkpoint**: すべてのユーザーストーリーが動く

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: 配布、CI / CD、ドキュメント、最終確認

- [ ] T066 [P] `scripts/package_zip.sh` を作る。`build/lispgb`、`README.md`、`README.ja.md`、`LICENSE` を `dist/LispGB-<version>-linux-arm64.zip` にまとめる（FR-024）
- [ ] T067 [P] CI を `.github/workflows/ci.yml` に書く。`ubuntu-24.04-arm` で `apt install sbcl libsdl2-dev` → `scripts/fetch_test_roms.sh` → `scripts/test.sh` → `scripts/build.sh` を、ローカルと同じスクリプトで実行する（FR-023）。ビルド後に、CI 上（Ubuntu 24.04）で `./build/lispgb --version` と `./build/lispgb --headless --frames 120 --screenshot out.bmp tests/roms/acid2/cgb-acid2.gbc` を実行し、実行ファイル自体が 24.04 の glibc と SBCL 2.3 系で動くことを確かめる。**プッシュはしない**（コミットはする）
- [ ] T068 [P] リリースを `.github/workflows/release.yml` に書く。`v*` タグで CI と同じ手順を実行し、`scripts/package_zip.sh` で作った zip を GitHub Releases に上げる
- [ ] T069 [P] 利用者向けの README を `README.md`（英語）と `README.ja.md`（日本語）に書く。構成は RuxBoy の README に合わせる（概要、現状、対応プラットフォーム、インストール（`sudo apt install libsdl2-2.0-0`）、ビルド、使い方、キー操作、ライセンス）。**開発向けの内容は書かない**
- [ ] T070 [P] 開発文書を `docs/dev/` に書く（`architecture.md`: コアとフロントエンドの分離と主な設計判断。`performance.md` と `known-failures.md` を最新にする）
- [ ] T071 性能を最終確認する。`scripts/bench.sh` でヘッドレス 180fps 以上（SC-004）。ウィンドウでの実行で音切れがないことと、起動から表示まで2秒以内（SC-005）であることを確かめる。結果を `docs/dev/performance.md` に記録する
- [ ] T072 SBCL がない環境で実行ファイルが動くことを確かめる（`env -i PATH=/usr/bin:/bin ./build/lispgb --version`。`SBCL_HOME` などに依存していないこと）。さらに、Docker / Podman が使える場合は、`ubuntu:24.04`（arm64）のコンテナに `sbcl` と `libsdl2-2.0-0` を入れ、(1) ソースから `scripts/test.sh` が通ること（SBCL 2.3 系との互換性）、(2) 26.04 でビルドした `build/lispgb --version` が動くこと、の2点を確かめる。結果は `docs/dev/platforms.md` に記録する（どちらもできない場合は「未検証」と書く）
- [ ] T073 quickstart.md の手順1〜8をすべて通して実行し、結果を報告する

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存なし
- **Foundational (Phase 2)**: Setup の後。全ストーリーをブロックする
- **US1 (Phase 3)**: Foundational の後。3-A → 3-B → 3-C → 3-D → 3-E → 3-F の順（どれも CPU とバスに依存し、テスト ROM の多くは複数の部品を必要とする）。3-G は 3-A の後ならいつでもよい。3-H は 3-A〜3-G の後
- **US2 (Phase 4)**: コアの全部品（3-A〜3-G）に依存する。T050 と T051 は 3-H にも依存する
- **US4 (Phase 5)**: T055 は 3-A〜3-G に依存する。US2 とは独立している
- **US3 (Phase 6)**: 3-H に依存する。T060 は T055 の仮の解析を置き換える
- **Polish (Phase 7)**: 全ストーリーの後

### Within Each User Story

- テストを先に書き、失敗することを確かめてから実装する（憲法 II）。失敗するテストは `register-pending` で登録し、どのコミットの時点でも `scripts/test.sh` が合格する状態を保つ（「全タスク共通の約束」の対応表を参照）
- 一度合格したテストが落ちる変更は、完了扱いにしない

### Parallel Opportunities

- Phase 1: T003、T004、T005
- Phase 2: T010（T009 と並行して書ける）
- US1: 各部品の単体テスト（T013、T014、T020、T023、T027、T030、T033、T036）は、それぞれ別のファイルなので並行して書ける
- US2: T046、T048、T049
- US4: T053、T054
- US3: T058、T059
- Polish: T066〜T070

---

## Parallel Example: User Story 1

```bash
# 各部品の単体テストを並行して書く:
Task: "Timer の単体テストを tests/unit/timer-test.lisp に書く"
Task: "PPU の単体テストを tests/unit/ppu-test.lisp に書く"
Task: "MBC の単体テストを tests/unit/mbc-test.lisp に書く"
Task: "APU の単体テストを tests/unit/apu-test.lisp に書く"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1（Setup）と Phase 2（Foundational）を終える
2. Phase 3（US1）を部品ごとに進め、各部品のテスト ROM が合格したら次へ進む
3. **止まって確認する**: テストが全部合格し、ウィンドウでプレイできることを確かめる
4. 3-A の直後に速度を計測し、180fps に届かない場合は、設計の問題として早めに直す

### Incremental Delivery

1. Setup + Foundational → 基盤ができる
2. US1 → プレイできる（MVP）
3. US2 → セーブできる
4. US4 → ヘッドレスと一括テストで検証できる
5. US3 → 細かい設定ができる
6. Polish → 配布物と CI

---

## Notes

- [P] = 別ファイルで、未完了のタスクに依存しない
- 各チェックポイントで、そのストーリーを単独で確かめる
- タスクが1つ完了するごとにコミットする。プッシュは指示があるまでしない（憲法 v1.1.0）
- 市販のゲーム ROM での確認が必要になったら、実行前にユーザーに相談する
