---
name: plan
description: Break a spec into a right-sized, testable task plan.
  Produces a proposal; writes to the branch-scoped docs/work/ plan only
  after user approval.
  Each task is sized so that its diff + test could land as a single commit.
---
# Plan a Spec

The user has a specification (in `docs/specs/`, a chat message, or
a linked issue) and wants to turn it into an ordered task list that
`/start-task` can consume.

Use `$ARGUMENTS` to locate the spec (e.g. `/plan docs/specs/auth-rewrite.md`).
If no argument is given, ask which spec to plan.

## Work scope

Task plans and logs are scoped by the current git branch so parallel
worktrees can use simple task numbers without colliding.

Create or switch to the feature branch before running `/plan`. The
branch is the unit of work: one branch has one active work plan at
`docs/work/<scope>/plan.md`.

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

If a branch is renamed, rename the matching `<work-root>` directory
or keep using the old branch name. Legacy layouts (`docs/plans/`, a
root `plan.md`, `docs/task-log/`) are never automatic fallbacks —
migrate them into the scoped work root first.

## Workflow

1. **Read the spec in full.** Do not plan from a summary — read the
   whole document so acceptance criteria and edge cases are visible.

2. **Check repo state:**
   - `git log --oneline -10`
   - `ls docs/work/<scope>/task-log/ 2>/dev/null` — is there related
     recent work in this branch scope?
   - `test -f docs/work/<scope>/plan.md && echo exists` — does a plan
     already exist for this branch scope?

3. **Pick the starting task number.** Task numbers are local to
   `docs/work/<scope>/`. In a fresh scope, start at 1. If the scoped
   plan or task log already exists, continue after the highest local
   task number:

   ```
   ls docs/work/<scope>/task-log/task-*.md 2>/dev/null
   grep -h '^## Task ' docs/work/<scope>/plan.md 2>/dev/null
   ```

   Take the highest `N` that appears in either output (a logged
   task or a not-yet-wrapped-up task in the scoped plan) and start
   at `N + 1`.

   Why branch-scoped: the whole skill chain (`/start-task`,
   `/wrap-up`, `/commit`) can keep the fast daily shape
   (`/start-task N`) while avoiding collisions between parallel
   worktrees. `task-N-{slug}.md` only has to be unique inside
   `docs/work/<scope>/task-log/`.

4. **Draft a task breakdown** following the rules below.

5. **Resolve every Key Location against the code** before showing
   the plan. Key Locations are hypotheses until checked — unresolved
   guesses are the main source of oversized tasks. For each task:
   - Verify each named file exists (glob) and each named
     class/function/symbol is found where claimed (bounded `rg`).
     Do not read implementations — this is existence checking,
     not code study.
   - A location that does not resolve is a planning bug: find the
     real one or rewrite the task.
   - If resolving reveals that the task actually touches more than
     ~10 files, or one location fans out into a whole subsystem,
     re-slice the task before presenting.
   The presented plan contains only resolved locations.

6. **Present the breakdown to the user** — before writing any file.

7. **Wait for user approval.** Only then write to
   `docs/work/<scope>/plan.md`. If a scoped plan file already exists,
   propose an edit rather than overwriting — the user decides.

## Task-sizing rules (apply to EACH task)

- **One coherent goal.** No multi-goal items joined by "and" or
  "then". If those words appear in the title, it's two tasks.
- **Independently reviewable.** The task's diff + its test could
  land as a single commit with no cross-task coordination.
- **Self-contained vs. the spec.** The task must be interpretable
  and executable without re-reading the spec. `/start-task` does
  not load `docs/specs/`. Inline every spec-derived fact the
  executing agent needs — constraints, acceptance criteria, domain
  rules, invariants — into `Instructions`, `Acceptance`, or
  `Key Discoveries`. A task that says "implement section 3.2 of
  the spec" is broken by definition.
