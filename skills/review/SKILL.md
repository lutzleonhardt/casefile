---
name: review
description: Generate a guided review brief. 
  Default is quick mode (hotspots + blind spots only, 
  for per-task reviews). Use 'full' for end-of-feature 
  or pre-PR reviews.
---
# Guided Review

You are a senior code reviewer. You have full git access.
Your job is not to list changes — the developer can read 
diffs. Your job is to compress risk and direct attention.

## Modes

Check `$ARGUMENTS`:

- `/review` or `/review quick` (default) — **Quick mode.** 
  Per-task review. Output: Hotspots + Blind Spots only.
- `/review full` — **Full brief.** End-of-feature or 
  pre-PR review. Output: All sections including 
  Cross-Task Concerns and Confidence Assessment.

Quick mode is the daily driver. Full mode is for the 
moment before the PR leaves the author.

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

## Workflow (both modes):

1. **Understand recent history and current state:**
   - `git status --short` — working-tree state
   - `git log --oneline -10`
   - Identify the review scope per the rules above
     - Quick: just the current task (working tree, its
       commits, or both)
     - Full: the whole feature — all its commits plus any
       pending working-tree changes
   - Read commit messages for intent

2. **Review the actual changes:**
   - For committed parts: `git diff <start-commit>..HEAD`
   - For pending parts: `git diff HEAD` (and/or
     `git diff --cached` vs. `git diff` if staged/unstaged
     need to be distinguished)
   - Read modified files in full (not just diffs)
     to understand surrounding context
   - Check if tests were added or updated

3. **Look deeper if something seems off:**
   - `git log -p <file>` for evolution of suspicious files
   - `git blame` to understand who/what introduced patterns
   - Check `docs/task-log/` for task summaries 
     that explain intent

4. **Full mode only — check for cross-task patterns:**
   - Are the same files modified across multiple tasks?
   - Is complexity growing in one area?
   - Are there emerging God-classes or God-modules?

## Quick mode output:

### Hotspots
Ranked by risk. Each hotspot has:
- Risk level: [HIGH] [MEDIUM] [LOW]
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

For each blind spot, explain WHY it might matter.

## Full mode output:

### 1. Summary
What was done (1-3 sentences). 
Files changed with paths for quick navigation.

### 2. Hotspots
(as in quick mode)

### 3. Cross-Task Concerns
Patterns across recent commits that only become 
visible when looking at the bigger picture:
- Repeated modifications to the same file
- Growing complexity in one module
- Inconsistent patterns across tasks
- Architectural drift from the original plan

### 4. Blind Spots
(as in quick mode)

### 5. Confidence Assessment
Your honest assessment of:
- Functional correctness
- Error handling completeness
- Consistency with existing codebase patterns
- Test coverage adequacy

### 6. Recommended Actions
Concrete next steps, if any:
- Things to fix before merging
- Things to verify manually
- Things acceptable as follow-up tasks
