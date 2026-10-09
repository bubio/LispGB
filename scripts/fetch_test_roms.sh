#!/bin/sh
set -e

# tests/roms/ にテスト ROM (Blargg) を配置するスクリプト。
# ライセンス上、テスト ROM をリポジトリにコミットしないため CI・ローカルの両方で
# このスクリプトを通して都度取得する（tests/roms/ は .gitignore 対象）。
# 再実行しても安全（取得済みファイルはスキップ）。

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
ROMS_DIR="$PROJECT_ROOT/tests/roms"
BLARGG_DIR="$ROMS_DIR/blargg"

# retrio/gb-test-roms をコミット固定で取得する
BLARGG_COMMIT="c240dd7d700e5c0b00a7bbba52b53e4ee67b5f15"
BLARGG_BASE_URL="https://raw.githubusercontent.com/retrio/gb-test-roms/$BLARGG_COMMIT"
MOONEYE_COMMIT="6745fe8ccc5e8035e104934dcea8c6500171b65e"
MOONEYE_BASE_URL="https://raw.githubusercontent.com/asoderman/Mooneye-Test-Suite-ROMS/$MOONEYE_COMMIT"

mkdir -p "$BLARGG_DIR/cpu_instrs/individual" "$BLARGG_DIR/instr_timing" \
	"$BLARGG_DIR/dmg_sound/rom_singles" \
	"$ROMS_DIR/mooneye/acceptance/timer" "$ROMS_DIR/mooneye/acceptance/interrupts" \
	"$ROMS_DIR/mooneye/acceptance/ppu" "$ROMS_DIR/acid2"

fetch() {
	remote_path="$1"
	local_path="$2"

	if [ -f "$local_path" ]; then
		echo "fetch_test_roms.sh: 取得済み、スキップ: $local_path"
		return 0
	fi

	echo "fetch_test_roms.sh: 取得中: $remote_path"
	tmp_path="$local_path.tmp"
	encoded_path=$(printf '%s' "$remote_path" | sed 's/ /%20/g')
	if ! curl -fsSL --retry 3 --retry-delay 2 -o "$tmp_path" "$BLARGG_BASE_URL/$encoded_path"; then
		rm -f "$tmp_path"
		echo "fetch_test_roms.sh: 取得失敗: $remote_path" >&2
		return 1
	fi
	mv "$tmp_path" "$local_path"
}

# cpu_instrs 個別 ROM（ROM-only、フェーズ1でパスさせる対象）
fetch "cpu_instrs/individual/01-special.gb" "$BLARGG_DIR/cpu_instrs/individual/01-special.gb"
fetch "cpu_instrs/individual/02-interrupts.gb" "$BLARGG_DIR/cpu_instrs/individual/02-interrupts.gb"
fetch "cpu_instrs/individual/03-op sp,hl.gb" "$BLARGG_DIR/cpu_instrs/individual/03-op sp,hl.gb"
fetch "cpu_instrs/individual/04-op r,imm.gb" "$BLARGG_DIR/cpu_instrs/individual/04-op r,imm.gb"
fetch "cpu_instrs/individual/05-op rp.gb" "$BLARGG_DIR/cpu_instrs/individual/05-op rp.gb"
fetch "cpu_instrs/individual/06-ld r,r.gb" "$BLARGG_DIR/cpu_instrs/individual/06-ld r,r.gb"
fetch "cpu_instrs/individual/07-jr,jp,call,ret,rst.gb" "$BLARGG_DIR/cpu_instrs/individual/07-jr,jp,call,ret,rst.gb"
fetch "cpu_instrs/individual/08-misc instrs.gb" "$BLARGG_DIR/cpu_instrs/individual/08-misc instrs.gb"
fetch "cpu_instrs/individual/09-op r,r.gb" "$BLARGG_DIR/cpu_instrs/individual/09-op r,r.gb"
fetch "cpu_instrs/individual/10-bit ops.gb" "$BLARGG_DIR/cpu_instrs/individual/10-bit ops.gb"
fetch "cpu_instrs/individual/11-op a,(hl).gb" "$BLARGG_DIR/cpu_instrs/individual/11-op a,(hl).gb"

# cpu_instrs 統合版（MBC1 が必要。フェーズ4まで許可リストに残す）
fetch "cpu_instrs/cpu_instrs.gb" "$BLARGG_DIR/cpu_instrs/cpu_instrs.gb"