- **Acceptance built in and traceable.** Each task carries its
  own verification — prefer automated evidence, but a permanent
  test is only one form of it: a command plus its recorded result
  in the task log counts fully.
  Each acceptance criterion gets a stable ID:
  `T{N}-AC-{NN}` where `{N}` is the task number exactly as written
  in the plan (`T3`, `T3.5`, `T17`, ...) and `{NN}` is a zero-padded
  counter starting at `01`. Use those IDs in `/start-task`,
  `/wrap-up`, `/commit`, and `/review`. Whether they may also
  appear in the code itself depends on the work mode: in home mode
  the plan is committed next to the code, so tagging a test or a
  source comment with its AC ID is allowed and useful; in casefile
  mode the plan is invisible from the repository, so AC IDs
  (`T{N}-AC-{NN}`, `XC-NN`) and task numbers stay out of every file
  of the repository — the AC → test mapping lives in the task log's
  Acceptance Coverage instead.
  - During draft planning, renumber freely until the user approves.
  - After the plan is accepted/committed, AC IDs are append-only:
    if an AC is dropped or reordered, leave a gap and do not
    renumber existing IDs.
  - A criterion is ID-worthy only if someone could later say
    "cover T3-AC-04" and know what behavior is meant. Generic
    bullets like "tests pass" are not acceptance criteria.
  If automation is a bad fit, acceptance may be omitted rather
  than prescribing manual steps. For pure mechanical refactors
  with no behavior change, acceptance is optional (existing tests
  staying green is implicit).
- **No standalone "testing", "verification", or "stabilization"
  tasks.** Tests belong to the task that introduces the behavior.
  A separate test-task is a size smell — the behavior-task was
  too large, or the test-task lacks a reviewable outcome of its own.
- **At most one explicit dependency** on a previous task. Deep
  dependency chains mean the slicing is wrong.
- **Size target (orientation, not rule):** completable in one
  sitting, rarely more than a few hours and ~10 files. Legacy-heavy
  touchpoints may exceed this — flag it when they do.

## Slicing rubric

- **TOO LARGE** if it spans multiple subsystems, sweeping refactors,
  or has ambiguous outcomes — split by subsystem or by
  "behavior change" vs "refactor".
- **TOO SMALL** if it lacks a distinct, reviewable outcome or test —
  merge into its parent goal.
- **JUST RIGHT** if the diff + test could be reviewed and landed
  as a single commit. Related changes within one subsystem
  (including tests) stay in the same task.

Aim for a handful of tasks. If the count climbs past ~8, the
slicing is probably too fine or the spec is too ambitious for one
plan — propose splitting the spec instead.

## Task entry schema

For each task, produce:

- **Title** — short, imperative, unambiguous.
- **Instructions** — what to do (Markdown encouraged). Must be
  self-contained: no references like "see spec" or "as in Task 2".
  The executing agent will read only this block plus the plan
  preamble.
- **Acceptance** — how to verify success. Each acceptance
  criterion gets a stable ID `T{N}-AC-{NN}`:
  - `N` is the task number exactly as written in the heading,
    including point tasks such as `3.5`.
  - `NN` is a zero-padded counter starting at `01`.
  - IDs are stable after plan approval. Leave gaps instead of
    renumbering if an AC is removed later.
  - Prefer behavior phrasing: Given/When/Then or a compact
    observable assertion.
  - State the outcome, never the mechanism. An AC that names a
    file, a spec, or a concrete assertion is a planning bug: it
    prescribes the implementation instead of what must be true.
  - If this task contributes to a cross-cutting acceptance item,
    mention the `XC-NN` ID here; `/start-task` will not load the
    plan-end cross-cutting section by default.
  Optional only for pure mechanical refactors.
- **Key Locations** — files, fully qualified classes/methods
  to be touched. Resolved against the code (workflow step 5),
  never unchecked guesses.
- **Key Discoveries** — facts from the spec or outside the key
  locations that the executing agent needs at start (domain rules,
  invariants, acceptance nuances). Required whenever the spec
  contains such facts; omit only for trivial refactors where spec
  and task scope are effectively identical.

