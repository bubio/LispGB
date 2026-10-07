# Phase 1 データモデル: Game Boy Color エミュレーター（LispGB）

**作成日**: 2026-10-07
**対象仕様**: [spec.md](./spec.md)

コアの状態はすべて、型付きスロットの構造体（`defstruct`）で持つ（[research.md](./research.md) R6）。
以下は「何を持つか」の定義です。スロット名は実装時に調整してよいですが、
**セーブステートに入れるかどうかの区別**は守ってください。

凡例: `u8` = `(unsigned-byte 8)`、`u16` = `(unsigned-byte 16)`、`u32` = `(unsigned-byte 32)`、
`bytes` = `(simple-array (unsigned-byte 8) (*))`。
SS 列: ○ = セーブステートに含める、× = 含めない。

---

## Machine（マシン全体）

コアの最上位の状態。フロントエンドとテストは、これだけを扱う。

| 要素 | 型 | SS | 説明 |
|---|---|---|---|
| cpu | Cpu | ○ | |
| bus | Bus | ○ | メモリマップと周辺機器をまとめたもの |
| cgb-mode | boolean | ○ | ROM ヘッダから決まる。DMG 専用 ROM なら偽 |

**操作**:
- `make-machine (rom-bytes)` → Machine。カートリッジを解析し、BIOS なしの起動直後の状態に
  する（FR-005、FR-006）。未対応のカートリッジ種別ならエラー条件を通知する。
- `run-frame (machine)` → 1フレーム（70224 ドットクロック。倍速モードでも映像は同じ）を
  実行する。
- `set-buttons (machine, button-set)` → 押下状態を更新する。押された瞬間にジョイパッド
  割り込みを要求する。
- `framebuffer (machine)` → `(simple-array u32 (23040))` を返す（ARGB8888、160×144）。
- `drain-audio (machine, dst)` → 溜まった音声サンプルを取り出す。
- `machine-serial-log (machine)` → シリアル出力の記録（Blargg の判定用）。
- `machine-cpu-registers (machine)` → a〜l、sp、pc を plist で返す（Mooneye の判定用）。
- `machine-ld-b-b-hit-p (machine)` → `LD B,B` を実行したかどうか（Mooneye の判定用）。
- `machine-read-byte (machine, address)` → バスから1バイト読む（Blargg `dmg_sound` の `$A000` 判定用）。

## Cpu

| 要素 | 型 | SS | 説明 |
|---|---|---|---|
| a, f, b, c, d, e, h, l | u8 | ○ | f の下位4bit は常に 0 |
| sp, pc | u16 | ○ | |
| ime | boolean | ○ | |
| ime-pending | boolean | ○ | EI の1命令遅延 |
| halted | boolean | ○ | |
| halt-bug | boolean | ○ | |
| stopped | boolean | ○ | |
| cycles | fixnum | ○ | フレーム内で経過した T サイクル数 |
| debug-ld-b-b-hit | boolean | × | Mooneye の判定用 |

**状態遷移**: 実行中 →（HALT）→ 停止中 →（IE と IF の論理積が 0 でなくなる）→ 実行中。
STOP（CGB で KEY1 の準備ビットが立っている場合）では倍速を切り替える。

## Bus（メモリマップと周辺機器）

| 要素 | 型 | SS | 説明 |
|---|---|---|---|
| wram | bytes (32KiB) | ○ | CGB は 8 バンク |
| wram-bank | u8 | ○ | SVBK |
| vram | bytes (16KiB) | ○ | CGB は 2 バンク |
| vram-bank | u8 | ○ | VBK |
| oam | bytes (160) | ○ | |
| hram | bytes (127) | ○ | |
| io | bytes (128) | ○ | 生値のレジスタ。**専用の項目を持つレジスタ（Timer、Ppu、Apu、Joypad、IE / IF、バンク、DMA）は IO 配列を使わず、専用の項目だけが正とする**（二重保存と食い違いを防ぐため） |
| ie, if | u8 | ○ | |
| key1-armed, double-speed | boolean | ○ | |
| hdma (src, dst, length, active, hblank-mode) | u16 / u8 / boolean | ○ | |
| oam-dma (active, source, index, delay) | | ○ | |
| timer | Timer | ○ | |
| ppu | Ppu | ○ | |
| apu | Apu | ○ | |
| cart | Cartridge | ○（一部） | |
| joypad | Joypad | ○ | |
| serial-log | 可変長のバイト列 | × | テストの判定用 |

## Timer

| 要素 | 型 | SS | 説明 |
|---|---|---|---|
| div-counter | u16 | ○ | 内部の16bit カウンタ。DIV はその上位8bit |
| tima, tma, tac | u8 | ○ | |
| overflow-delay | fixnum | ○ | TIMA のオーバーフローから再ロードまでの遅延 |

## Ppu

