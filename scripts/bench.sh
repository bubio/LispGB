#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/.."
mkdir -p build/fasl
export LISPGB_BENCH_ROM="${1:-tests/roms/blargg/cpu_instrs/cpu_instrs.gb}"
exec sbcl --noinform --non-interactive \
 --eval '(require :asdf)' \
 --eval '(asdf:initialize-output-translations `(:output-translations (,(merge-pathnames "**/*.*" (truename "./")) ,(merge-pathnames "**/*.*" (truename "build/fasl/"))) :ignore-inherited-configuration))' \
 --eval '(asdf:load-asd (truename "lispgb.asd"))' \
 --eval '(asdf:load-system "lispgb/core")' \
 --load scripts/bench.lisp
