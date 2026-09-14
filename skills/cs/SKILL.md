---
name: cs
description: Code-health gate for the current change. Runs CodeScene (`cs`)
  on the files you touched, sorts findings into "your current work" vs
  "grazed / pre-existing", and hands the first bucket to your judgment
  against the task's intent. Use as the closing structural gate after
  /review's fixes have settled, before /wrap-up.
---
# CodeScene Change Gate (`/cs`)

A pre-commit **code-health** lens for the current change. Not a linter
(style/correctness rules) — CodeScene scores structural health:
complexity, nesting, method size, cohesion. It runs on the working tree
as the **closing structural gate** — *after* `/review`'s fixes have
settled — and before `/wrap-up` / `/commit`.

Its job is to split code-health findings into two buckets and hand the
first to the working agent's judgment — never to auto-fix.

- **Topf A — your current work:** findings on lines you changed. Fix,
  consciously accept, or defer — the agent decides against the task's
  intent, exactly as it triages `/review` or second-opinion output.
- **Topf B — grazed / pre-existing:** findings in files you touched but
  on code you did not change. You only *surfaced* them; they are not this
  task's work. They go to a standing debt register and stay there.

This skill is intentionally **private and excluded from any published
skill bundle** — CodeScene is proprietary. `casefile skills install` and
`casefile skills update` do not manage it; maintain the private agent copies
directly. It has **zero coupling** to the published workflow skills: Topf A
is spoken back to the agent in this session, and Topf B is written to a
standalone debt register that nothing drains. `/wrap-up`, `/commit`, and the task log stay untouched — Topf B is
deliberately *not* folded into `### Open Issues`, because surfacing
pre-existing debt is not owning it.

## Work scope

Resolve the active roots before reading task context or writing the debt
register:

```
casefile root -v
```

Trust its output verbatim: `work root` is where `plan.md` and `task-log/`
live; `doc root` is where project-global docs live, including the debt
register in Step 5. Use `scope` and `mode` from the same output; never
re-derive paths or infer home mode from missing configuration or tooling.

Reading `<work-root>/plan.md` / the current
`<work-root>/task-log/task-{N}-*.md` is **optional** —
it only lets Topf A borrow AC-ID tags. `/cs` does not judge the task and
does not need to: it is a *producer* of sorted findings, like a
second-opinion review. The fix/accept/defer decision happens in the agent
that consumes this output, which already holds the task context. So `/cs`
runs in any repo, with or without the task system.

A missing plan does not invalidate successfully resolved roots. It only
removes AC tags; the register can still be written under `<doc-root>`.

If `casefile` is not on PATH or `casefile root -v` fails, report the root
resolution failure, continue the code-health analysis without task context,
and print both buckets. Skip the register write (Step 5); never fall back
to `vault`, manually derived paths, or a guessed `docs/` directory.

## Prerequisite — `cs` available and authenticated

```
cs auth status
```

If `cs` is not on PATH, or status reports signed-out and no
`CS_ACCESS_TOKEN` is set, stop and tell the user:

> CodeScene CLI is not ready. Run `cs auth login` (OAuth) or set
> `CS_ACCESS_TOKEN`, then re-run `/cs`.

Do not attempt analysis without a working license — every `cs review`
would fail the online license check.

## Step 1 — Determine the change scope (baseline: working tree)

Changed files = tracked modifications since HEAD, plus new untracked
files:

```
git diff --name-only HEAD
git ls-files --others --exclude-standard
```

Changed line ranges (new-side hunks) per file:

```
git diff HEAD -- <file>
```

Keep only CodeScene-scorable source files. Skip lockfiles, generated
output, docs, config, and vendored paths — they either score `null` or
are noise. A **new (untracked) file** counts as fully yours: every line
is "changed", so all its findings are Topf A.

> Knob: to gate exactly what `/commit` will stage rather than the whole
> working tree, use `git diff --cached` / `--name-only --cached` instead.
> Default is the full working tree (`HEAD`), matching `/review`.

## Step 2 — Run CodeScene per changed file

For each scorable changed file:

```
cs review <file> --output-format json
```

The JSON shape is:

```json
{ "score": 9.2,
  "review": [{ "category": "Complex Method",
    "functions": [{ "title": "…", "details": "cc = 16",
                    "start-line": 1460, "end-line": 1508 }],
    "description": "…" }] }
```

Skip files where `score` is `null` (no scorable code). Collect every
`review[].functions[]` entry with its `category`, `details`, and
`start-line`/`end-line`.

**Tiebreaker (optional but recommended)** — run delta once to learn which
findings your change actually *introduced or worsened* vs. which were
already there where you happened to edit:

```
cs delta --output-format json --include-metadata
```

Delta reports **new issues only** by design, so a finding present in
`delta` is one you made worse; a finding present only in `review` was
pre-existing.

