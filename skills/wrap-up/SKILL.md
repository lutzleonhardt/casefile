---
name: wrap-up
description: Generate or extend a structured task summary
  at the end of a completed or blocked task.
  For BLOCKED tasks, also evaluates escalation
  triggers and proposes a re-plan.
---
# Task Wrap-Up

The task is finished (or has been declared blocked).
Write (or extend) the task summary file at
`docs/work/<scope>/task-log/task-{N}-{slug}.md`.

- `{N}` = task number from the plan
- `{slug}` = short kebab-case description (e.g. `login-service`)
- `<scope>` = derived from the current git branch (see Work scope)

One task gets exactly one log file. No date in the filename —
the date lives in git history (commit date) and optionally in
session markers inside the file.

If the task is NOT finished, do not run this skill — it is
for completed or blocked tasks only.

## Work scope

Resolve the active roots before touching any plan, log, or doc path:

```
casefile root -v
```

Trust its output verbatim: `work root` is where `plan.md` and
`task-log/` live — every `docs/work/<scope>/` path in this skill
refers to it. `doc root` is where project-global docs (specs,
architecture, improvements) live — every other `docs/` path in this
skill resolves against it. `scope` and `mode` come from the same
output; do not re-derive any of them, and let the CLI's own errors
(detached HEAD, missing casefile repo) stop the run. If `casefile` is not
on PATH, stop: the kit ships with its CLI — reinstall it instead of
deriving paths by hand. In casefile mode, work artifacts never enter
the current repository.

If `<work-root>/plan.md` is missing, stop and tell the user to run
`/plan` on this branch first. Legacy layouts (`docs/plans/`, a
root `plan.md`, `docs/task-log/`) are never automatic fallbacks —
migrate them into the scoped work root first.
**Exception:** the fix lane (below) needs no plan — a missing
`plan.md` never stops `/wrap-up fix`.

## Task identity — `$ARGUMENTS`

Use `$ARGUMENTS` to identify the task being closed
(e.g. `/wrap-up 3` means Task 3). The skill must know
the task number before it writes anything.

Resolution rules, in order:

1. If `$ARGUMENTS` contains a number, use that.
2. Else, if this session was primed by `/start-task N`
   (or an earlier `/wrap-up N` / `/commit N`) and N is
   unambiguous in context, use N.
3. Else, **stop** and tell the user:
   > Task number required. Run as `/wrap-up N`.
   Do not guess, do not scan the plan, do not write a file.

Fresh sessions (review-fix, retroactive wrap-up, cross-session
handoff) always need the explicit argument — session context
alone is not enough.

## Fix lane — unplanned work (`/wrap-up fix …`)

Not everything grows from a plan. A sporadic bugfix, a small
chore, an ad-hoc improvement — one commit, no task number — still
deserves provenance: log + commit link + session archive, minus
the plan ceremony.

- **Identity:** `fix-<slug>` — derive `<slug>` from the user's
  description the same way task slugs are derived (short
  kebab-case). Other conventional-commit types are valid stems
  when the work clearly isn't a fix (`chore-…`, `docs-…`,
  `perf-…`); `fix` is the default. State the chosen identity in
  the closing message — `/commit fix` resolves it from there.
- **File:** `docs/work/<scope>/task-log/fix-<slug>.md`. Scope
  stays branch-derived: on `main`, `work/main/` is the natural
  ad-hoc ledger; a side-fix on a feature branch lands in that
  branch's scope — exactly where the relevance search will later
  look for it.
- **No plan required** — the plan.md check does not apply.
- **Retroactive is the normal case:** the fix usually already
  happened in this or another session; write the log from the
  session's evidence while the user reviews the change.
- **Template — slimmed base structure:**
  - Add **### Root Cause** directly after `### Status` — for a
    bug this is the section that pays rent later: what was
    actually wrong, and why it manifested the way it did.
  - Drop **Acceptance Coverage** entirely (there are no AC IDs).
  - **Context for Next Task** only when the fix leaves something
    behind (follow-up, gotcha); otherwise omit.
  - Everything else (Files Modified, Key Decisions, Review Focus,
    Test Evidence, Open Issues, Git State, Sessions) applies
    unchanged.
- **When NOT to use it:** trivial diffs without a diagnosis —
  typo, dependency bump, comment fix — need no log; the commit is
  documentation enough. The test: will someone plausibly ask in
  six months why this line is the way it is? If a real root cause
  was found or a behavior decision made, write the log.
- **Closing message:** point at `/commit fix` (same session) or
  `/commit fix-<slug>` (fresh session) instead of `/commit {N}`.

