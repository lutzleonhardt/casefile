---
name: review
description: Generate a guided review brief.
  Default is quick mode (hotspots + blind spots for per-task
  triage). Use 'full' for end-of-feature or pre-PR reviews. Use
  'coverage' or 'big' for large diffs that need a complete review map.
---
# Guided Review

You are a senior code reviewer. You have full git access.
Your job is not to list changes — the developer can read 
diffs. Your job is to compress risk and direct attention.

## Modes

Check `$ARGUMENTS`:

- `/review` or `/review quick` (default) — **Quick mode.** 
  Per-task triage. Output: Hotspots + Blind Spots only.
- `/review full` — **Full brief.** End-of-feature or 
  pre-PR review. Output: All sections including 
  Cross-Task Concerns and Confidence Assessment.
- `/review coverage` or `/review big` — **Coverage mode.**
  Large-diff review. Output: a complete, ordered partition of the
  diff with attention tiers, inline risk flags, and a coverage ledger.

Quick mode is the daily driver. Full mode is for the 
moment before the PR leaves the author. Coverage mode is for large
diffs where the reviewer wants confidence that no changed file or
moved responsibility slipped through.

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

## Review scope — commit range vs. working tree

Before running the workflow, decide **what** is being reviewed.
`/review` has to cover both committed history and work in the
working tree, because `/wrap-up` produces summary + code
*uncommitted by design* — the most common review moment is exactly
*before* that commit goes out.

Check git state first:

- `git status --short` — any uncommitted or staged changes?
- `git log --oneline -10` — recent commit history.

Pick the scope:

- **Working-tree only** (nothing committed yet for the current
  task): review `git diff HEAD` — this covers staged + unstaged
  changes together. Split with `git diff` (unstaged) and
  `git diff --cached` (staged) if that distinction matters.
- **Committed only** (no working-tree changes): review
  `git diff <start-commit>..HEAD`.
- **Mixed** (some commits already landed for the task, more
  changes still in the working tree): review both —
  `git diff <start-commit>..HEAD` for the committed part and
  `git diff HEAD` for what is still pending. Call out the split
  in the output so the user can see which findings belong to
  which slice.

If the user passed an explicit range in `$ARGUMENTS` (e.g.
`/review HEAD~3..HEAD`), honour it verbatim and skip scope
detection.

## Workflow (all modes):

1. **Understand recent history and current state:**
   - `git status --short` — working-tree state
   - `git log --oneline -10`
   - Identify the review scope per the rules above
     - Quick: just the current task (working tree, its
       commits, or both)
     - Full: the whole feature — all its commits plus any
       pending working-tree changes
     - Coverage: the requested large diff, defaulting to the current
       task/worktree if no explicit range is given
   - Read commit messages for intent
   - Estimate diff size for the selected scope with `git diff --shortstat`
     and changed-file inventory commands. For mixed scope, use the union
     of committed and pending changed paths for file count; line totals
     may be an approximate sum of both slices.
   - In quick or full mode, if the diff is large (rough heuristic:
     more than 15 changed files or more than 800 insertions+deletions),
     begin the output with a one-line `Size note:` recommending
     `/review coverage` for complete coverage. Do not switch modes
     automatically.

2. **Review the actual changes:**
   - For committed parts: `git diff <start-commit>..HEAD`
   - For pending parts: `git diff HEAD` (and/or
     `git diff --cached` vs. `git diff` if staged/unstaged
     need to be distinguished)
   - Read modified files in full (not just diffs)
     to understand surrounding context
   - Check if tests were added or updated
   - Check the relevant `docs/work/<scope>/task-log/` entry for
     Acceptance Coverage, Review Focus, and AC IDs when reviewing a
     task with a wrap-up log. In casefile mode, AC IDs
     (`T{N}-AC-{NN}`, `XC-NN`) or task numbers inside the
     diff — comments, test names, fixtures — are a Hotspot: the plan
     is invisible from the code repo. In home mode they are fine.
   - Treat `Review Focus` as claims to verify against the code and
     diff, not as truth. False or incomplete claims become Hotspots.
     Missing, generic, or non-actionable entries become Blind Spots.
   - Cross-check `Plan deviations` in both directions. Extract just
     the task's `## Task N` block from `docs/work/<scope>/plan.md`
     (not the sibling tasks) and (a) verify each declared deviation
     against it, (b) scan the diff for departures from the block —
     touched files outside Key Locations, reinterpreted or silently
     dropped ACs — that are NOT declared. An undeclared deviation is
     a Hotspot and ranks above a declared one; a missing or generic
     `Plan deviations` entry is a Blind Spot.
   - Fix-lane logs (`fix-*.md`, `chore-*.md`, … — see `/wrap-up`'s
     fix lane) carry no Acceptance Coverage or AC IDs by design;
     their absence is not a Blind Spot there. Verify the
     **Root Cause** section instead: does the diff actually address
     the stated cause rather than the symptom, and does a
     regression test pin it? A missing, vague, or unconvincing
     Root Cause is a Blind Spot. Fix-lane scopes (e.g. `work/main/`)
     may have no `plan.md` — skip plan-based checks there.

3. **Look deeper if something seems off:**
   - `git log -p <file>` for evolution of suspicious files
   - `git blame` to understand who/what introduced patterns
   - Check `docs/work/<scope>/task-log/` for task summaries that
     explain intent.

