# Implementation Plan: Game Boy Color エミュレーター（LispGB）

**Branch**: `001-gbc-emulator` | **Date**: 2026-10-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-gbc-emulator/spec.md`

## Summary

コマンドラインから起動する Game Boy / Game Boy Color エミュレーターを、SBCL（Common Lisp）で
作る。機能とテストの合格水準は RuxBoy と同等にする。

- **コア**: 外部ライブラリに依存しない純粋な Lisp。型付きの構造体と単純配列で状態を持つ。
- **フロントエンド**: SBCL 組み込みの FFI（`sb-alien`）から SDL2 を直接呼ぶ。
- **依存**: 外部の Lisp ライブラリはゼロ。Quicklisp も使わない。
- **配布**: `save-lisp-and-die` で作った単体の実行ファイルを zip にする。
- **正確性**: RuxBoy と同じテスト ROM と同じ判定方法で確かめる。

## Technical Context

**Language/Version**: Common Lisp / SBCL。開発環境は 2.6.0。CI とリリースは Ubuntu 24.04 の
apt 版 SBCL（2.3 系）でビルドするので、2.3 系以降で動くように書く。

**Primary Dependencies**: SBCL に同梱のもの（ASDF、`sb-alien`、`sb-sprof`）。実行時に必要なのは
SDL2（`libSDL2-2.0.so.0`）だけで、起動時に動的に読み込む。外部の Lisp ライブラリはなし。

**Storage**: ファイルだけ。`config.txt`、`recent.txt`（XDG の設定ディレクトリ）、
`<ROM>.sav`、`<ROM>.state`（ROM と同じ場所）。

**Testing**: 自前の最小テストフレームワーク（`deftest` / `is`）で、単体テストとテスト ROM による
結合テスト（Blargg、Mooneye、acid2）を書く。`scripts/test.sh` で一括実行する。

**Target Platform**: Linux arm64（Ubuntu 24.04 以降）。開発環境は Ubuntu 26.04 / aarch64。
Linux amd64 はローカルと Ubuntu 24.04 CI で確認済み（2026-10-09）。
macOS は Apple Silicon のローカル環境に展開する。SDL2 は Homebrew の dylib または
Framework を遅延ロードし、設定は `~/Library/Application Support/LispGB/` に保存する。
macOS Intel と Windows は実動作未検証。

**Project Type**: デスクトップの CLI アプリケーション（エミュレーター）

**Performance Goals**: ウィンドウ表示・音声ありで 59.7fps を維持し、音切れしない。
ヘッドレスでは 180fps 以上（実機の3倍以上）。起動から画面表示まで2秒以内。

**Constraints**: 正確性を速度より優先する（憲法 I）。処理系がなくても動く単体の実行ファイルにする。
glibc 2.39（Ubuntu 24.04）で動くようにする。テスト ROM はリポジトリに入れない。

**Scale/Scope**: コアは約 6〜8 千行、フロントエンドは約 1.5 千行、テストは約 2 千行を見込む。
CPU 命令は 512 個（CB 接頭辞付きを含む）。対応する MBC は 5 種類。

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原則 | 判定 | 根拠 |
|---|---|---|
| I. 正確性第一 | ✅ | テスト ROM（Blargg、Mooneye、acid2）による判定を完成条件にした（research R8）。既知の不合格は一覧で管理する |
| II. テスト先行と回帰防止 | ✅ | コアの各部に単体テストを付け、`scripts/test.sh` で一括実行する。テスト ROM はコミット固定の取得元から取る |
| III. 実機速度でのリアルタイム動作 | ✅ | 音声駆動のペース配分（R7）。型宣言と関数ベクタで高速化する方針を立て（R6）、`sb-sprof` で計測して `scripts/bench.sh` で確認する |
| IV. コアとフロントエンドの分離 | ✅ | `lispgb/core` は SDL もファイル I/O も参照しない。`--headless` とテストは SDL2 を読み込まずに動く。セーブステートは検証してから書き込む |
| V. シンプルさと依存の最小化 | ✅ | 外部の Lisp ライブラリはゼロ。SDL2 だけは、マルチメディア層として自前で書く価値がないので使う（理由は R2、R3 に記録） |
| 技術制約 | ✅ | Linux 優先、XDG に従った置き場所、MIT ライセンス、セマンティックバージョニング、BIOS は使わない |
| 開発ワークフロー | ✅ | コメントとメッセージは日本語。CI のファイルは作るが、プッシュは指示があるまでしない。README は利用者向けの情報だけにする |

**Phase 1 の設計後に再確認**: 違反は見つからなかった。Complexity Tracking は空のまま。

## Project Structure

### Documentation (this feature)

```text
specs/001-gbc-emulator/
├── plan.md              # 本ファイル
├── research.md          # Phase 0（技術選定と実測結果）
├── data-model.md        # Phase 1（状態の定義とセーブステートに含めるもの）
├── quickstart.md        # Phase 1（エンドツーエンドの検証手順）
├── contracts/
│   ├── cli.md               # コマンドライン、キー操作、終了コード
│   ├── savestate-format.md  # .state の形式
│   └── config-format.md     # config.txt と recent.txt
└── tasks.md             # Phase 2（/speckit-tasks で作る）
```

### Source Code (repository root)

```text
lispgb.asd                 # ASDF の定義: lispgb/core, lispgb, lispgb/tests
src/
├── core/                  # エミュレーションコア（純粋な Lisp、I/O なし）
│   ├── package.lisp
│   ├── types.lisp         # 型の別名、最適化宣言、ビット操作のマクロ
│   ├── cartridge.lisp     # ヘッダの解析、種別の対応表
│   ├── mbc.lisp           # ROM のみ / MBC1 / MBC2 / MBC3（RTC 含む）/ MBC5
│   ├── timer.lisp
│   ├── joypad.lisp
│   ├── ppu.lisp           # DMG と CGB の描画、STAT、パレット
│   ├── apu.lisp           # 4 チャンネル、フレームシーケンサー、48kHz 出力
│   ├── bus.lisp           # メモリマップ、IO の振り分け、OAM DMA、HDMA、シリアル
│   ├── cpu.lisp           # レジスタ、割り込み、HALT / STOP、ステップ実行
│   ├── opcodes.lisp       # 命令を生成するマクロと 256×2 の関数ベクタ
│   ├── savestate.lisp
│   └── machine.lisp       # make-machine / run-frame / set-buttons など公開 API
└── app/                   # フロントエンド
    ├── package.lisp
    ├── sdl2.lisp          # sb-alien による SDL2 の最小限の宣言
    ├── paths.lisp         # XDG のディレクトリ、.sav / .state のパス
    ├── fileio.lisp        # 一時ファイルと rename によるアトミックな書き込み
    ├── cli.lisp
    ├── config.lisp
    ├── recent.lisp
    ├── bmp.lisp
    ├── video.lisp
    ├── audio.lisp         # キューイング方式と音声駆動のペース配分
    ├── input.lisp
    └── main.lisp          # エントリポイント lispgb:main とメインループ
