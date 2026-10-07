# 契約: 設定ファイルと最近使った ROM の一覧

spec FR-017、FR-018。

## 置き場所

| OS | ディレクトリ |
|---|---|
| Linux | `$XDG_CONFIG_HOME/LispGB/`（未設定または空なら `~/.config/LispGB/`） |
| macOS（将来） | `~/Library/Application Support/LispGB/` |
| Windows（将来） | `%APPDATA%\LispGB\` |

ディレクトリがなければ、親ディレクトリも含めて作る。作れない場合は警告を出し、既定値で
起動を続ける（設定も一覧も保存しない）。

## `config.txt`

UTF-8 で、1行に1項目を `key = value` の形で書く。`#` から行末まではコメント。前後の
空白は無視する。

```
# LispGB 設定ファイル
scale = 4
fullscreen = false
shader = nearest
volume = 100
```

| key | 値 | 既定 |
|---|---|---|
| scale | 1〜8 の整数（9 以上は 8 に丸める） | 4 |
| fullscreen | `true` / `false` | false |
| shader | `nearest` / `smooth` | nearest |
| volume | 0〜100 の整数 | 100 |

- ファイルがなければ、上の既定値で生成する。
- 未知の key、解釈できない値、`=` がない行は無視する（その項目は既定値のまま。警告は出さない）。
- 起動中に設定ファイルを書き換えることはない（生成するときだけ書く）。

## `recent.txt`

- UTF-8 で、1行に1件、ROM の絶対パスを書く。先頭が最も新しい。
- ROM を起動するたびに、そのパスを先頭に移し、重複を除いて最大10件に切り詰める。
- 書き込みは、一時ファイルに書いてから `rename` する。