4. **Full mode only — check for cross-task patterns:**
   - Are the same files modified across multiple tasks?
   - Is complexity growing in one area?
   - Are there emerging God-classes or God-modules?
   - Read the active plan at `docs/work/<scope>/plan.md`. If it has a
     `Cross-Cutting Acceptance` section, check each `XC-NN` against
     task logs and tests.

   Cross-cutting check statuses:
   - `passed` — at least one test or task log asserts the full
     invariant.
   - `unverified` — relevant modules were not touched, or no
     evidence exists yet.
   - `gap` — contributing tasks were touched but no evidence
     covers the invariant.

5. **Coverage mode only — build a complete review map:**
   - Use `git diff --name-status` and `git diff --stat` for the
     selected scope to build the changed-file inventory.
   - For mixed scope, build the coverage inventory as the union of the
     committed and pending changed paths. If a file appears in both
     slices, assign it once and mention the split only when it matters.
   - Partition every changed file into exactly one logical category.
     Coverage mode is allowed to be exhaustive; do not hide boring
     files just because they are low-risk.
   - Add attention tiers instead of omitting files:
     - `deep` — must be read carefully; core behavior or risky moves.
     - `read` — should be read normally; meaningful implementation.
     - `skim` — inspect enough to confirm expected mechanical,
       generated, config, docs, or lockfile changes.
   - Order categories by dependency and understanding flow, not by
     filename. Contracts/state should usually precede consumers.
   - Deleted files count in the coverage ledger like any other changed
     file. They usually belong in the Responsibility Reconciliation
     station or a dedicated removal station, then get behavior-mapped in
     the Responsibility Reconciliation section.
   - If files were deleted, renamed, split, or replaced by many new
     files, include a **Responsibility Reconciliation** station that
     maps old responsibilities to their new homes. This is mandatory
     for monolith-to-components or shell-to-modules diffs.
   - Reconcile the category inventory against the diffstat. Report
     assigned file count vs. changed file count, and call out any
     unassigned or multiply assigned files as a coverage failure.

## Quick mode output:

If the large-diff heuristic triggered, start with the one-line
`Size note:` before the sections below.

### Hotspots
Ranked by risk. Each hotspot has:
- Risk level: [HIGH] [MEDIUM] [LOW]
- AC ID it touches (`T{N}-AC-{NN}` or `XC-NN`), or `no AC` if
  the finding is outside the stated acceptance surface
- File and line reference
- What the concern is
- What to check or consider

### Blind Spots
Areas that are likely relevant but were NOT 
inspected or modified. Be specific:
- Related test files not updated
- Documentation not adjusted
- Config files that might need changes
- Adjacent modules that depend on changed code
- Error handling paths not covered
- Missing, generic, or non-actionable `Review Focus` entries in the
  task log

For each blind spot, explain WHY it might matter.

## Full mode output:

If the large-diff heuristic triggered, start with the one-line
`Size note:` before the sections below.

### 1. Summary
What was done (1-3 sentences). 
Files changed with paths for quick navigation.

### 2. Hotspots
(as in quick mode)

### 3. Cross-Cutting Acceptance Check
If the active plan has a `Cross-Cutting Acceptance` section,
report each `XC-NN`:

- Evidence from task logs and tests.
- `passed` if the full invariant is asserted.
- `unverified` if the contributing modules were not touched or no
  final integration task has run yet.
- `gap` if contributing tasks were touched but no evidence covers
  the invariant.

A `gap` is a strong signal that an integration test or follow-up
task is missing.

### 4. Cross-Task Concerns
Patterns across recent commits that only become 
visible when looking at the bigger picture:
- Repeated modifications to the same file
- Growing complexity in one module
- Inconsistent patterns across tasks
- Architectural drift from the original plan

### 5. Blind Spots
(as in quick mode)

### 6. Confidence Assessment
Your honest assessment of:
- Functional correctness
- Error handling completeness
- Consistency with existing codebase patterns
- Test coverage adequacy

### 7. Recommended Actions
Concrete next steps, if any:
- Things to fix before merging
- Things to verify manually
- Things acceptable as follow-up tasks

## Coverage mode output:

### 1. Change Shape
Explain the diff shape in 3-6 bullets. Focus on what kind of review this
is (for example monolith split, contract change, config churn,
generated update), not on listing every changed file.

### 2. Coverage Ledger
Report:
- Review scope
- Changed files from diff inventory (union of committed and pending
  paths for mixed scope)
- Files assigned to exactly one category
- Unassigned files, if any
- Multiply assigned files, if any
- Deleted files counted in assigned total
- Result: `complete` only if assigned count equals changed count and
  there are no duplicates

### 3. Coverage Path
Provide a table with one row per review station:
- `#`
- Station
- Tier: `deep`, `read`, or `skim`
- Files
- Why this station is ordered here
- What to check
- Risk flags such as `[HIGH] T3-AC-05`, if any

Every changed file must appear in exactly one station. Generated,
lockfile, config, docs, and deleted files still belong in the table;
deleted files usually appear in the Responsibility Reconciliation
station or a dedicated removal station. Use attention tiers to keep the
review fast.

### 4. Responsibility Reconciliation
Required when the diff deletes, renames, splits, or replaces files.
Map old responsibilities to their new locations. For each old
responsibility, state whether it is preserved, intentionally removed,
or questionable. Include file references.

If no such restructuring exists, say `Not needed`.

### 5. Hotspot Details
For each risk flag in the Coverage Path, provide the same details as
quick-mode Hotspots: severity, AC ID or `no AC`, file/line reference,
concern, and what to check.

### 6. Blind Spots / Residual Risk
List only risks that remain after the coverage pass, such as files that
could not be inspected deeply, missing tests, generated artifacts that
were only skimmed, unavailable runtime checks, or unclear task-log
claims.

### 7. Recommended Actions
Concrete next steps before merge or commit. Separate must-fix items from
acceptable follow-ups.
