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

## Casefile mode differences

In casefile mode the work artifacts never enter the current
repository. This changes the commit mechanics:

- **Staging list:** `[code]` files only. The `[log]` file (and
  `[plan]` for BLOCKED+replan) live in the **casefile repo** instead,
  not staged here.
- **Link:** after the code commit, one command attaches the git
  note (`tasklog:` pointer), commits the casefile repo, and pushes the
  notes backup into the casefile:
  ```
  casefile link {N} {slug} [{sha}] -m "task-N: <title> ({project})"
  ```
  By default this also copies the transcripts listed in the log's
  `### Sessions` section into the casefile (safety net against
  transcript expiry and machine loss). Pass `--no-session` only
  when the user explicitly wants the raw transcripts excluded.
- **Code already committed** (e.g. wrap-up ran after the commit):
  skip `git add`/`git commit`, ask the user to confirm the target
  commit hash, then run `casefile link {N} {slug} <hash>` against it.
- **Never** push notes refs or anything else to the repository's
  origin. `casefile link`'s backup push targets the private casefile only.

The `casefile link` command appears in the commit plan (step 5) and
runs only after the user confirms.

## Home mode: session archive

In home mode the log and code are committed to the repository
itself — but the session transcripts under `~/.claude/projects/`
(and `~/.codex/sessions/`) are ephemeral: nothing preserves them.
`/commit` therefore archives them into the casefile repo, which acts
as the personal session archive even for home-mode projects. After
the code commit, run:

```
casefile archive {N}
```

It copies the transcripts listed in the log's `### Sessions`
section **plus the current session** (a resume's ID may not be
in the log yet — the commit phase always runs after the last
wrap-up) into `<casefile>/<project>/work/<scope>/sessions/task-{N}/`
and commits the casefile repo. If it fails with "no casefile repo",
report that one line and continue — the archive is a safety net,
never a commit blocker. Missing source files (expired transcripts)
are reported per line, not fatal. Skip the step only when the user
explicitly asks for the transcripts to be excluded.

The command appears in the commit plan (step 5, `[sessions]`
group) and runs only after the user confirms, once the code commit
has succeeded.

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

**Fix lane:** `$ARGUMENTS` may also name an unplanned work item
(see `/wrap-up`'s fix lane). A full stem (`fix-<slug>`,
`chore-<slug>`, …) is used as-is. A bare type (`fix`) resolves
via (a) this session's `/wrap-up fix` identity, else (b) exactly
one uncommitted `<type>-*.md` log in the scope's `task-log/` —
if several match, list them and stop. Everywhere this skill says
`task-{N}-{slug}.md`, a fix item reads `{stem}.md`; everywhere it
says `{N}` (including `casefile link` and `casefile archive`), pass the
stem — `casefile link fix-<slug> [sha]` takes no separate slug
argument.

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

Casefile mode: stage `[code]` files only — the log and plan are
committed to the casefile repo instead (see Casefile mode differences).

**Commit message template (home mode):**

- **DONE:** `task-N: <title from log>`
- **BLOCKED with re-plan:** `replan: <reason> (task-N blocked)`
  The `<reason>` is a short human-readable phrase derived
  from the Re-Plan Proposal — ask the user if ambiguous.
- **BLOCKED without re-plan:** `task-N: blocked — <reason>`
- **Fix lane:** `<type>: <title from log>` (e.g. `fix: …`,
  `chore: …`) — the stem's type is the conventional-commit type.

**Commit message template (casefile mode):** the code repo does not
carry the plan or task logs, so workflow vocabulary (`task-N`,
`replan`, `blocked`) must not leak into its history — to colleagues
it references a numbering that does not exist. Use a plain,
conventional message instead:

- **DONE:** `<title from log>` (no task-N prefix)
- **BLOCKED:** a neutral WIP-style message derived from the title —
  ask the user if unsure what is appropriate in this repo.

The task number stays fully traceable: it lives in the git note
(`tasklog: .../task-{N}-{slug}.md`) and in the casefile repo's own
commit message, which keeps the `task-N:` prefix.

The same leak rule covers the diff itself: in casefile mode, AC IDs
(`T{N}-AC-{NN}`, `XC-NN`) and task numbers must not appear in
source comments, test names, or fixtures of the code repo. Before
building the commit plan, `git grep -nE 'T[0-9.]+-AC-[0-9]+|XC-[0-9]+'`
over the `[code]` files; any hit is a discrepancy in step 5 for the
user to decide on. Home mode is exempt — there the plan sits next
to the code.

Keep messages short (≤ 72 chars for the subject line). No
automatic body unless the user asks for one or the Acceptance
Coverage section contains anything other than `passed`.

When a body is warranted, keep it short and traceable:

```
Covers T{N}-AC-01..05
Partial T{N}-AC-06: <reason>
Defers T{N}-AC-07 -> Task M
```

Prefer `Covers` over `Closes`; AC IDs are not issue IDs. In casefile
mode the code-repo commit gets no such body at all — the Acceptance
Coverage is readable in the linked task log.

### 5. Show the commit plan

Present a single block to the user containing:

- Commit message (subject line).
- Files to be staged, one per line, grouped as:
  - `[log]` — the task summary file (home mode only)
  - `[code]` — source files from Files Modified
  - `[plan]` — plan file (BLOCKED+replan only, home mode only)
  - `[casefile]` — casefile mode: the exact `casefile link …` command
  - `[sessions]` — home mode: the exact `casefile archive …` command
    (see Home mode: session archive)
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
  one-line confirmation. In casefile mode, then run the `[casefile]`
  command from the plan against the new hash and confirm with
  one line. In home mode, then run the `[sessions]` command from
  the plan and confirm the copy count and casefile commit with one
  line.
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
- It does not push to a remote. (Sole exception: `casefile link`'s
  notes backup push, which targets the local casefile path and never
  the repository's origin.)
- It does not sweep files with `git add -A` or `git add .`.
  Every path in the staging list is explicit and traceable
  to the log.
