#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sed -n 's/^[[:space:]]*:version "\([^"]*\)".*/\1/p' "$SCRIPT_DIR/../lispgb.asd" | head -n 1
