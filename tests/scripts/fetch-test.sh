#!/bin/sh
# 通信を置き換え、固定取得元・ダイジェスト・キャッシュを検証する。
set -eu
LISPGB_TEST_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
LISPGB_FETCH_TEST=$(mktemp -d)
trap 'rm -rf "$LISPGB_FETCH_TEST"' EXIT HUP INT TERM
mkdir -p "$LISPGB_FETCH_TEST/scripts" "$LISPGB_FETCH_TEST/tests" "$LISPGB_FETCH_TEST/bin"
cp "$LISPGB_TEST_ROOT/scripts/fetch_test_roms.sh" "$LISPGB_FETCH_TEST/scripts/"
cp -R "$LISPGB_TEST_ROOT/tests/roms" "$LISPGB_FETCH_TEST/tests/"
cp "$LISPGB_TEST_ROOT/tests/rom-manifest.txt" "$LISPGB_FETCH_TEST/tests/"
export LISPGB_FETCH_REFERENCE="$LISPGB_TEST_ROOT/tests/roms/acid2"
export LISPGB_FETCH_LOG="$LISPGB_FETCH_TEST/requests"
cat > "$LISPGB_FETCH_TEST/bin/curl" <<'MOCK'
#!/bin/sh
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o) output=$2; shift 2 ;;
        --retry|--retry-delay) shift 2 ;;
        -*) shift ;;
        *) url=$1; shift ;;
    esac
done
printf '%s\n' "$url" >> "$LISPGB_FETCH_LOG"
if [ "${LISPGB_FETCH_FAIL:-0}" = 1 ]; then exit 22; fi
if [ "${LISPGB_FETCH_CORRUPT:-0}" = 1 ]; then printf broken > "$output"; exit 0; fi
case "$url" in
    */dmg-acid2.gb) cp "$LISPGB_FETCH_REFERENCE/dmg-acid2.gb" "$output" ;;
    */cgb-acid2.gbc) cp "$LISPGB_FETCH_REFERENCE/cgb-acid2.gb" "$output" ;;
    *) exit 1 ;;
esac
MOCK
chmod +x "$LISPGB_FETCH_TEST/bin/curl"
export PATH="$LISPGB_FETCH_TEST/bin:$PATH"
rm "$LISPGB_FETCH_TEST/tests/roms/acid2/"*
sh "$LISPGB_FETCH_TEST/scripts/fetch_test_roms.sh" > "$LISPGB_FETCH_TEST/output" 2>&1
test "$(wc -l < "$LISPGB_FETCH_LOG" | tr -d ' ')" -eq 2
grep -q '/c458e7c5d2d350fb37a1931c40da9f758d28d240/.github/actions/dmg-acid2.gb' "$LISPGB_FETCH_LOG"
grep -q '/c458e7c5d2d350fb37a1931c40da9f758d28d240/.github/actions/cgb-acid2.gbc' "$LISPGB_FETCH_LOG"
cmp "$LISPGB_FETCH_REFERENCE/dmg-acid2.gb" "$LISPGB_FETCH_TEST/tests/roms/acid2/dmg-acid2.gb"
cmp "$LISPGB_FETCH_REFERENCE/cgb-acid2.gb" "$LISPGB_FETCH_TEST/tests/roms/acid2/cgb-acid2.gbc"
# 正しい取得済みの ROM は再取得しない。
sh "$LISPGB_FETCH_TEST/scripts/fetch_test_roms.sh" > "$LISPGB_FETCH_TEST/output" 2>&1
test "$(wc -l < "$LISPGB_FETCH_LOG" | tr -d ' ')" -eq 2
# 改変されたキャッシュは上書きせず、失敗を返す。
printf 'broken' > "$LISPGB_FETCH_TEST/tests/roms/acid2/dmg-acid2.gb"
if sh "$LISPGB_FETCH_TEST/scripts/fetch_test_roms.sh" > "$LISPGB_FETCH_TEST/output" 2>&1; then
    echo '改変された ROM を受理しました。' >&2; exit 1
fi
test "$(cat "$LISPGB_FETCH_TEST/tests/roms/acid2/dmg-acid2.gb")" = broken
# 取得失敗と転送中の改変は成功として終了せず、一時ファイルを残さない。
rm "$LISPGB_FETCH_TEST/tests/roms/acid2/dmg-acid2.gb"
for kind in fail corrupt; do
    LISPGB_FETCH_FAIL=0; LISPGB_FETCH_CORRUPT=0
    if [ "$kind" = fail ]; then LISPGB_FETCH_FAIL=1; else LISPGB_FETCH_CORRUPT=1; fi
    export LISPGB_FETCH_FAIL LISPGB_FETCH_CORRUPT
    if sh "$LISPGB_FETCH_TEST/scripts/fetch_test_roms.sh" > "$LISPGB_FETCH_TEST/output" 2>&1; then
        echo 'ROM の取得失敗を見逃しました。' >&2; exit 1
    fi
    test ! -e "$LISPGB_FETCH_TEST/tests/roms/acid2/dmg-acid2.gb"
    test ! -e "$LISPGB_FETCH_TEST/tests/roms/acid2/dmg-acid2.gb.tmp"
done
echo 'ROM 固定取得・照合・取得失敗の検証合格'
