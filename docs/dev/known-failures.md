# 既知の不合格

参照実装 RuxBoy の仕様で除外が許可された Mooneye の3件のみを扱う。

| ROM | 理由 |
|---|---|
| rapid_toggle | TAC の急速切り替えに関する実機との差異。RuxBoy でも不合格 |
| reti_timing | RETI と割り込み受理のタイミング。RuxBoy でも不合格 |
| stat_lyc_onoff | LCD の on/off 時の LYC 比較タイミング。RuxBoy でも不合格 |

未実装の機能や、それ以外の回帰を既知失敗に追加して隠すことはしない。
