---
name: plan
description: Break a spec into a right-sized, testable task plan.
  Produces a proposal; writes to docs/plans/ only after user approval.
  Each task is sized so that its diff + test could land as a single commit.
---
# Plan a Spec

The user has a specification (in `docs/specs/`, a chat message, or
a linked issue) and wants to turn it into an ordered task list that
`/start-task` can consume.

Use `$ARGUMENTS` to locate the spec (e.g. `/plan docs/specs/auth-rewrite.md`).
If no argument is given, ask which spec to plan.

## Workflow

1. **Read the spec in full.** Do not plan from a summary — read the
   whole document so acceptance criteria and edge cases are visible.

2. **Check repo state:**
   - `git log --oneline -10`
   - `ls docs/task-log/ 2>/dev/null` — is there related recent work?
   - `ls docs/plans/ 2>/dev/null` — does a plan already exist for this spec?

3. **Pick the starting task number.** Task numbers are
   **globally sequential across the repo**, not local to one
   plan. To find the right starting number:

   ```
   ls docs/task-log/task-*.md 2>/dev/null
   grep -h '^## Task ' docs/plans/*.md 2>/dev/null
   ```

   Take the highest `N` that appears in either output (a logged
   task or a not-yet-wrapped-up task in another plan) and start
   this plan at `N + 1`. If both queries return empty, this is
   the first plan in the repo — start at 1.

   Why globally sequential: the whole skill chain
   (`/start-task`, `/wrap-up`, `/commit`, `/handoff`) keys off
   a single integer plus the file convention
   `task-N-{slug}.md`. Restarting numbering per plan or per
   milestone breaks that integer's uniqueness and produces
   filename collisions in `docs/task-log/`. The plan filename
   (`docs/plans/{slug}.md`) already carries milestone identity
   when needed; the task number does not have to.

4. **Propose a task breakdown** following the rules below.
   Present it to the user **before** writing any file.

5. **Wait for user approval.** Only then write to
   `docs/plans/{slug}.md`. If a plan file already exists, propose
   an edit rather than overwriting — the user decides.

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
  own verification — prefer automated tests (unit or integration).
  Each acceptance criterion gets a stable ID:
  `T{N}-AC-{NN}` where `{N}` is the task number exactly as written
  in the plan (`T3`, `T3.5`, `T17`, ...) and `{NN}` is a zero-padded
  counter starting at `01`. Use those IDs in `/start-task`,
  `/wrap-up`, `/commit`, and `/review`.
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
  - If this task contributes to a cross-cutting acceptance item,
    mention the `XC-NN` ID here; `/start-task` will not load the
    plan-end cross-cutting section by default.
  Optional only for pure mechanical refactors.
- **Key Locations** — files, fully qualified classes/methods
  likely to be touched.
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
- **Task heading** — `## Task N` or `## Task N: <title>` on its
  own line. Numbering is globally sequential across the whole
  repo (see Workflow step 3) — a new plan does **not** restart
  at 1 if prior tasks already exist. If the new plan's first
  task is, say, Task 17, that's correct; the gap (Tasks 1–16
  live in earlier plans / earlier milestones) is intentional
  and is the cost of keeping every `task-N-{slug}.md` filename
  globally unique. Optionally add a one-line preamble note
  ("Task numbering continues from <prior-plan>; last task = N.")
  to spare future readers the lookup.
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
> `docs/task-log/task-{N}-{slug}.md` and is safe to run multiple
> times across sessions — it merges. `/commit N` reads that log,
> stages code + summary, and commits them together after showing
> the plan and waiting for confirmation. Optionally run `/review`
> (quick per-task, full before a PR) between wrap-up and commit;
> a second `/wrap-up N` can absorb the review findings.

This keeps the plan a guide, not a straitjacket — and gives every
`/start-task` run the closing checklist in its loaded context.

## After user approval

1. Write the plan to `docs/plans/{slug}.md`. Create `docs/plans/`
   if it does not exist.
2. Do NOT commit automatically. Tell the user:
   > Plan is ready at `docs/plans/{slug}.md`.
   > Recommended commit:
   > ```bash
   > git add docs/plans/<file>
   > git commit -m "plan: <spec title>"
   > ```
3. The plan now feeds `/start-task N` for execution.
