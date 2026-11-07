---
name: commit-split
description: Land a task as a short series of atomic commits
  instead of one. Derives slices by intent in dependency order
  from the task log, labels each slice mechanical or behavioral,
  shows the plan, commits after confirmation, and verifies that
  every slice builds green on its own. Optional alternative to
  /commit, chosen by the user per task.
---
# Task Commit — split into a series

`/commit N` lands a task as one commit. This skill is the optional
alternative for a task whose change set reads better as a short
series of small commits: the reviewer and the history get one
responsibility per commit, each commit green on its own, while the
task keeps one plan block, one log and one acceptance set. The user
chooses per task. Nothing before this step changes — `/wrap-up` and
`/review` have already run on the working tree.

Small, untangled diffs are what make a review effective; the order
of the pieces matters less. The split therefore optimizes for small
commits with one intent each, then for reading order. The unit of a
slice is an intent, not a file: the refactoring that prepares a
change and the change itself usually touch the same files and land
as two slices.

This skill **executes** `git add`, `git commit` and a verifying
`git rebase -x` after showing the user the full plan and waiting for
explicit confirmation. If the user says anything other than a clear
"yes" / "ok" / "commit", abort without running any git command.

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
the current repository. `archive` is where `casefile archive` copies
session transcripts; it is never a target for plans, logs, or docs.

If `<work-root>/plan.md` is missing, stop and tell the user to run
`/plan` on this branch first.

## How the series stays one task

- **Home mode:** the log is committed with the **first** slice. Every
  later commit inherits it in its tree, and `casefile why` resolves
  those commits through the `task-N:` subject convention. After the
  series, `casefile archive {N}` runs once.
- **Casefile mode:** `[code]` files only, as in `/commit`; log and
  plan stay in the casefile. Every commit of the series gets its own
  note: `casefile link {N} {slug} <sha>` per commit, sessions copied
  by the first call only (`--no-session` on the others). Subjects
  carry no `task-N` prefix (the leak rule of `/commit` applies); the
  notes hold the series together.
- The log is not rewritten with the series' SHAs: the log sits in the
  first commit, so the later SHAs depend on it. The series is found
  by its subjects: `git log --oneline --grep='^task-N:'` in home mode,
  by its notes in casefile mode.

## Task identity — `$ARGUMENTS`

A task number is required (`/commit-split 6.1`); resolution follows
`/commit`. Fix-lane items (`fix-…`, `chore-…`, `docs-…`) are one
commit by definition — use `/commit` for them.

## Workflow

### 1. Locate and read the log

As `/commit` steps 1 and 2: exactly one `task-log/task-{N}-*.md`,
read Title, Status, Files Modified, Key Decisions, Acceptance
Coverage. A BLOCKED task is not split — `/commit N` handles its
templates.

### 2. Check git state

As `/commit` step 3, plus two conditions specific to a series:

- **Nothing is staged.** The series rebuilds the index from scratch;
  if something is staged, show it and ask before continuing.
- **The working tree is the whole task.** Files in the tree but not
  in the log, or in the log but not in the tree, are discrepancies
  for the user, exactly as in `/commit`.

### 3. Derive the slices

