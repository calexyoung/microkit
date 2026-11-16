#!/bin/bash
# The design kit's source of truth is MicroKit. Catch can't depend on
# MicroKit (its CI can't resolve a local path package), so it carries a
# byte-identical copy of the one file. A header comment can't stop the two
# drifting; this can. Run from either repo:
#
#   scripts/check-kit-sync.sh
#
# Exits 1 if the copies differ, 0 if they match. If the other repo isn't
# checked out beside this one there is nothing to compare: that is reported
# loudly and exits 2 (CI for Catch alone should not run this).
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
truth="$root/microkit/Sources/MicroKit/MicrotoolsKit.swift"
copy="$root/catch-the-thought/CatchTheThought/Kit/MicrotoolsKit.swift"
for f in "$truth" "$copy"; do
  if [[ ! -f "$f" ]]; then echo "MISSING $f — cannot compare"; exit 2; fi
done
if cmp -s "$truth" "$copy"; then
  echo "same  Catch's copy matches MicroKit"
else
  echo "DIFF  Catch's copy differs from MicroKit — copy MicroKit's file over it"
  exit 1
fi
