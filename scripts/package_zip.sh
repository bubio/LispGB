#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/.."
case "$(uname -s)" in
    Linux) platform=linux ;;
    Darwin) platform=macos ;;
    *) echo "未対応の OS です。" >&2; exit 1 ;;
esac
case "$(uname -m)" in
    aarch64|arm64)
        case "$platform" in linux) arch=aarch64 ;; macos) arch=apple-silicon ;; esac ;;
    x86_64|amd64)
        case "$platform" in linux) arch=x86_64 ;; macos) arch=intel ;; esac ;;
    *) echo "未対応の CPU アーキテクチャです。" >&2; exit 1 ;;
esac
test -x build/lispgb
version=$(sh scripts/get_version.sh)
test "$(./build/lispgb --version)" = "LispGB $version"
mkdir -p dist
LISPGB_PACKAGE_DIR=$(mktemp -d)
trap 'rm -rf "$LISPGB_PACKAGE_DIR"' EXIT HUP INT TERM
cp build/lispgb README.md README.ja.md LICENSE "$LISPGB_PACKAGE_DIR/"
if [ "$platform" = macos ] && otool -L build/lispgb | grep -q '@executable_path/libzstd.1.dylib'; then
    cp build/libzstd.1.dylib build/zstd-LICENSE "$LISPGB_PACKAGE_DIR/"
fi
(cd "$LISPGB_PACKAGE_DIR" && zip -q package.zip ./*)
mv "$LISPGB_PACKAGE_DIR/package.zip" "dist/LispGB-$version-$platform-$arch.zip"
echo "配布物: dist/LispGB-$version-$platform-$arch.zip"
