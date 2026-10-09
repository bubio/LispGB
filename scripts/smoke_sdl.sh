#!/bin/sh
# 実ウィンドウと音声デバイスを使う、ローカル向けの検証。
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/.."
LISPGB_SDL_DIR=$(mktemp -d)
trap 'rm -rf "$LISPGB_SDL_DIR"' EXIT HUP INT TERM
mkdir -p "$LISPGB_SDL_DIR/home" build/fasl
export HOME="$LISPGB_SDL_DIR/home"
export XDG_CONFIG_HOME="$LISPGB_SDL_DIR/config"
cp tests/roms/acid2/cgb-acid2.gbc "$LISPGB_SDL_DIR/test.gbc"
export LISPGB_SDL_ROM="$LISPGB_SDL_DIR/test.gbc"
sbcl --noinform --non-interactive \
 --eval '(require :asdf)' \
 --eval '(asdf:initialize-output-translations `(:output-translations (,(merge-pathnames "**/*.*" (truename "./")) ,(merge-pathnames "**/*.*" (truename "build/fasl/"))) :ignore-inherited-configuration))' \
 --eval '(asdf:load-asd (truename "lispgb.asd"))' \
 --eval '(asdf:load-system "lispgb")' \
 --load scripts/smoke_sdl.lisp
