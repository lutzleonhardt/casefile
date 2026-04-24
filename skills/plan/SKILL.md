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

3. **Propose a task breakdown** following the rules below.
   Present it to the user **before** writing any file.

4. **Wait for user approval.** Only then write to
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
- **Acceptance built in.** Each task carries its own verification —
  prefer automated tests (unit or integration). If automation is
  a bad fit, acceptance may be omitted rather than prescribing
  manual steps. For pure mechanical refactors with no behavior
  change, acceptance is optional (existing tests staying green
  is implicit).
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
- **Acceptance** — how to verify success. Optional only for pure
  mechanical refactors.
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
  own line. Tasks are numbered sequentially starting at 1.
- **Task block** — from `## Task N` up to (but excluding) the
  next `## Task M` heading or EOF. `/start-task N` extracts
  exactly this block.

Do not nest tasks under deeper headings (`### Task N`) and do
not split a task across multiple `## Task N` occurrences — the
extraction pattern anchors on `^## Task <number>`.

## Flexibility clause (include verbatim in the plan)

> The executing agent may adjust scope and ordering based on more
> up-to-date context discovered during implementation, as long as
> each task still satisfies the sizing rules above.
>
> When a task is finished (DONE or BLOCKED), run `/wrap-up` to
> generate the summary, commit summary + code together in a
> single commit, and optionally run `/review` (quick per-task,
> full before a PR). Do not commit automatically.

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
