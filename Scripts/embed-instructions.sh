#!/bin/sh
set -eu
{
  printf 'let defaultInstructions = #"""\n'
  cat "$1"
  printf '"""#\n'
} >"$2"
