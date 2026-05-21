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

If the task is NOT finished but the context is filling up,
use `/handoff` instead — this skill is for completed or
blocked tasks only.

## Work scope

Resolve the active work root before reading or writing task logs:

1. Run `git branch --show-current`.
2. If the branch name is empty (detached HEAD), stop and ask the user to
   switch to a branch before writing task logs.
3. Derive `<scope>` from the branch name:
   - `main` stays `main`; `master` stays `master`.
   - Otherwise take the part after the final slash, so
     `feature/f1234-user-import` becomes `f1234-user-import`.
   - Normalize to lowercase kebab-case: replace characters outside
     `a-z`, `0-9`, `.`, `_`, and `-` with `-`, collapse repeated `-`,
     and trim leading/trailing punctuation.
4. Use `docs/work/<scope>/` as the work root.

Do not infer scope from other `docs/work/*` directories. If
`docs/work/<scope>/plan.md` is missing, stop and tell the user to run
`/plan` on this branch or migrate the old plan/task logs into this scoped
work root. Legacy `docs/task-log/` is not an automatic fallback.

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
- **Open Issues**: merge; drop issues that are now resolved
  (note them in the session marker if helpful).
- **Context for Next Task**: replace with the current view —
  this is forward-looking, not historical.
- **Git State**: replace with current output of
  `git diff --stat` and `git status --short`.

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
to unblock. (For in-progress tasks, use `/handoff`.)

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

### Test Evidence
What was tested and how. Include:
- Test commands run and their output
- Manual verification steps taken
- Screenshots or log snippets if relevant

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