# instr_timing（フェーズ1でパスさせる対象）
fetch "instr_timing/instr_timing.gb" "$BLARGG_DIR/instr_timing/instr_timing.gb"

# dmg_sound 個別ROM（フェーズ5でパスさせる対象。MBC1+RAM+BATTERY、cpu_instrsと
# 同じピン留めコミットから取得するため新規ピン留めは不要）
fetch "dmg_sound/rom_singles/01-registers.gb" "$BLARGG_DIR/dmg_sound/rom_singles/01-registers.gb"
fetch "dmg_sound/rom_singles/02-len ctr.gb" "$BLARGG_DIR/dmg_sound/rom_singles/02-len ctr.gb"
fetch "dmg_sound/rom_singles/03-trigger.gb" "$BLARGG_DIR/dmg_sound/rom_singles/03-trigger.gb"
fetch "dmg_sound/rom_singles/04-sweep.gb" "$BLARGG_DIR/dmg_sound/rom_singles/04-sweep.gb"
fetch "dmg_sound/rom_singles/05-sweep details.gb" "$BLARGG_DIR/dmg_sound/rom_singles/05-sweep details.gb"
fetch "dmg_sound/rom_singles/06-overflow on trigger.gb" "$BLARGG_DIR/dmg_sound/rom_singles/06-overflow on trigger.gb"
fetch "dmg_sound/rom_singles/07-len sweep period sync.gb" "$BLARGG_DIR/dmg_sound/rom_singles/07-len sweep period sync.gb"
fetch "dmg_sound/rom_singles/08-len ctr during power.gb" "$BLARGG_DIR/dmg_sound/rom_singles/08-len ctr during power.gb"
fetch "dmg_sound/rom_singles/09-wave read while on.gb" "$BLARGG_DIR/dmg_sound/rom_singles/09-wave read while on.gb"
fetch "dmg_sound/rom_singles/10-wave trigger while on.gb" "$BLARGG_DIR/dmg_sound/rom_singles/10-wave trigger while on.gb"
fetch "dmg_sound/rom_singles/11-regs after power.gb" "$BLARGG_DIR/dmg_sound/rom_singles/11-regs after power.gb"
fetch "dmg_sound/rom_singles/12-wave write while on.gb" "$BLARGG_DIR/dmg_sound/rom_singles/12-wave write while on.gb"

fetch_mooneye() {
	remote_path="$1"
	local_path="$2"

	if [ -f "$local_path" ]; then
		echo "fetch_test_roms.sh: 取得済み、スキップ: $local_path"
		return 0
	fi

	echo "fetch_test_roms.sh: 取得中: $remote_path"
	tmp_path="$local_path.tmp"
	if ! curl -fsSL --retry 3 --retry-delay 2 -o "$tmp_path" "$MOONEYE_BASE_URL/$remote_path"; then
		rm -f "$tmp_path"
		echo "fetch_test_roms.sh: 取得失敗: $remote_path" >&2
		return 1
	fi
	mv "$tmp_path" "$local_path"
}

for name in div_write rapid_toggle tim00 tim00_div_trigger tim01 tim01_div_trigger \
	tim10 tim10_div_trigger tim11 tim11_div_trigger tima_reload \
	tima_write_reloading tma_write_reloading
do
	fetch_mooneye "acceptance/timer/$name.gb" "$ROMS_DIR/mooneye/acceptance/timer/$name.gb"
done

# acceptance/interrupts: 割り込み系 acceptance ROM（フェーズ2）
for name in ei_sequence ei_timing halt_ime0_ei halt_ime0_nointr_timing \
	halt_ime1_timing if_ie_registers intr_timing rapid_di_ei \
	reti_intr_timing reti_timing
do
	fetch_mooneye "acceptance/$name.gb" "$ROMS_DIR/mooneye/acceptance/$name.gb"
done
fetch_mooneye "acceptance/interrupts/ie_push.gb" "$ROMS_DIR/mooneye/acceptance/interrupts/ie_push.gb"

# acceptance/ppu: STAT blocking / LYC on-off の acceptance ROM(フェーズ3)
for name in stat_irq_blocking stat_lyc_onoff
do
	fetch_mooneye "acceptance/ppu/$name.gb" "$ROMS_DIR/mooneye/acceptance/ppu/$name.gb"
done

