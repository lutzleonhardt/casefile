---
name: start-task
description: Bootstrap a new task session with plan context, 
  task-history context, and git history.
---
# Start Task

The user wants to begin a new task from the task plan.
Use $ARGUMENTS to identify the task (e.g. "/start-task 3" 
means Task 3).

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

### Casefile mode

Some repositories must not carry work artifacts (customer repos,
work that stays local). Casefile mode — enabled once per repo with
`casefile enable <client>/<project>` (config in `.git/config`, never
committed; `casefile disable` turns it off; enabling/disabling is a
user decision — a skill never runs either command itself) —
reroutes the work root
into a private casefile repository; commits are linked to task logs
via git notes instead of committed files.

- **Casefile layout:** the casefile is its own git repo. `<doc-root>/`
  holds project-global docs; `<doc-root>/work/<scope>/` holds
  `plan.md`, `task-log/` and `sessions/`.
- **Origin stays clean:** never push notes refs to the repository's
  origin — `casefile link`'s backup push targets the private casefile only.
- **No AC IDs in the code:** in casefile mode, AC IDs (`T{N}-AC-{NN}`,
  `XC-NN`) and task numbers never appear in source comments, test
  names, fixtures, or any other file of the current repository —
  the plan is invisible from there, so to colleagues they are
  dangling references. Prepare the AC → test mapping in step 4;
  record the verified mapping in the wrap-up log's Acceptance Coverage.
  Home mode is different: the plan is committed next to the code,
  so tagging tests and comments with their AC ID is allowed and
  useful.
- **Tooling:** `casefile doctor` checks config, notes and backup
  state; `casefile why <file>:<line>` resolves a blamed line to its
  task log.

## Your workflow:

1. **Load the plan preamble + only the requested task block.**
   `/start-task` must not read sibling tasks — this would pollute
   context and break task isolation. The plan brings three
   distinct pieces of context, and only two apply now: the
   preamble (global rules) and the requested task block. Sibling
   tasks are explicitly out of scope.
   - Locate the plan file at `docs/work/<scope>/plan.md`. If it does
     not exist, stop per the Work scope rule. If no task number is
     given in $ARGUMENTS, ask which task to start.
   - **Primary path — shell-free extraction via `grep` + `Read`:**
     1) `grep -n '^## Task [0-9]' <plan-file>` to list every task
        heading with its line number.
     2) Preamble: `Read <plan-file>` with `offset=1` and
        `limit=<line-of-first-task-heading − 1>`.
     3) Task N block: `Read <plan-file>` with
        `offset=<line-of-Task-N>` and
        `limit=<line-of-Task-N+1 − line-of-Task-N>`. For the last
        task, omit `limit` (reads to EOF).
     This avoids shell quoting entirely and is the preferred route.
   - **Fallback — pure-shell awk (only if `Read` offset/limit is
     unavailable):** use a positive-only pattern that contains no
     `!`. Do NOT use `!f` — in interactive bash the leading `!`
     triggers history expansion and breaks the command:

     ```
     awk '/^## Task [0-9]/{exit} {print}' <plan-file>
     awk -v n=N '/^## Task [0-9]/ { if (inblock) exit; if ($0 ~ "^## Task " n "($|[: ])") inblock=1 } inblock' <plan-file>
     ```
   - Do NOT read the spec (`docs/specs/`). If the task block
     references the spec or a sibling task, flag this back to
     the user before proceeding — the plan violates `/plan`'s
     self-containment rule and should be amended first.