Sources, in this order: the log's Files Modified (the file inventory
with a reason per file), Key Decisions (which change came from which
decision — a change that emerged during review and reaches beyond
the task's key locations is the first slice candidate), a
dependency-ordered change map if the log has one, and the diff
itself (imports decide the order).

Rules:

- **One intent per slice.** A reviewer must be able to say in one
  sentence what the slice does.
- **Intent decides, not the file.** A file may span slices when its
  hunks carry different intents; the common shape is a mechanical
  slice (rename, extract, move) followed by the behavioral slice in
  the same files. Where intents already separate by file, keep files
  whole — the plan stays a plain file list — but never merge two
  intents to keep a file whole. Where two intents interleave line by
  line, the cut is not worth forcing: put the file whole into the
  later slice and say so in the plan.
- **Mechanical apart from behavioral.** Label every slice:
  *mechanical* (rename, move, extraction, format, pure refactoring,
  docs, dependency bumps) or *behavioral* (anything that changes what
  the system does). Never mix the two in one slice, not even inside
  one file — the mechanical part is for skimming, the behavioral part
  is where the reviewer's attention goes.
- **Dependency order.** A slice may use only what HEAD and earlier
  slices provide: infrastructure before consumers, wire contracts
  before their users, shared vocabulary before both.
- **Tests travel with the code they cover.** A shared test helper
  goes with the first slice that needs it; an existing test touched
  only to compile against a new signature goes with the slice that
  changed the signature.
- **Build inputs follow their consumer.** Lock files, manifests and
  tsconfigs go with the slice that needs them. A lock file that
  serves two slices is split by hunk per consumer, so that every
  slice still installs with a frozen lock file.
- **The log goes into slice 1** (home mode).
- **Two to six slices.** One slice means the task is a `/commit`.
  More than six means the task was too big for its plan block: say
  so, propose a six-way cut, and note the sizing in the log's Open
  Issues — do not split hairs to get there.
- **Each slice builds and tests green on its own.** Verified in
  step 6, never assumed.

### 4. Compose the messages

- **Subject** (home mode): `task-N: <what this slice does>`, at most
  72 characters, worded so the mechanical/behavioral nature shows
  ("extract …", "rename …" versus "add …", "handle …"). Casefile
  mode: a plain conventional subject without the task prefix.
- **Body:** two to five lines, what and why, taken from the log (the
  Files Modified reasons, the decision behind it). The body is what
  a reader has who sees only this commit.
- **Acceptance coverage:** as in `/commit` — a `Covers …` body only
  when the log's Acceptance Coverage holds anything other than
  `passed`, and only on the last slice. Never in casefile mode.

### 5. Show the plan

The user approves a cut, not a wall of text. Keep the plan short and
write it in the conversation's language; only the commit subjects and
bodies are in the repository's language, because they go into git.
Compose the full messages and file lists now, but show them on
request.

Present a single block:

- One header line: base commit (`git rev-parse --short HEAD`), number
  of slices, verification command.
- **Overview, one line per slice:** number, label
  (mechanical | behavioral), a gist of at most ten words in the
  conversation's language, file count and line delta. This is what
  the user reads.
- **Subjects:** the commit subjects, verbatim, one per line.
- **Decisions needed:** discrepancies from step 2 and owed items from
  the log, one line each, only where the user has to decide.
  Observations without a decision stay out of the plan.
- The commands in one short block, linking included
  (`casefile archive {N}` in home mode, one `casefile link …` per
  slice in casefile mode).

End with a confirmation prompt:

> Commit Task N as this series of k commits? (yes / no / edit / details k)

`details k` shows one slice in full: body, files with
`(new|modified|deleted)` and line counts, and for a file that spans
slices the symbols or hunks that belong here. `edit` accepts a
revised cut or wording and re-shows the plan. Do not run anything
until the user has confirmed.

### 6. Execute on "yes"

```sh
base=$(git rev-parse HEAD)
git reset -q                      # index only; the working tree is untouched
# per slice, in order:
git add -- <files that belong to slice k as a whole>
git apply --cached --recount "$TMPDIR/slice-k-<file>.patch"   # per file that spans slices
git commit -m "<subject>" -m "<body>"
# then verify every slice on its own:
git rebase -x '<verify>' "$base"
```

A file that spans slices is staged hunk by hunk, without any
interactive prompt: copy this slice's hunks verbatim from
`git diff -- <file>` into a patch file under `$TMPDIR` (the diff
header plus the chosen `@@` hunks; `--recount` tolerates the stale
hunk counts) and apply it to the index. The rest of the file falls
into the next slice by itself: after the commit, `git diff -- <file>`
shows only the remaining hunks, and the last slice takes the file
whole.

`<verify>` is the project's build-and-test entry (typecheck plus
tests, e.g. `pnpm -r typecheck && pnpm -r test`), taken from the
log's Test Evidence or the repository's conventions. If no single
command is unambiguous, ask before step 5.