## Precondition — run BEFORE committing the task's code

Wrap-up must happen **before** the task's code changes are
committed. The intended flow is:

1. Finish the code changes (do NOT commit yet).
2. Run `/wrap-up N` → scoped summary file is written (or extended).
3. Run `/commit N` → commits code + summary together.

If the task's code has already been committed when
`/wrap-up N` is invoked, stop and tell the user:

> Task-N code was already committed as `<hash>`. The
> wrap-up summary belongs in that commit. Either:
>
>   (a) amend the commit to include the summary (only if
>       the commit has not been pushed), or
>
>   (b) land the summary as a separate follow-up commit
>       (`docs: task-N wrap-up summary`) and accept the
>       broken single-commit rule for this task.

Ask the user which option before writing the file, so the
summary lands in the right commit from the start.

**Casefile mode exception:** the summary never becomes part of the
code commit — the link is a git note added by `/commit N`. If the
task's code is already committed in casefile mode, do not stop:
proceed with the wrap-up and tell the user that `/commit N` will
attach the note to the existing commit instead of creating one.

## Log-file lookup — merge or fresh

Before writing, check for an existing log:

```
ls docs/work/<scope>/task-log/task-{N}-*.md 2>/dev/null
```

- **No file** — fresh write, normal path.
- **Exactly one file** — read it, **merge** with the new
  session's findings (see merge rules below). Show the user
  the proposed merged file and wait for approval before
  writing.
- **Multiple files** — the filename convention was violated inside
  this work scope. Stop and tell the user; ask which file to extend,
  or let them rename/consolidate manually before continuing.

## Merge rules (when a log file already exists)

Read the existing file, then integrate the new session's
output as follows:

- **Task** (one-sentence summary): keep existing unless the
  new session materially changes scope; if it does, rewrite
  and flag the change.
- **Status**: replace with the current status. If the prior
  status was BLOCKED and the new status is DONE, drop the
  Escalation Assessment and Re-Plan Proposal sections
  entirely (they are historical noise once unblocked).
- **Files Modified**: union the lists. If the same file
  appears in both, keep the most informative reason or
  merge both reasons on one line.
- **Files Read (Context Only)**: union the lists.
- **Key Decisions**: append new decisions under a session
  marker (see below). Do not rewrite prior decisions — they
  are part of the record.
- **Test Evidence**: append new evidence under a session
  marker. Accumulates across sessions.
- **Acceptance Coverage**: union the AC IDs. If an AC was
  partial/skipped in the prior session and is now passed, replace
  it. If it was passed and now regresses, surface that explicitly
  instead of silently downgrading it.
- **Review Focus**: replace with the current view. This section is
  a live map for the next human review, not a historical record.
- **Open Issues**: merge; drop issues that are now resolved
  (note them in the session marker if helpful).
- **Context for Next Task**: replace with the current view —
  this is forward-looking, not historical.
- **Git State**: replace with current output of
  `git diff --stat` and `git status --short`.
- **Sessions**: union — append the current session's line, never
  rewrite or drop prior lines.

### Session marker

When a merge happens, append a short marker to the `Key
Decisions` and/or `Test Evidence` sections to preserve
temporal order. Format:

```
— session 2026-04-24
```

Use `date +%Y-%m-%d` to get the date. One marker per
session-contribution, placed before the lines added by
that session. Keeps the log readable without introducing
a new top-level Session heading.

## Base summary structure (always):

### Task
One-sentence summary of what was worked on.

### Status
DONE | BLOCKED
If BLOCKED, explain why and what needs to happen
to unblock.

### Files Modified
Each file with a one-line description of what
changed and why. Format:
- `path/to/file.ts` (new|modified|deleted) — reason

### Files Read (Context Only)
Files that were read for understanding but NOT
modified. This helps the next session know what
context was used.

### Key Decisions
Technical decisions made during this session and
the reasoning behind them. Include alternatives
that were considered and rejected.

### Review Focus
Compact map for human review. Do not repeat the diff.
Each bullet must be filled with concrete content or the
literal word `None`.

- **Behavior claims:** 1-3 observable claims this implementation now
  satisfies. Empty or generic claims are review blind spots.
- **Plan deviations:** everything done differently from the approved
  task block — instructions not followed as written, acceptance
  criteria reinterpreted, key locations that turned out wrong or
  incomplete. One line each: what the plan said → what was done →
  why. Use `None` only if the block was followed as written; in the
  fix lane (no plan) write `No plan (fix lane)`.