2. **Read task-history context.** Tasks build on each other, so
   the direct predecessor is the fast path — but earlier tasks can
   matter too. Reading older task logs is *history retrieval*, not
   a violation of task isolation: the isolation rule applies to
   sibling **plan** tasks, not to past **logs**.
   - **Direct predecessor (fast path):** read
     `docs/work/<scope>/task-log/task-{N-1}-*.md`. Use the
     deterministic numbered path — `ls -t` is unreliable, because
     a re-run of `/wrap-up M` for an older task can give its file a
     newer mtime than the real predecessor.
   - If this is Task 1, skip the predecessor read.
   - **Bounded relevance search across older logs.** Extract
     concrete terms from the requested task block — file paths,
     class/function names, AC IDs, domain terms, referenced
     interfaces — and search `docs/work/<scope>/task-log/` with
     `rg`. Example:
     for a task block mentioning `BuildToolsPolicy` and
     `tools/build-tools.ts`:
     `rg -n 'BuildToolsPolicy|build-tools\.ts' docs/work/<scope>/task-log/`
     Avoid generic terms (`service`, `config`, `handler`) — they
     match everywhere and produce noise.
     If the preamble carries a `Predecessor:` line, that scope's
     `task-log/` belongs to the same search. The line is the user's
     judgment that the two scopes are connected; do not widen the
     search to unrelated scopes on your own.
   - **One line, on demand.** When a single line's *reason* would
     change your approach, resolve it instead of searching for it:
     `casefile why <file>:<line>` prints the commit and its task
     log, across scopes and in both modes. A targeted lookup, not
     a survey.
   - **Hard cap:** read at most 2–3 additional logs beyond the
     predecessor. If more look relevant, surface the candidates
     to the user instead of reading all of them.
   - Use each older log to identify decisions or constraints that
     affect this task. Surface those consequences in the briefing
     when relevant; do not list every context source by default.

3. **Check git history.**
   - `git log --oneline -10` — recent commits.
   - `git status --short` — any uncommitted changes.
   - `git diff --stat HEAD~1` — what changed last.
   - **Per-file history when the task touches known files:**
     `git log --oneline -- <file>` for each key file named in the
     task block.
   - **Optional pickaxe** — only when a symbol is central or its
     history looks suspicious, and **always file-scoped**:
     `git log -p -S'<symbol>' -- <file>`. The unscoped form scans
     every commit and produces huge output; do not use it as a
     default.
   - `git show <hash>` only for commits that look directly
     relevant to the task.
   - **Casefile mode — notes-driven log retrieval:** run the per-file
     history commands with `--show-notes`. A note line
     `tasklog: <project>/work/<scope>/task-log/<file>` names the casefile
     log of the commit that produced those lines — read the
     referenced log from the casefile. This channel finds logs across
     branch scopes (stacked branches), which the directory-scoped
     search above cannot. Logs read this way count toward the
     2–3 extra-log cap.
   - **Casefile mode — notes restore check (once per session):** run
     `casefile doctor`. If it reports missing local notes with an
     existing backup (typical after a re-clone), offer to run
     `casefile restore`.

4. **Prepare the implementation.** Work out the assumptions,
   risks, file-level plan, rollback approach, and verification
   before presenting the briefing. Map each planned test or manual
   check to the task's AC IDs (`T{N}-AC-{NN}`), and identify any
   coverage gaps. This preparation remains required even though
   the user-facing briefing is short. Keep the detailed plan in
   the task context; do not create another briefing document just
   to hold it. `/wrap-up` records the actual decisions and verified
   AC coverage for the independent reviewer.

   If the file-level plan exceeds ~10 files, or the
   task block's Key Locations turned out wrong or incomplete (the
   real code lives elsewhere, or one location fans out into a
   whole subsystem), stop and propose a split or a plan amendment
   before writing code — do not absorb the extra scope silently.
   An accepted deviation must later appear in `/wrap-up`'s
   `Plan deviations`.

   Identify what concrete output proves this task worked,
   and what the next task can treat as validated. If there is
   no clear answer, stop and flag back to the user — the task
   is likely too large or too vague. This gate also catches
   oversized tasks from plans written outside `/plan`.

   Do not load the plan-end `Cross-Cutting Acceptance` section
   during normal task start. If the requested task block itself
   references an `XC-NN`, include that contribution in the prepared
   test plan. Keep preparation and briefing grounded in the task
   block. Do not write implementation code yet.