tests/
├── framework.lisp         # deftest / is / 集計
├── unit/                  # cpu, timer, mbc, ppu, apu, bus, joypad, savestate, cli, config
├── suites/                # blargg.lisp, mooneye.lisp, acid2.lisp（ROM の結果を判定する）
└── roms/                  # テスト ROM の置き場所（.gitignore 対象。スクリプトで取得）
scripts/
├── fetch_test_roms.sh
├── test.sh
├── build.sh               # save-lisp-and-die → build/lispgb
├── bench.sh
├── get_version.sh
└── package_zip.sh
.github/workflows/
├── ci.yml                 # ubuntu-24.04-arm: テスト → ビルド
└── release.yml            # タグをプッシュしたら zip を Releases に上げる
docs/dev/                  # 開発文書（既知の不合格一覧、性能メモなど）
README.md / README.ja.md / LICENSE
```

**Structure Decision**: プロジェクトは1つで、ASDF のシステムを3つに分ける。コア
（`lispgb/core`）は I/O に依存しない（憲法 IV）。フロントエンド（`lispgb`）はコアに依存する。
テスト（`lispgb/tests`）はコアとフロントエンドの両方を検証する。

## 開発の順序（tasks で詳しく分解する）

RuxBoy のフェーズ構成に合わせ、各段階をテストで確かめてから次へ進む。

1. 骨組み: ASDF、テストフレームワーク、スクリプト、ROM の取得
2. CPU（Blargg `cpu_instrs`、`instr_timing`）→ 早い段階で速度を計測する
3. 割り込みとタイマー（Mooneye の timer / interrupts）
4. PPU（dmg-acid2、Mooneye の ppu）
5. カートリッジと MBC（Mooneye の emulator-only/mbc*）
6. APU（Blargg `dmg_sound`）
7. CGB の機能（cgb-acid2）
8. セーブステート
9. フロントエンド（SDL2、CLI、設定ファイル、.sav、ヘッドレスモード）
10. CI / CD と配布（zip、Releases）

## Complexity Tracking

憲法違反がないので、記入なし。
