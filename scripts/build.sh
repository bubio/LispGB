#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/.."
mkdir -p build/fasl
LISPGB_SBCL_COMMAND=sbcl
if [ "$(uname -s)" = Darwin ]; then
    # コアを連結した後では install_name_tool が使えないため、ランタイムを先に調整する。
    LISPGB_RUNTIME=$(sbcl --noinform --non-interactive --eval '(write-string (namestring sb-ext:*runtime-pathname*))')
    LISPGB_SBCL_HOME=$(sbcl --noinform --non-interactive --eval '(write-string (namestring (sb-int:sbcl-homedir-pathname)))')
    cp "$LISPGB_RUNTIME" build/lispgb-runtime
    LISPGB_ZSTD_LIBRARY=$(otool -L build/lispgb-runtime | awk '/\/libzstd[^ ]*\.dylib / {print $1}')
    if [ -n "$LISPGB_ZSTD_LIBRARY" ]; then
        LISPGB_ZSTD_PREFIX=$(dirname "$(dirname "$LISPGB_ZSTD_LIBRARY")")
        # Homebrew の dylib は読み取り専用。再ビルド時は既存のコピーを置き換える。
        cp -f "$LISPGB_ZSTD_LIBRARY" build/libzstd.1.dylib
        chmod u+w build/libzstd.1.dylib
        cp "$LISPGB_ZSTD_PREFIX/LICENSE" build/zstd-LICENSE
        install_name_tool -change "$LISPGB_ZSTD_LIBRARY" '@executable_path/libzstd.1.dylib' build/lispgb-runtime
        codesign --force --sign - build/libzstd.1.dylib
        codesign --force --sign - build/lispgb-runtime
    fi
    export SBCL_HOME="$LISPGB_SBCL_HOME"
    LISPGB_SBCL_COMMAND=./build/lispgb-runtime
fi
exec "$LISPGB_SBCL_COMMAND" --noinform --non-interactive \
 --eval '(require :asdf)' \
 --eval '(asdf:initialize-output-translations `(:output-translations (,(merge-pathnames "**/*.*" (truename "./")) ,(merge-pathnames "**/*.*" (truename "build/fasl/"))) :ignore-inherited-configuration))' \
 --eval '(asdf:load-asd (truename "lispgb.asd"))' \
 --eval '(asdf:load-system "lispgb")' \
 --eval '(apply (function sb-ext:save-lisp-and-die) "build/lispgb" :executable t :save-runtime-options t :toplevel (function lispgb:main) (when (member :sb-core-compression *features*) (list :compression t)))'
