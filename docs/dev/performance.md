# 性能測定

## T019: CPU・Timer・MBC（2026-10-07）

- コマンド: `sh scripts/bench.sh`
- ROM: `tests/roms/blargg/cpu_instrs/cpu_instrs.gb`
- 通常ビルド、3000 フレーム: **2.328 秒、1288.66 fps**。
- 目標 400fps を上回ったため、プロファイルによる最適化は行っていない。
- PPU と APU は未実装。完成時の速度保証ではなく、この段階の基準値。

## T045: MVP（2026-10-08）

CPU・Timer・MBC・PPU・APU を有効にして同じ3000フレームを測定。
3000 フレーム: 13.544 秒、221.50 fps

実ウィンドウ（640×576）で cgb-acid2 の表示と Esc 終了を確認。