If the rebase stops at slice k, the cut was wrong, not the code:
`git rebase --abort`, then `git reset -q --mixed "$base"` returns the
working tree to its unstaged state. Fold slice k into slice k+1
(merge the file lists, extend subject and body), show the revised
plan and ask again. One retry; if it fails again, stop, leave the
tree unstaged and report — `/commit N` remains available.

Then link: `casefile archive {N}` in home mode; in casefile mode
`casefile link {N} {slug} <sha>` for each commit of the series, the
first with sessions, the rest with `--no-session`. Report each
result in one line.

### 7. After a successful series

Show `git log --oneline <base>..HEAD` and tell the user:

> Committed Task N as k commits (`<first>`..`<last>`). Task N is closed.
>
> Next: `/start-task N+1` to begin the next task, or
> `/review <base>..HEAD` for a review brief over the series.

Do **not** push. Pushing is an explicit human action.

## After the split — assigning later changes

Review fixes made after the split are ordinary working-tree edits.
When the user asks to assign them to the right commit, first decide
between two moves:

- **Fixup** when the change corrects a slice without changing what
  the slice is: same intent, same subject still true. Cheap, one
  rebase, conflict-free when intents are separated by file.
- **Re-cut** when the series itself changes: a slice would need a
  new subject, a new slice belongs between existing ones, or a file
  moves from one slice to another. Rewording, reordering and
  re-staging by hand cost more than the cut did, and each step runs
  through editor hooks. Nothing is pushed, the working tree holds
  the final state, and the skill derives the cut from the log — so
  update the log first (`/wrap-up N`), then
  `git reset -q --mixed <base>` and run `/commit-split N` again.
  Cost: one plan confirmation and one verification pass, the same as
  the first run. In casefile mode the new commits are linked again.

For a fixup, fold each change into the slice that owns the lines it
touches — never edit on a detached commit, never ask the user to
rebase by hand:

1. **Owner lookup** per change: the slice that last touched those
   lines, `git blame -L <start>,<end> -- <file>` or
   `git log --format=%s <base>..HEAD -L <start>,<end>:<file>`. With
   intents separated this names one subject; for lines the series
   did not touch, or a new file, the owner is the slice the change
   belongs to by intent — say which. A log change goes to slice 1.
   A change the series never claimed (new behavior, not a
   correction) is appended as a new slice instead of folded.
   `git absorb` automates this lookup when it is installed.
2. **One fixup per target slice**, addressed by subject, not SHA:
   `git commit --fixup=':/<subject>' -- <files>` (a new file needs
   `git add -- <file>` first, so the pathspec knows it). A file whose
   fixes belong to two slices is staged hunk by hunk, as in step 6.
3. **Fold and re-verify:**
   `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>` then
   `git rebase -x '<verify>' <base>`. A fixup can conflict with a
   later slice that touched neighbouring lines; resolve it from the
   known final state of the file and `git rebase --continue`.
4. Show `git log --oneline <base>..HEAD`.

Only before anything is pushed: published history is appended to,
never rewritten. In casefile mode the notes follow the rewrite
(`notes.rewriteRef` is set by `casefile enable`); run
`casefile backup` afterwards and confirm with `casefile doctor`.

## What this skill does not do

- It does not derive a cut without the task log, and it does not
  force a hunk-level cut where two intents interleave line by line.
- It does not run tests beyond the verification command; test
  evidence lives in the wrap-up.
- It does not write SHAs into the log, push, or rewrite published
  history.
- It does not sweep files with `git add -A` or `git add .`. Every
  path in a slice is explicit and traceable to the log.
