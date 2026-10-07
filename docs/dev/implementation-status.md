# 実装状況

## 2026-10-08: T032 完了

T001〜T032 を完了。CPU、Timer、MBC、DMG 描画、DMA、48kHz の4チャンネル音源を実装した。
`sh scripts/test.sh` は終了コード 0。Blargg CPU 13本、音源12本、dmg-acid2、
Mooneye の取得済み ROM が合格（既知のタイミング不合格3件を除く）。

音源は実 ROM に合わせ、波形 RAM の 2 T サイクルのアクセス窓、再トリガー時の破壊、
電源断時の長さカウンタ保持と制御リセット、周期0のスイープを検証した。
CGB、入力、SDL2 フロントエンド、保存機能、CLI は後続タスクで実装する。

ROM は Git 管理対象外。取得元と固定バージョンは `scripts/fetch_test_roms.sh` に記載。

## T034: CGB

倍速切り替え、RGB555 パレット、BG 属性、CGB のスプライト優先度、GDMA / HDMA を追加。
単体テストと既存全スイートが合格。DMA の転送時間は参照実装の 8 T から
32ドット（通常8 Mサイクル、倍速16 Mサイクル）へ修正した。
根拠: [Pan Docs の転送時間](https://gbdev.io/pandocs/CGB_Registers.html#transfer-timings)。
