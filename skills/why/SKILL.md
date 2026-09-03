---
name: why
description: Answer why a line of code is the way it is.
  Blames the line, follows the commit's task-log link via the
  casefile CLI, and answers from the log's recorded decisions,
  citing the evidence chain.
---
# Why (`/why FILE:LINE`)

The user points at code and asks why it is the way it is. Do not
speculate from the code — pull the case file.

## Input — `$ARGUMENTS`

- `FILE:LINE` — the primary form (e.g. `/why src/auth.ts:120`).
- A bare `FILE` plus a quoted snippet or symbol: locate the line
  first (`rg -n`), then proceed. If the location stays ambiguous,
  ask instead of guessing.

## Workflow

1. **Run the CLI — this is the whole retrieval:**

   ```
   casefile why FILE:LINE
   ```

   It blames the line, resolves the commit, and prints the linked
   task log — via git note in casefile mode, via the co-committed
   log in home mode. Use `--head N` only when the log is very long.
   Never re-implement the blame → note → log chain by hand; if
   `casefile` is not on PATH, stop and point at the kit's installer.

2. **Read what it printed.** The answer usually lives in
   `### Key Decisions` (what was decided, why, and what was
   rejected), `### Root Cause` (fix-lane logs), or the one-line
   `### Task` summary.

3. **Mechanical blame hit?** If the blamed commit is clearly
   formatting, a rename, or a sweep, the reason lives deeper:
   `git log -L<LINE>,<LINE>:<FILE>` walks the line's history and
   shows each commit's note (`tasklog:` pointer) inline — follow
   the first substantive commit's log instead.

4. **No linked log** (`no note and no co-committed task log`):
   fall back honestly — `git log -1 <sha>` for the commit message,
   `casefile search '<term>'` for related logs in casefile mode.
   Say explicitly that no log is linked; do not dress a guess up
   as provenance.

## Output shape

Keep it compact:

- **Answer:** 1–3 sentences — the reason, sourced from the log or
  commit, not inferred from the code.
- **Evidence:** the chain `FILE:LINE → <sha> (<subject>) →
  <log path>`, plus the log section(s) the answer rests on.
- **Caveat** — only when needed: the line changed after the log
  was written, the log contradicts the current code, or no log
  exists.
