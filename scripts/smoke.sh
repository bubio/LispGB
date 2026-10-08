#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/.."
LISPGB_SMOKE_DIR=$(mktemp -d)
trap 'rm -rf "$LISPGB_SMOKE_DIR"' EXIT HUP INT TERM
export XDG_CONFIG_HOME="$LISPGB_SMOKE_DIR/config"
version=$(sh scripts/get_version.sh)
actual=$(./build/lispgb --version)
if [ "$actual" != "LispGB $version" ]; then
    echo "バージョン表示が不正です: $actual" >&2
    exit 1
fi
case "$(./build/lispgb --help)" in
    '使い方: lispgb'*) ;;
    *) echo "使い方の表示が不正です。" >&2; exit 1 ;;
esac
SDL_VIDEODRIVER=invalid SDL_AUDIODRIVER=invalid ./build/lispgb \
    --headless --frames 120 --screenshot "$LISPGB_SMOKE_DIR/cgb.bmp" tests/roms/acid2/cgb-acid2.gbc
test "$(wc -c < "$LISPGB_SMOKE_DIR/cgb.bmp")" -eq 69174
./build/lispgb --recent > "$LISPGB_SMOKE_DIR/recent.txt"
test -s "$LISPGB_SMOKE_DIR/recent.txt"
echo "実行ファイルの検証合格"