# emulator-only/mbc1,mbc2,mbc5: MBC系 ROM(フェーズ4)。MBC3(+RTC)はmooneyeスイート
# に該当ROMが無いため、MbcTest内のユニットテストで検証する(docs/dev/phases/
# phase-04-cartridge-mbc.md参照)。MBC1Mマルチカート(multicart_rom_8Mb)は
# BubiBoy Lite同様スコープ外。
mkdir -p "$ROMS_DIR/mooneye/emulator-only/mbc1" "$ROMS_DIR/mooneye/emulator-only/mbc2" \
	"$ROMS_DIR/mooneye/emulator-only/mbc5"

for name in bits_ramg bits_bank1 bits_bank2 bits_mode rom_512kb rom_1Mb rom_2Mb \
	rom_4Mb rom_8Mb rom_16Mb ram_64kb ram_256kb
do
	fetch_mooneye "emulator-only/mbc1/$name.gb" "$ROMS_DIR/mooneye/emulator-only/mbc1/$name.gb"
done

for name in bits_ramg bits_romb bits_unused ram rom_512kb rom_1Mb rom_2Mb
do
	fetch_mooneye "emulator-only/mbc2/$name.gb" "$ROMS_DIR/mooneye/emulator-only/mbc2/$name.gb"
done

for name in rom_512kb rom_1Mb rom_2Mb rom_4Mb rom_8Mb rom_16Mb rom_32Mb rom_64Mb
do
	fetch_mooneye "emulator-only/mbc5/$name.gb" "$ROMS_DIR/mooneye/emulator-only/mbc5/$name.gb"
done

# SameBoy の検証用 ROM を固定コミットから取得する。
# 元の公式リリースとバイト一致することを確認した SHA256 も照合する。
ACID2_COMMIT="c458e7c5d2d350fb37a1931c40da9f758d28d240"
ACID2_BASE_URL="https://raw.githubusercontent.com/LIJI32/SameBoy/$ACID2_COMMIT/.github/actions"
DMG_ACID2_SHA256="464e14b7d42e7feea0b7ede42be7071dc88913f75b9ffa444299424b63d1dff1"
CGB_ACID2_SHA256="197fb0bcec544f0400527fc707e0a94f55435974986e6986b424ace5de81720e"

verify_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        actual=$(sha256sum "$1" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        actual=$(shasum -a 256 "$1" | awk '{print $1}')
    else
        echo "SHA256 の照合には sha256sum または shasum が必要です。" >&2
        return 1
    fi
    if [ "$actual" != "$2" ]; then
        echo "テスト ROM の SHA256 が一致しません: $1" >&2
        return 1
    fi
}

fetch_acid2() {
    acid_name=$1
    acid_path=$2
    acid_hash=$3
    if [ -f "$acid_path" ]; then
        verify_sha256 "$acid_path" "$acid_hash"
        echo "fetch_test_roms.sh: 照合済み、スキップ: $acid_path"
        return 0
    fi
    acid_tmp="$acid_path.tmp"
    if ! curl -fsSL --retry 3 --retry-delay 2 -o "$acid_tmp" "$ACID2_BASE_URL/$acid_name"; then
        rm -f "$acid_tmp"
        echo "テスト ROM の取得に失敗しました: $acid_name" >&2
        return 1
    fi
    if ! verify_sha256 "$acid_tmp" "$acid_hash"; then
        rm -f "$acid_tmp"
        return 1
    fi
    mv "$acid_tmp" "$acid_path"
}

fetch_acid2 dmg-acid2.gb "$ROMS_DIR/acid2/dmg-acid2.gb" "$DMG_ACID2_SHA256"
fetch_acid2 cgb-acid2.gbc "$ROMS_DIR/acid2/cgb-acid2.gb" "$CGB_ACID2_SHA256"
# 既存のスイートの .gb 名と利用ガイドの .gbc 名を両方維持する。
if [ ! -e "$ROMS_DIR/acid2/cgb-acid2.gbc" ]; then
    cp "$ROMS_DIR/acid2/cgb-acid2.gb" "$ROMS_DIR/acid2/cgb-acid2.gbc"
fi
verify_sha256 "$ROMS_DIR/acid2/cgb-acid2.gbc" "$CGB_ACID2_SHA256"
echo "fetch_test_roms.sh: 完了。配置先: $ROMS_DIR"
