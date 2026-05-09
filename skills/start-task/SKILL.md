---
name: start-task
description: Bootstrap a new task session with plan context, 
  previous task summary, and current git state.
---
# Start Task

The user wants to begin a new task from the task plan.
Use $ARGUMENTS to identify the task (e.g. "/start-task 3" 
means Task 3).

## Your workflow:

1. **Load the plan preamble + only the requested task block.**
   `/start-task` must not read sibling tasks — this would pollute
   context and break task isolation. The plan brings three
   distinct pieces of context, and only two apply now: the
   preamble (global rules) and the requested task block. Sibling
   tasks are explicitly out of scope.
   - Locate the plan file: `docs/plans/*.md` or `plan.md` in the
     project root. If no task number is given in $ARGUMENTS,
     ask which task to start.
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

2. **Read the previous task summary.** Look in:
   - `docs/task-log/` for the most recent summary file
   - Use `ls -t docs/task-log/ | head -1` to find it
   - If this is Task 1, skip this step

3. **Check git state:**
   - `git log --oneline -5` — recent commits
   - `git status --short` — any uncommitted changes
   - `git diff --stat HEAD~1` — what changed last

4. **Produce a Task Briefing** with this structure:

   ### Task N: <title from plan>
   
   **Scope:** What this task should accomplish (from plan)
   
   **Context from previous task:**
   - Key decisions made
   - Files modified
   - Open issues carried forward
   
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
     `docs/task-log/task-{N}-{slug}.md`. Safe to run multiple
     times across sessions before committing; findings are merged.
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
