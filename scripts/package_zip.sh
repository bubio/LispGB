#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/.."
case "$(uname -m)" in
    aarch64|arm64) ;;
    *) echo "この配布スクリプトは Linux arm64 用です。" >&2; exit 1 ;;
esac
test -x build/lispgb
version=$(sh scripts/get_version.sh)
test "$(./build/lispgb --version)" = "LispGB $version"
mkdir -p dist
LISPGB_PACKAGE_DIR=$(mktemp -d)
trap 'rm -rf "$LISPGB_PACKAGE_DIR"' EXIT HUP INT TERM
cp build/lispgb README.md README.ja.md LICENSE "$LISPGB_PACKAGE_DIR/"
(cd "$LISPGB_PACKAGE_DIR" && zip -q package.zip lispgb README.md README.ja.md LICENSE)
mv "$LISPGB_PACKAGE_DIR/package.zip" "dist/LispGB-$version-linux-arm64.zip"
echo "配布物: dist/LispGB-$version-linux-arm64.zip"
