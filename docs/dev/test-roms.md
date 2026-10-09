# テスト ROM の固定取得

## acid2（T085）

`sh scripts/fetch_test_roms.sh`（Windows では `scripts/fetch_test_roms.ps1`）は
SameBoy の検証用 ROM をコミット固定で取得し、SHA256 を照合する。
追加のアセンブラは不要。取得済みのファイルと `.gbc` 別名も毎回照合し、
不一致なら既存ファイルを残して非0で終了する。一時ファイルは照合後に移動する。

- 配布元: [SameBoy 固定コミット](https://github.com/LIJI32/SameBoy/tree/c458e7c5d2d350fb37a1931c40da9f758d28d240/.github/actions)
- コミット: `c458e7c5d2d350fb37a1931c40da9f758d28d240`
- dmg-acid2: `.github/actions/dmg-acid2.gb`、SHA256 `464e14b7d42e7feea0b7ede42be7071dc88913f75b9ffa444299424b63d1dff1`
- cgb-acid2: `.github/actions/cgb-acid2.gbc`、SHA256 `197fb0bcec544f0400527fc707e0a94f55435974986e6986b424ace5de81720e`

2026-10-09 に既存の公式 dmg-acid2 v1.0 / cgb-acid2 v1.1 の ROM とバイト一致を確認した。
公式ソースの該当コミットはそれぞれ `dc2295408f881637ff69f784d8d93f3d2db30181`、
`fa5b7f86d6fb599f79e55169494d981a7af75a31`。両 ROM のライセンスは MIT。
RuxBoy のリリース URL の取得を変えた理由は、憲法 II のコミット固定取得に従うため。
Blargg / Mooneye の取得元・固定コミット・対象 ROM と、acid2 の期待フレームハッシュは維持する。

`sh tests/scripts/fetch-test.sh` は通信を置き換え、新規取得、再取得の省略、
改変キャッシュの拒否を検証する。ローカルで両 acid2 の取得が済んだ状態で実行する。

T085 の確認: 修正前に固定 URL の検査が失敗し、修正後に取得検証が成功。
固定コミットから実際に取得したバイナリも既存 ROM と一致した。

## 必須集合と一括検証（T086）

`tests/rom-manifest.txt` は Blargg、Mooneye、両 acid2 と cgb の別名を含む81ファイルの
共通一覧。取得スクリプトは一覧の欠落・空ファイルを失敗とする。
テストの共通 Lisp 検査はヘッダの最小長336バイトも検査する。

- `LISPGB_REQUIRE_TEST_ROMS=1 sh scripts/test.sh` で必須モードを実行する。
- Windows の `scripts/test.ps1` / `scripts/run.lisp` も同じ環境変数と検査を使う。
- CI / Release の全ワークフローはこの環境変数を設定する。
- ローカルの通常実行では ROM がまったくなければ明示的にスキップする。一部だけある場合は
  不完全な結果を全テスト合格とせず、欠落名を表示して非0終了する。
- Unix の一括テストには取得スクリプトの通信置換テストも含める。Windows の通常テストに
  新たな Git Bash 依存は追加しない（ROM 取得時の既存ラッパーは維持）。

T086 の確認: 検査の未実装時に2件の新規テストが失敗。修正後は全144件合格、
不合格0件、既知の不合格3件。空・一部欠落・完備・切り詰めファイルを検証した。
ROM なしの隔離コピーでローカルの66単体テストは成功、必須モードは実行前に失敗。
取得失敗と転送内容の改変も非0終了し、一時ファイルを削除する。
全ワークフローの actionlint とシェル構文検査も成功。Windows のネイティブ実行は今回未検証。

PowerShell が呼ぶ共通の scripts/run.lisp を macOS 上で必須モード実行し、同じ144件合格を確認した。
