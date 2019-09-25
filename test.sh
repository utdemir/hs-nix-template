#!/usr/bin/env sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TMPDIR="$(mktemp -d)"
function cleanup() {
  rm -rf "$TMPDIR"
}

cd "$TMPDIR"
cookiecutter "$DIR"
$SHELL
