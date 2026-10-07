#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR/.."
mkdir -p build/fasl-safe
exec sbcl --noinform --non-interactive \
  --eval '(pushnew :lispgb-safe *features*)' \
  --eval '(require :asdf)' \
  --eval '(asdf:initialize-output-translations `(:output-translations (t ,(truename "build/fasl-safe/")) :ignore-inherited-configuration))' \
  --eval '(asdf:load-asd (truename "lispgb.asd"))' \
  --eval '(asdf:load-system "lispgb/tests")' \
  --eval '(unless (directory "tests/roms/**/*.gb*") (format t "テスト ROM がないため ROM テストをスキップします。~%"))' \
  --eval '(let ((failures (lispgb.tests:run-tests))) (when (zerop failures) (format t "全テスト合格~%")) (uiop:quit (if (zerop failures) 0 1)))'
