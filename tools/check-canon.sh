#!/bin/sh
# Drift guard: the canonical Work-scope block must appear verbatim
# in every skill that resolves work/doc roots. Scope-free skills
# (why) are exempt on purpose — the CLI resolves for them.
set -eu
cd "$(git rev-parse --show-toplevel)"
fail=0
for s in plan start-task wrap-up review commit; do
  f="skills/$s/SKILL.md"
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
