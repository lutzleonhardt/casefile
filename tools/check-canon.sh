#!/bin/sh
# Drift guard: the canonical Work-scope block must appear verbatim
# in every published skill.
set -eu
cd "$(git rev-parse --show-toplevel)"
fail=0
for f in skills/*/SKILL.md; do
  if python3 -c 'import sys
canon = open(sys.argv[1]).read().strip()
skill = open(sys.argv[2]).read()
sys.exit(0 if canon in skill else 1)' tools/work-scope.canon.md "$f"; then
    echo "ok    $f"
  else
    echo "DRIFT $f"
    fail=1
  fi
done
exit $fail