## Step 3 — Sort into two buckets

For each finding, test whether its function's line span
`[start-line … end-line]` overlaps any line you changed in that file:

- **Overlap** (or the file is new/untracked) → **Topf A**.
- **No overlap** → **Topf B**.

Overlap **proposes** the bucket — deterministic and cheap, and the agent
may re-route in Step 4. It has one blind spot: it cannot tell an edit
that *caused* a smell from an edit *inside* a function that was already
unhealthy. When you added code that grew a function past a threshold,
overlap is definitionally correct — no judgment needed. When you merely
touched a line in a pre-existing complex function, the `delta` tiebreaker
(`adjacent`) flags it for re-routing to Topf B.

Then tag, reusing the review vocabulary the rest of the workflow speaks:

- Topf A: if the active `plan.md` defines acceptance criteria, tag the
  finding with the AC ID it touches (`T{N}-AC-{NN}`); otherwise tag it
  `current work`.
- Topf A refinement from the tiebreaker: mark each item `introduced`
  (in `delta` — you worsened it) or `adjacent` (only in `review` —
  already complex where you edited).
- Topf B: tag `pre-existing` / `no AC`.

## Step 4 — Triage Topf A against the task (do NOT auto-fix)

Hand Topf A to the working agent's judgment, given the task intent read
in Work scope — the same way `/review` and second-opinion findings are
triaged. For each item decide:

- **Fix now** — default for `introduced` findings: your change caused the
  regression, so restoring health is in scope.
- **Accept with note** — the finding is real but fixing it is out of
  scope or not worth it; record a one-line reason.
- **Defer** — default for `adjacent` findings: fixing means a real
  refactor of pre-existing code. Move it to Topf B.

Do not force fixes. Anything consciously not fixed flows into the
system's existing valve: `/wrap-up`'s `### Acceptance Coverage`
(`partial` / `skipped` with reason) and, at commit, a `Defers
T{N}-AC-… -> Task M` body line. The point of two buckets is to *prevent*
scope creep, not to make every `cc > threshold` a blocker.

## Step 5 — Persist Topf B to the standing debt register

Topf B is project-global (pre-existing debt lives on the mainline, not on
this branch), so it goes to a doc-root register that accumulates across
tasks and is left as-is until a refactoring task deliberately consumes it:

```
<doc-root>/tech-debt-backlog.md
```

One line per item (dedupe on path + function + category — if an entry
already exists, skip it rather than appending a duplicate):

```
- [ ] `<path>` — `<function>` (<category>, <details>, L<start-line>) — pre-existing; grazed by task <N> · source: cs
```

Always also print Topf B in the skill output, so it is visible this
session even if the register write is skipped.

- **No drain, no coupling:** nothing folds this register into `### Open
  Issues`. `/wrap-up` and `/commit` never read it. It feeds `/plan` only
  when you choose to open a debt task.
- **Casefile mode:** write the register only under the `doc root` returned
  by `casefile root -v`, in the private casefile repository. Work artifacts
  never enter the current repository.
- If the doc root could not be resolved, skip the write and rely on the
  printed Topf B.

## Output

Present two clearly separated buckets. Keep it compact and
attention-directing, like `/review` — do not restate the raw JSON.

```
CodeScene change gate — <N> files scanned, scores <lo>–<hi>

## Topf A — your current work
[FIX]    global-filter.store.ts · onInit L1574 · Complex Method cc=13 · introduced · T3-AC-02
         → your filter subscription pushed cc over threshold; extract the guard clauses.
[ACCEPT] …  (reason)
[DEFER]  …  (→ Topf B)

## Topf B — grazed / pre-existing  (→ debt register)
- global-filter.store.ts · constructPayload.resolveIds L1460 · Complex Method cc=16 · pre-existing
  → untouched by this task; candidate for a dedicated refactoring task.
```

End with the one-line register status: `N item(s) added to
tech-debt-backlog.md (M already present)`.

## Notes

- **Run order — `/cs` comes last, not in parallel.** Do `/review` and
  its fixes first, then `/cs`. Fixing review findings changes structure
  (added guards / error handling *raise* complexity; extractions *lower*
  it), so `/cs` must see the settled structure — and it then audits the
  health cost of the review fixes themselves, which a parallel run misses.
- **Keep the gate from re-opening review:** at this late stage take only
  small, behavior-preserving Topf A fixes. A finding that would need a
  real structural refactor goes to Topf B, not a last-minute rewrite that
  re-opens the review loop.
- `cs review` scores the current working-tree file; `git diff` new-side
  line numbers use the same coordinates, so overlap tests are exact.
- Baseline is working tree (a). `--staged` / `--cached` narrows the gate
  to exactly what `/commit` will stage.