| 要素 | 型 | SS | 説明 |
|---|---|---|---|
| mode | 0..3 | ○ | HBlank / VBlank / OAM / 描画 |
| dot | fixnum | ○ | ライン内の位置 |
| ly, lyc, lcdc, stat, scy, scx, wy, wx, bgp, obp0, obp1 | u8 | ○ | |
| window-line | u8 | ○ | ウィンドウの内部ラインカウンタ |
| stat-line | boolean | ○ | STAT 割り込みの立ち上がりを判定する |
| bg-palette-ram, obj-palette-ram | bytes (64) | ○ | CGB の BCPS / OCPS とデータ |
| bcps, ocps | u8 | ○ | |
| opri | u8 | ○ | |
| framebuffer | `(simple-array u32 (23040))` | ○ | |
| frame-ready | boolean | × | 1フレームの完成を知らせるフラグ |
| line-scratch（BG の色番号、優先度） | 160要素の配列 | × | 1ライン内で完結する作業領域 |

**色変換**: CGB の RGB555 → ARGB8888 の変換式と、DMG のパレット色は RuxBoy / BubiBoy Lite と
同じにする（acid2 の期待ハッシュを流用するため。research.md R8）。

## Apu

| 要素 | 型 | SS | 説明 |
|---|---|---|---|
| enabled | boolean | ○ | NR52 |
| frame-sequencer-step | 0..7 | ○ | |
| ch1, ch2（矩形波: duty、長さ、エンベロープ、周波数、タイマー。ch1 はスイープも） | | ○ | |
| ch3（波形: wave-ram 16B、出力レベル、位置） | | ○ | |
| ch4（ノイズ: LFSR、分周、エンベロープ） | | ○ | |
| nr50, nr51 | u8 | ○ | |
| sample-accumulator | fixnum | ○ | 48kHz へ間引く際の端数 |
| ring（left / right / read / write / count） | | × | 出力バッファ。**復元時は 0 クリアする**（FR-013） |

## Cartridge と Mbc

| 要素 | 型 | SS | 説明 |
|---|---|---|---|
| rom | bytes | × | 呼び出し側が持つ ROM データ |
| header | CartridgeHeader | × | ROM から再計算できる |
| ram | bytes | ○ | 外部 RAM（MBC2 は内蔵の 512 要素、各4bit） |
| ram-dirty | boolean | × | `.sav` を保存する判定用 |
| mbc-kind | :rom-only / :mbc1 / :mbc2 / :mbc3 / :mbc5 | × | ヘッダから決まる |
| rom-bank, ram-bank, ram-enabled, banking-mode | | ○ | 種別ごとに使うスロットが異なるが、構造体は1つ（フラット）にする |
| rtc（s, m, h, dl, dh、ラッチ値、ラッチの状態、基準 UNIX 時刻） | | ○ | MBC3 のみ使う |

### CartridgeHeader

| 要素 | 説明 |
|---|---|
| title | 0x0134〜0x0143 |
| cgb-flag | 0x0143（0x80 = 両対応、0xC0 = CGB 専用） |
| cartridge-type | 0x0147。MBC の種別、RAM・バッテリー・RTC の有無に対応付ける |
| rom-size, ram-size | 0x0148、0x0149 |
| header-checksum | 0x014D（不一致なら警告だけ出す。エッジケース） |
| global-checksum | 0x014E〜0x014F（セーブステートの ROM 識別に使う） |

**検証**: ROM のサイズが 0x150 未満ならエラー。未対応の cartridge-type ならエラー。
`.sav` のサイズが RAM のサイズと一致しない場合は、読み込まない。

## Joypad

| 要素 | 型 | SS | 説明 |
|---|---|---|---|
| select-action, select-direction | boolean | ○ | P14 / P15 |
| pressed | u8（ビット集合） | ○ | 右 / 左 / 上 / 下 / A / B / Select / Start |

## SaveState（シリアライズしたもの）

形式は [contracts/savestate-format.md](./contracts/savestate-format.md)。上の表で SS が ○ の
要素をすべて固定の順序で書く。

**不変条件**: 読み込みでは、まず全体を検証（マジック → バージョン → ROM 識別 → サイズ）して
から書き込む。検証に失敗した場合、Machine は一切変更しない（FR-012）。

## フロントエンド側の実体

| 実体 | 内容 | 保存場所 |
|---|---|---|
| AppConfig | scale (1..8, 既定 4)、fullscreen (既定 false)、shader (:nearest / :smooth, 既定 :nearest)、volume (0..100, 既定 100) | `config.txt`（[contracts/config-format.md](./contracts/config-format.md)） |
| RecentList | ROM の絶対パス、最大10件、新しい順、重複なし | `recent.txt`（設定ディレクトリ） |
| CliOptions | [contracts/cli.md](./contracts/cli.md) のとおり | — |
| SaveRam | 外部 RAM の生バイト列 | `<ROMのパスから拡張子を除いたもの>.sav` |
| StateFile | SaveState のバイト列 | `<ROMのパスから拡張子を除いたもの>.state` |