5. **Explain the task to the user.** The briefing should let the
   user understand the intended behavior and architectural change,
   then decide whether to proceed. Use the conversation's language
   unless the user requests another. Start with
   `Task N: <title from plan>` and use this reading order:

   - **What changes and why:** one or two sentences about the
     outcome. For a refactor, name the responsibility being moved
     and what its callers will see.
   - **How it fits together:** the few participating parts, who
     owns the relevant state, and who calls or notifies whom —
     shown in code, as described below. Define unfamiliar or easily
     confused task-specific terms at first use, ideally as a
     comment next to the identifier. Use familiar words and
     concrete verbs; avoid invented labels. Assume technical
     fluency, without assuming familiarity with this particular
     system.
   - **How we will check it:** one or two sentences naming the
     observable result and the relevant check. Make meaningful
     verification limits visible, including what a later task
     still needs to prove.
   - **Decisions before starting:** for each unresolved question,
     explain the choice, your recommendation, and its practical
     consequence. Surface material assumptions, risks, scope
     deviations, or conflicting local changes here even when the
     rest of the briefing is short. If no decision is open, say
     the task is ready to implement.

   Carry the first two parts in code rather than prose: one or two
   short excerpts, usually 5–15 lines each, whose comments state
   the essence — a before/after pair, caller and callee,
   composition and use, or a state change. Prose only connects the
   excerpts and covers what code cannot show. Use code to explain
   the mechanism, not to sketch the implementation. Ground it in
   the actual code or approved plan; label proposed or simplified
   code accordingly. Omit boilerplate and unrelated types. Skip
   code only when the change has nothing code-shaped to show, such
   as a pure configuration or documentation change.

   Keep the prose to a few short sentences per part. Do not append
   the old technical briefing: omit routine history, commit lists,
   full file inventories, and AC-by-AC test mappings unless
   requested or needed for a decision. Answer follow-up questions
   the same way: a focused annotated excerpt with a sentence of
   context, never a drafted implementation. Correct
   misunderstandings explicitly.

6. **Wait for user approval** before proceeding.

7. **When the implementation is finished, explain the result and
   remind the user to close it out.**
   Make the report understandable without rereading the briefing.
   State the outcome and explain the central mechanism of the
   finished implementation, including work that went as briefed.
   For code changes, use a few short excerpts of the actual code
   with comments carrying the explanation; do not invent an
   implementation to illustrate the result.

   Then explain deviations and unplanned additions, such as a
   workaround or a restructured call site, with their reasons.
   Show further code or a before/after pair where it clarifies
   those differences. Add verification results and open points in
   a few lines. Focus on behavior and architectural relationships;
   leave the full file-by-file account to the wrap-up log.

   Then, for DONE and BLOCKED alike, surface the closing pair —
   do **not** execute either step automatically, these are user
   decisions:
   - `/wrap-up N` — writes or extends
     `docs/work/<scope>/task-log/task-{N}-{slug}.md`. Safe to run
     multiple times across sessions before committing; findings are
     merged. An initial wrap-up before independent review provides
     the reviewer with intent, decisions, and test evidence; state
     clearly when review is still pending.
   - `/commit N` — stages code + summary from the log and commits
     them together (after showing the plan and waiting for
     confirmation).
   - Optionally `/review` between the two — default is quick mode
     (per-task hotspots + blind spots); use `/review full` before
     a PR, `/review coverage` for large diffs. A second `/wrap-up N`
     can absorb the review findings before `/commit N` runs.

   If the user explicitly declared the task BLOCKED instead of
   DONE, still point at `/wrap-up N` — it handles the BLOCKED case
   (escalation assessment + re-plan proposal), and `/commit N`
   picks up the BLOCKED commit-message template from the log.
