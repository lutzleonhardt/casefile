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

Resolve the active work root before reading plan or task-log files:

1. Run `git branch --show-current`.
2. If the branch name is empty (detached HEAD), stop and ask the user to
   switch to a branch before starting task work.
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
work root. Legacy paths (`docs/plans/*.md`, root `plan.md`, and
`docs/task-log/`) are not automatic fallbacks.

## Your workflow:

1. **Load the plan preamble + only the requested task block.**
   `/start-task` must not read sibling tasks — this would pollute
   context and break task isolation. The plan brings three
   distinct pieces of context, and only two apply now: the
   preamble (global rules) and the requested task block. Sibling
   tasks are explicitly out of scope.
   - Locate the plan file at `docs/work/<scope>/plan.md`. If it does
     not exist, stop and ask the user to run `/plan` or migrate the
     existing work artifacts into this scope. If no task number is given
     in $ARGUMENTS, ask which task to start.
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
   - **Hard cap:** read at most 2–3 additional logs beyond the
     predecessor. If more look relevant, surface the candidates
     to the user instead of reading all of them.
   - For each older log you read, note one sentence on *why* it
     was relevant. If no older logs are relevant, say so
     explicitly in the briefing.

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

4. **Produce a Task Briefing** with this structure:

   ### Task N: <title from plan>
   
   **Scope:** What this task should accomplish (from plan)
   
   **Task-history context:**
   - Direct predecessor: key decisions, files modified, open
     issues carried forward
   - Earlier related task logs consulted, each with a one-line
     *why*. State explicitly if none were relevant.
   - Relevant git-history findings (per-file or per-symbol), if any
   
   **Current repo state:**
   - Recent commits
   - Uncommitted changes (if any)
   
   **Proposed approach:**
   1) Assumptions
   2) Risks
   3) File-level plan
   4) Testable artifact & review guard for the next task
   5) Test plan — list which AC IDs (`T{N}-AC-{NN}`) each
      planned test or manual check covers
   6) Rollback plan
   
   Do not write code yet.

   On point (4): what concrete output proves this task worked,
   and what can the next task treat as "validated"? If there is
   no clear answer, stop and flag back to the user — the task
   is likely too large or too vague. This gate also catches
   oversized tasks from plans written outside `/plan`.

   Do not load the plan-end `Cross-Cutting Acceptance` section
   during normal task start. If the requested task block itself
   references an `XC-NN`, mention that this task contributes to it
   in the test plan, but keep the task briefing grounded in the
   task block.

5. **Wait for user approval** before proceeding.

6. **When the task is finished, remind the user to close it out.**
   After the implementation work is done (DONE or BLOCKED), surface
   the closing pair — do **not** execute either step automatically,
   these are user decisions:
   - `/wrap-up N` — writes or extends
     `docs/work/<scope>/task-log/task-{N}-{slug}.md`. Safe to run
     multiple times across sessions before committing; findings are
     merged.
   - `/commit N` — stages code + summary from the log and commits
     them together (after showing the plan and waiting for
     confirmation).
   - Optionally `/review` between the two — default is quick mode
     (per-task hotspots + blind spots); use `/review full` before
     a PR. A second `/wrap-up N` can absorb the review findings
     before `/commit N` runs.

   If the user explicitly declared the task BLOCKED instead of
   DONE, still point at `/wrap-up N` — it handles the BLOCKED case
   (escalation assessment + re-plan proposal), and `/commit N`
   picks up the BLOCKED commit-message template from the log.
