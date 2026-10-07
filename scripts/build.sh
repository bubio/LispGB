#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/.."
mkdir -p build/fasl
exec sbcl --noinform --non-interactive \
 --eval '(require :asdf)' \
 --eval '(asdf:initialize-output-translations `(:output-translations (,(merge-pathnames "**/*.*" (truename "./")) ,(merge-pathnames "**/*.*" (truename "build/fasl/"))) :ignore-inherited-configuration))' \
 --eval '(asdf:load-asd (truename "lispgb.asd"))' \
 --eval '(asdf:load-system "lispgb")' \
 --eval '(apply (function sb-ext:save-lisp-and-die) "build/lispgb" :executable t :toplevel (function lispgb:main) (when (member :sb-core-compression *features*) (list :compression t)))'