## Plan file layout

The plan file uses a stable heading convention so `/start-task N`
can extract exactly one task block without loading siblings:

- **Preamble** — everything before the first task heading: plan
  title, spec reference, scope note, and the Flexibility Clause.
  Keep it compact (≤ 30 lines). This is the only cross-cutting
  context `/start-task` will load alongside the requested task.
  Include an explicit source line near the top, for example
  `Spec: docs/specs/auth-rewrite.md` or `Spec: <issue/chat source>`.
- **Task heading** — `## Task N` or `## Task N: <title>` on its
  own line. Numbering is sequential inside `docs/work/<scope>/`.
  A different branch scope may also have `Task 1`; that is correct.
  The directory is the uniqueness boundary.
- **Task block** — from `## Task N` up to (but excluding) the
  next `## Task M` heading or EOF. `/start-task N` extracts
  exactly this block.

Do not nest tasks under deeper headings (`### Task N`) and do
not split a task across multiple `## Task N` occurrences — the
extraction pattern anchors on `^## Task <number>`.

## Cross-Cutting Acceptance

If the plan has more than ~3 tasks or contains invariants that
span task boundaries, add a short plan-end section:

```
## Cross-Cutting Acceptance

- **XC-01** — <observable behavior no single task can prove alone>.
  **Touches:** T1, T2, T3.
```

Rules:

- Use IDs `XC-{NN}`. They are stable after plan approval and
  append-only like task AC IDs.
- Keep this section at the end of the plan, after the final task
  block. `/start-task N` must not load it unless the requested
  task block explicitly references an `XC-NN`.
- Keep it short. If it grows past ~10 items, the per-task ACs are
  probably under-specifying local invariants.
- An `XC` item belongs here only if it cannot be fully proven by
  one task on its own. Otherwise put it in the relevant task's
  Acceptance section.
- Each item must include a `Touches:` line listing contributing
  task IDs.

Good examples:

- **XC-01** — The history log records exactly one durable entry per
  successful mutating tool call and no entries for failed atomic
  edits. **Touches:** T1, T2, T3.
- **XC-02** — The prompt date, tool-scope date, and repository
  search date use the same captured value within a turn.
  **Touches:** T3, T3.5, T5.5.

## Flexibility clause (include verbatim in the plan)

> The executing agent may adjust scope and ordering based on more
> up-to-date context discovered during implementation, as long as
> each task still satisfies the sizing rules above.
>
> When a task is finished (DONE or BLOCKED), close it with the
> `/wrap-up N` → `/commit N` pair. `/wrap-up N` writes or extends
> `docs/work/<scope>/task-log/task-{N}-{slug}.md`, where `<scope>`
> is derived from the current git branch, and is safe to run multiple
> times across sessions — it merges. `/commit N` reads that log,
> stages code + summary, and commits them together after showing
> the plan and waiting for confirmation. Optionally run `/review`
> (quick per-task, full before a PR, coverage for large diffs)
> between wrap-up and commit;
> a second `/wrap-up N` can absorb the review findings.

This keeps the plan a guide, not a straitjacket — and gives every
`/start-task` run the closing checklist in its loaded context.

## After user approval

1. Write the plan to `docs/work/<scope>/plan.md`. Create
   `docs/work/<scope>/` if it does not exist.
2. Do NOT commit automatically. Tell the user:
   > Plan is ready at `docs/work/<scope>/plan.md`.
   > Recommended commit:
   > ```bash
   > git add docs/work/<scope>/plan.md
   > git commit -m "plan: <spec title>"
   > ```
   In casefile mode, recommend committing in the casefile repo instead
   (never in the current repository):
   > ```bash
   > git -C <casefile-root> add <project>/work/<scope>/plan.md
   > git -C <casefile-root> commit -m "plan: <spec title> (<project>)"
   > ```
3. The plan now feeds `/start-task N` for execution.
