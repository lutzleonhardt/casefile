---
name: commit
description: Commit a task's code and its wrap-up summary
  together in a single commit. Reads the task log to derive
  staging list and message, shows the plan to the user, then
  executes git add + git commit after confirmation.
---
# Task Commit

The task's wrap-up summary already exists (written by
`/wrap-up N`). Stage and commit the task's code changes
together with the summary file in a single commit.

This skill **executes** `git add` and `git commit` after
showing the user the full plan and waiting for explicit
confirmation. If the user says anything other than a clear
"yes" / "ok" / "commit", abort without running any git
command.

## Work scope

Resolve the active work root before locating the task log:

1. Run `git branch --show-current`.
2. If the branch name is empty (detached HEAD), stop and ask the user to
   switch to a branch before running git commands.
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

Use `$ARGUMENTS` to identify the task being committed
(e.g. `/commit 3` means Task 3). Required.

Resolution rules, in order:

1. If `$ARGUMENTS` contains a number, use that.
2. Else, if this session ran `/wrap-up N` or `/start-task N`
   and N is unambiguous in context, use N.
3. Else, **stop** and tell the user:
   > Task number required. Run as `/commit N`.
   Do not guess. Do not run git commands.

## Workflow

### 1. Locate the log file

```
ls docs/work/<scope>/task-log/task-{N}-*.md
```

- **Exactly one file** — continue.
- **No file** — stop. Tell the user:
  > No wrap-up summary found for Task N. Run `/wrap-up N`
  > first.
- **Multiple files** — stop. Filename convention violated inside this
  work scope; ask the user to consolidate before committing.

### 2. Read the log file

Extract:

- **Title** (from `### Task` — the one-sentence summary).
- **Status** (`DONE` or `BLOCKED`).
- **Files Modified** list — the canonical list of source
  files that should be staged.
- **Acceptance Coverage** — note covered, partial, skipped, or
  deferred AC IDs for the optional commit body.
- For BLOCKED: note the Re-Plan Proposal if present and
  identify the plan file path referenced.

### 3. Check current git state

```
git status --short
git diff --stat
```

Reconcile against the Files Modified list:

- Files listed in the log that are **missing** from the
  working tree / index → flag to user. Possible causes:
  file was reverted, already committed separately, or log
  is stale.
- Files present in the working tree that are **not** in
  the log → flag to user. Either the log is incomplete
  (re-run `/wrap-up N` to refresh) or these files belong
  to a different task.
- Files already staged that are **not** in the log → flag.
  The user might have staged something by hand; ask before
  sweeping it into the task commit.

Do not auto-resolve any of these — surface them and wait.

### 4. Build the staging list and commit message

**Staging list:**

- The log file: `docs/work/<scope>/task-log/task-{N}-{slug}.md`
- Every file in the log's `Files Modified` section that
  exists in the working tree or index.
- For BLOCKED with Re-Plan: also include
  `docs/work/<scope>/plan.md` (the updated plan).

**Commit message template:**

- **DONE:** `task-N: <title from log>`
- **BLOCKED with re-plan:** `replan: <reason> (task-N blocked)`
  The `<reason>` is a short human-readable phrase derived
  from the Re-Plan Proposal — ask the user if ambiguous.
- **BLOCKED without re-plan:** `task-N: blocked — <reason>`

Keep messages short (≤ 72 chars for the subject line). No
automatic body unless the user asks for one or the Acceptance
Coverage section contains anything other than `passed`.

When a body is warranted, keep it short and traceable:

```
Covers T{N}-AC-01..05
Partial T{N}-AC-06: <reason>
Defers T{N}-AC-07 -> Task M
```

Prefer `Covers` over `Closes`; AC IDs are not issue IDs.

### 5. Show the commit plan

Present a single block to the user containing:

- Commit message (subject line).
- Files to be staged, one per line, grouped as:
  - `[log]` — the task summary file
  - `[code]` — source files from Files Modified
  - `[plan]` — plan file (BLOCKED+replan only)
- Any discrepancies from step 3 (missing / extra / already-staged
  files) with a short note each.
- The exact commands that will run:
  ```
  git add <file1> <file2> ...
  git commit -m "<message>"
  # or: git commit -m "<message>" -m "<body>" when a body is used
  ```

End with a confirmation prompt, e.g.:

> Commit Task N as shown above? (yes / no / edit message)

### 6. Act on the response

- **`yes` / `ok` / `commit`** — run `git add <files>` then
  `git commit -m "<message>"` (plus `-m "<body>"` if the shown
  plan included a body). Show the resulting commit hash and a
  one-line confirmation.
- **`edit message`** — accept a revised message from the
  user and re-show the plan for confirmation. Do not
  commit until re-confirmed.
- **`no`** or anything ambiguous — abort. Do not stage,
  do not commit. Tell the user nothing was changed.

### 7. After a successful commit

Tell the user:

> Committed as `<hash>`. Task N is closed.
>
> Next: `/start-task N+1` to begin the next task, or
> `/review` for a quick per-task review, or
> `/review full` before opening a PR.

Do **not** push. Pushing is an explicit human action.

## What this skill does not do

- It does not run tests. Test evidence lives in the wrap-up.
- It does not amend or rewrite history. If the user needs
  to amend a prior commit, they do that by hand.
- It does not push to a remote.
- It does not sweep files with `git add -A` or `git add .`.
  Every path in the staging list is explicit and traceable
  to the log.
