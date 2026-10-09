#!/bin/sh
# アーキテクチャ別の ZIP を展開し、配布先での起動を確認する。
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/.."
case "${1:-}" in
    arm64) arch=arm64; cpu=arm64 ;;
    amd64) arch=amd64; cpu=x86_64 ;;
    *) echo "使い方: verify_macos_package.sh arm64|amd64" >&2; exit 2 ;;
esac
version=$(sh scripts/get_version.sh)
LISPGB_VERIFY_DIR=$(mktemp -d)
trap 'rm -rf "$LISPGB_VERIFY_DIR"' EXIT HUP INT TERM
unzip -q "dist/LispGB-$version-macos-$arch.zip" -d "$LISPGB_VERIFY_DIR"
# 単一の CPU スライスだけを持ち、同梱ライブラリも同じ CPU であること。
test "$(lipo -archs "$LISPGB_VERIFY_DIR/lispgb")" = "$cpu"
for library in "$LISPGB_VERIFY_DIR"/*.dylib; do
    if [ -f "$library" ]; then
        test "$(lipo -archs "$library")" = "$cpu"
    fi
done
test "$(env -i PATH=/nonexistent "$LISPGB_VERIFY_DIR/lispgb" --version)" = "LispGB $version"
mkdir -p "$LISPGB_VERIFY_DIR/home"
HOME="$LISPGB_VERIFY_DIR/home" XDG_CONFIG_HOME="$LISPGB_VERIFY_DIR/config" \
SDL_VIDEODRIVER=invalid SDL_AUDIODRIVER=invalid "$LISPGB_VERIFY_DIR/lispgb" \
    --headless --frames 120 --screenshot "$LISPGB_VERIFY_DIR/frame.bmp" tests/roms/acid2/cgb-acid2.gbc
test "$(wc -c < "$LISPGB_VERIFY_DIR/frame.bmp")" -eq 69174
echo "macOS $arch 配布物の検証合格（単一 CPU・展開後の起動と描画）"