- **Assumptions / choices:** concrete spec gaps or design decisions made
  during implementation. Use `None` only if the spec was unambiguous.
- **Scope notes:** intentional behavior or file changes outside the
  obvious task surface, or `None`. Silent omission is review-relevant
  scope drift.
- **Read next:** 1-3 exact files/symbols the reviewer should inspect
  first, with one line why. Listing only changed files is not a
  meaningful entry.

### Test Evidence
What was tested and how. Include:
- Test commands run and their output
- Manual verification steps taken
- Screenshots or log snippets if relevant
- Temporary probes: a probe answers a question once and must be
  removed before the task closes — record its command and result
  here instead. If it changed the code (a config workaround, a
  pinned version), the constraint belongs in a comment next to
  that code, not in this log. State explicitly that the probe is
  gone; a probe still in the tree is an unfinished task.

### Acceptance Coverage
One line per AC ID from the task's plan block.

Status values:
- `passed` — automated test exists and is green; reference the
  test file/test name or command output.
- `partial` — covered manually, or automated coverage stops short
  of the full AC; explain the gap.
- `skipped` — explicitly not addressed this session; explain why
  and reference a follow-up task if applicable.
- `N/A` — AC was dropped by an approved plan amendment; leave a
  one-line note and keep the ID visible.

If any AC is `skipped` and that was not a deliberate scope decision,
the task is not ready for `/commit N`. Finish the AC or split the
remaining work into a follow-up task before committing.

### Open Issues
Unfinished work, known issues, open questions.
Reference follow-up tasks where applicable.
Format: "Issue description (→ Task N)"

### Context for Next Task
What the next session needs to know to continue.
Include:
- Key interfaces and their signatures
- State assumptions
- Dependencies between this task and the next
- Any gotchas discovered during implementation

### Git State
Run these commands and include their output:
- `git diff --stat`
- `git status --short`

### Sessions
One line per agent session that contributed to this task, so the
raw transcripts stay findable from the log:

```
- <agent> <session-id> (<YYYY-MM-DD>) — transcript: <absolute path>
```

Determine the current session's line(s) with the `casefile` CLI
(works in home and casefile mode):

```
casefile session              # this Claude Code session (deterministic
                           # via $CLAUDE_CODE_SESSION_ID)
casefile session --agent all  # additionally the newest Codex session
                           # in this repo (cwd-matched heuristic)
```

Paste its output lines verbatim.

Record only the sessions you can determine; earlier sessions keep
their lines from prior merges.

## Additional sections for BLOCKED tasks only:

If Status is BLOCKED, also evaluate the escalation
triggers and produce a re-plan proposal. Append the
following sections to the summary:

### Escalation Assessment
For each trigger, state: CLEAR | WARNING | TRIGGERED
with evidence.

1. **Scope creep:** `git diff --stat` — are more files
   modified than the plan specified? Which ones are
   outside planned scope?
2. **API changes:** Has any public interface changed
   that was not planned? Check exports, function
   signatures, shared types.
3. **Failed attempts:** How many implementation
   attempts? Check git log for reverts or repeated
   changes to the same files.
4. **Test failures outside scope:** Are tests failing
   in modules not targeted by this task?
   Run the test suite and check.
5. **Explainability:** Can you summarize what this
   task accomplished in 5 bullet points or fewer?
   If not, scope is probably too large.

### Re-Plan Proposal
Based on the assessment, propose:
- What to keep from the current task (already valuable)
- How to split the remaining work into smaller tasks
- Updated task list with revised scope

Then propose an updated plan patch for `docs/work/<scope>/plan.md`.
Do NOT overwrite the old plan — the old version stays
in git history. Write the revision as an edit.

## After generating the summary:

Do **not** commit. The commit is `/commit N`'s job.

Tell the user:

> Summary is ready at `docs/work/<scope>/task-log/task-{N}-{slug}.md`.
> When you are done with this task's work, close it out with
> `/commit {N}` — that reads this log, stages code + summary
> together, and commits with a message derived from the log's
> title and status.
>
> You can run `/wrap-up {N}` again from another session
> before committing — findings are merged into this same
> file.

The single-commit rule still matters: the final committed
summary describes *this exact code state*. `/wrap-up` builds
the summary; `/commit` makes the atomic commit. Keeping them
split lets you extend the summary across sessions without
amend-dance, and the final commit still contains one coherent
story per task.

In casefile mode, adjust the closing message: the summary lives in
the casefile, `/commit N` commits code only and links it to the log
via a git note, and the casefile repo is committed by `/commit N` as
well.
