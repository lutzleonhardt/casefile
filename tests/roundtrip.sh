#!/bin/sh
# Round-trip and regression tests for the casefile CLI.
# Runs in throwaway fixture repos under mktemp; safe to run anywhere.
set -eu

KIT="$(cd "$(dirname "$0")/.." && pwd)"
S="$(mktemp -d)"
trap 'rm -rf "$S"' EXIT

# Isolate from the invoking environment: casefile resolves ~/casefile
# and the current session transcript via HOME / CLAUDE_CODE_SESSION_ID.
HOME="$S/home"
export HOME
unset CLAUDE_CODE_SESSION_ID
mkdir -p "$HOME"

cf() { python3 "$KIT/casefile" "$@"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok    $*"; }

# ── fixture 1: casefile mode ─────────────────────────────────────────
mkdir -p "$S/repo"
cd "$S/repo"
git init -q -b main
git config user.email t@example.com
git config user.name T
printf 'line1\n' > f.txt
git add f.txt
git commit -qm init

cf enable acme/demo >/dev/null
git -C "$HOME/casefile" config user.email t@example.com
git -C "$HOME/casefile" config user.name T

printf 'line2\n' >> f.txt
printf 'spaced\n' > 'a b.txt'
git add f.txt 'a b.txt'
git commit -qm 'add feature'

mkdir -p "$HOME/casefile/acme/demo/work/main/task-log"
printf '### Task\nDemo feature added.\n\n### Status\nDONE\n' \
  > "$HOME/casefile/acme/demo/work/main/task-log/task-1-demo.md"

cf link 1 demo >/dev/null
cf why f.txt:2 | grep -q 'Demo feature added' \
  || fail 'why f.txt:2 did not surface the linked task log'
pass 'round-trip: enable -> link -> why'

cf doctor >/dev/null || fail 'doctor reported problems after link'
pass 'doctor clean after link'

cf why 'a b.txt:1' | grep -q 'Demo feature added' \
  || fail 'why on a path with spaces did not resolve'
pass 'path with spaces'

# restore: a deleted local notes ref comes back from the backup
git update-ref -d refs/notes/commits
cf restore >/dev/null || fail 'restore after deleted notes ref failed'
cf why f.txt:2 | grep -q 'Demo feature added' \
  || fail 'why lost the link after restore'
pass 'restore recovers deleted notes ref'

# uncommitted line: clear message, no traceback
printf 'line3\n' >> f.txt
st=0; out="$(cf why f.txt:3 2>&1)" || st=$?
[ "$st" -ne 0 ] || fail 'why on an uncommitted line must exit non-zero'
echo "$out" | grep -q 'uncommitted' \
  || fail "why on an uncommitted line lacks a clear message: $out"
if echo "$out" | grep -q 'Traceback'; then
  fail 'why on an uncommitted line crashed with a traceback'
fi
git checkout -q -- f.txt
pass 'uncommitted line dies cleanly'

# shallow guard: blame at the truncation point must refuse, not misattribute
git clone -q --depth 1 "file://$S/repo" "$S/shallow"
cd "$S/shallow"
st=0; out="$(cf why f.txt:1 2>&1)" || st=$?
[ "$st" -ne 0 ] || fail 'why at the shallow boundary must exit non-zero'
echo "$out" | grep -q 'unshallow' \
  || fail "shallow-boundary message must mention unshallow: $out"
pass 'shallow-clone boundary guard'

# ── fixture 2: home mode, log co-committed with the code ─────────────
mkdir -p "$S/repo2"
cd "$S/repo2"
git init -q -b main
git config user.email t@example.com
git config user.name T
printf 'code\n' > code.txt
mkdir -p docs/work/main/task-log
printf '### Task\nHome-mode log travels with the commit.\n' \
  > docs/work/main/task-log/task-1-x.md
git add code.txt docs
git commit -qm 'task-1: x'

out="$(cf why code.txt:1)" \
  || fail 'home mode: why failed on a co-committed task log'
echo "$out" | grep -q 'co-committed' \
  || fail 'home mode: expected the co-committed channel marker'
echo "$out" | grep -q 'Home-mode log travels' \
  || fail 'home mode: co-committed log content not shown'
pass 'home mode co-committed channel'

# ── fixture 3: link a named summary from its original feature scope ──
cd "$S/repo"
git checkout -qb feat/squash-demo
printf 'squashed feature\n' > squashed.txt
git add squashed.txt
git commit -qm 'implement feature'
git checkout -q main
git merge --squash feat/squash-demo >/dev/null
git commit -qm 'squash feature'
squash_sha="$(git rev-parse HEAD)"
git checkout -q feat/squash-demo

squash_logs="$(cf root)/task-log"
mkdir -p "$squash_logs"
printf '### Task\nSummary of the squashed feature.\n' \
  > "$squash_logs/squash-$squash_sha.md"
cf link "squash-$squash_sha" "$squash_sha" --no-session >/dev/null
casefile_head="$(git -C "$HOME/casefile" rev-parse HEAD)"
cf link "squash-$squash_sha" "$squash_sha" --no-session >/dev/null
[ "$(git -C "$HOME/casefile" rev-parse HEAD)" = "$casefile_head" ] \
  || fail 'squash: retry created another casefile commit'
squash_pointer="tasklog: acme/demo/work/squash-demo/task-log/squash-$squash_sha.md"
[ "$(git notes show "$squash_sha" | grep -Fxc "$squash_pointer")" = 1 ] \
  || fail 'squash: expected exactly one pointer to the feature-scope summary'
out="$(cf doctor)"
echo "$out" | grep -q 'backup: in sync' \
  || fail 'squash: notes backup is not in sync'
git checkout -q main
out="$(cf why squashed.txt:1)"
echo "$out" | grep -Fq "$squash_pointer" \
  || fail 'squash: why on main did not resolve the feature-scope summary'
echo "$out" | grep -q 'Summary of the squashed feature' \
  || fail 'squash: why did not read the summary content'
pass 'squash: named log + explicit SHA from feature scope, retry, backup, why on main'

echo 'all tests passed'
