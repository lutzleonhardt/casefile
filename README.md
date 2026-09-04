# Casefile

**AI-assisted development that `git blame` can explain.**

> *casefile — the file a lawyer keeps on their own side of the desk, deliberately separate from the official record.*

Run in [native-federation/devtools](https://github.com/native-federation/devtools), a repo built with casefile:

![git blame gives a sha — casefile why prints the task log behind it](docs/assets/why.gif)

<details>
<summary>The same run as copyable text</summary>

```
$ casefile why projects/devtools-ui/src/app/app.html:7 --head 8
projects/devtools-ui/src/app/app.html:7 -> bae1956e (task-4: hide the Diagnostics tab)
tasklog: docs/work/graph-view/task-log/task-4-hide-diagnostics-tab.md (co-committed)
  ### Task

  Presentation-only nav change: the Diagnostics entry is removed from the
  panel navigation while the placeholder route stays reachable by direct
  URL (no redirect); the existing app/shell pins are extended in place and
  source comments record that the tab returns when resolution-model
  Task 10 (canonical Diagnostics) lands.

  … (177 more lines: git show bae1956e:docs/work/graph-view/task-log/task-4-hide-diagnostics-tab.md)
```

</details>

One command answered *why the Diagnostics tab is hidden* — and when it
comes back. The answer was not written for this question. It is the task
log that was committed together with the change, found via `git blame`.
Reading provenance needs no AI: plain git and a single-file Python CLI.

Or hand the question to an agent. One real `claude -p` run in the same
repo, answer unedited:

```
$ claude -p 'Why is the Diagnostics tab hidden? Use /why on projects/devtools-ui/src/app/app.html:7'
```

<details>
<summary>The full answer — Answer · Evidence · Caveat</summary>

> **Answer:** The Diagnostics tab was deliberately removed from the panel nav in graph-view Task 4 as a presentation-only change ahead of the 2026-08-25 demo: the view behind it was still an honest placeholder, so the tab is hidden until resolution-model **Task 10 (canonical Diagnostics)** lands and restores it. The route itself was left untouched — no redirect, no guard — so the placeholder stays reachable by direct deep link at `#/diagnostics` (hash routing; a path-based `/diagnostics` URL falls back to Packages). The deferral rationale is recorded in `docs/work/resolution-model/plan.md` under "Plan amendment (2026-08-23): demo resequencing".
>
> **Evidence:** `projects/devtools-ui/src/app/app.html:7` → `bae1956e` ("task-4: hide the Diagnostics tab") → `docs/work/graph-view/task-log/task-4-hide-diagnostics-tab.md` — sections *Task* and *Key Decisions* ("Route code untouched, comment only" and "Return-note placement").
>
> **Caveat:** Task 10 still hasn't landed (current sequence on `feature/resolution-model` is Task 12 next, then 10), so the hidden state is still the intended one. A known leftover from that decision: the capture-status strip can still show a plain-text `Diagnostics` label — deliberately left untouched per your call at the time, to be reconciled when Task 10 restores the tab.

</details>

The agent read the full log, pulled the deferral rationale from the
plan, and knew what has *not* happened yet. None of that context was in
the question.

## Every commit carries its case

Each task ends with one structured log: what changed and why, key
decisions with the alternatives that were rejected, test evidence,
acceptance coverage, open issues, and context for the next task. The log
competes with no ticket system — it holds exactly what is written down
nowhere else, and it is linked to the commit that made the change.

The chain runs one layer deeper: closing a task also archives the **raw
agent-session transcripts** that produced it — listed in the log's
Sessions section, stored next to the log in the private casefile repo
(in both modes), never in the code repo. The log is the curated record;
the transcript is the evidence behind it, kept before the agent tool
expires it. Transcripts capture everything the agent saw — including
client code. Whether archiving them is appropriate for a given
engagement is a contract question the operator answers, not the tool:
pass `--no-session` to `casefile link` (or skip `casefile archive`)
and the transcripts stay out.

| | **Home mode** | **Casefile mode** |
|---|---|---|
| Artifacts live | `docs/work/<scope>/` inside the repo | a private casefile repo outside it |
| Commit ↔ log link | log committed next to the code | git notes (never pushed to origin) |
| For | your own projects | client repos that must stay clean — zero footprint |

In casefile mode the commit ↔ log link lives in **local git notes**:
the client repo never sees the logs *or* the notes ref — `casefile
link` pushes its notes backup into the private casefile only. On the
operator's machine it looks like this
([native-federation-website](https://github.com/native-federation/native-federation-website)
is developed in casefile mode):

```
$ git log -1 --show-notes --format=short 4bf926e
commit 4bf926eb9a768d08ec2f12276b4b8800bbf824a7
Author: Lutz Leonhardt <kontakt@lutzleonhardt.de>

    feat: link the published Chrome Web Store listing

Notes:
    tasklog: native-federation/native-federation-website/work/webstore-link/task-log/feat-add-link-to-store.md
```

The [same commit on GitHub](https://github.com/native-federation/native-federation-website/commit/4bf926eb9a768d08ec2f12276b4b8800bbf824a7)
shows no note, and the repo carries no work directory at all. Unlike
the demo at the top, this one is deliberately *not* reproducible from
a clone: the provenance never left the operator's machine. Two edge
cases to know:

- **A fresh clone has no notes.** Notes do not travel with
  `git clone`; the links are still safe — every `casefile link`
  backs the notes ref up into the casefile repo, `casefile doctor`
  flags the gap after a re-clone, `casefile restore` brings them back.
- **Squash and rebase merges break the link.** Both mint new commits
  server-side, so the noted commit never reaches `main`. Merge
  commits (and fast-forwards) are safe: they keep the original SHAs —
  and `git blame` attributes lines to those, exactly where the notes
  hang.

## Tasks build on the record

The second half of the system is the loop that writes those logs. A spec
is sliced into isolated, commit-sized tasks; each new task starts by
reading its predecessor's log — not the whole history, not the sibling
tasks.

```mermaid
flowchart LR
    P["/plan\nspec → sized tasks"] --> S["/start-task N\nbriefing, wait for approval"]
    S --> I["implement + verify"]
    I --> W["/wrap-up N\nstructured task log"]
    W --> R["/review\nguided review brief"]
    R --> C["/commit N\ncode + log, staged from the log"]
    C -. "git notes: commit ↔ log" .-> W
    W -. "task N+1 starts from this log" .-> S
```

Anthropic's [AI-Native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
chains versioned artifacts forward — intent, spec, plan, diff, review
findings — and keeps standing knowledge in a deliberately short
`CLAUDE.md`. Casefile adds the layer both leave out: history. `CLAUDE.md`
holds state, not the reasons; the playbook's artifacts trace a feature
forward, but nothing routes from a line of code back to the decision
behind it, or hands one task's discoveries to the next. One log per
task, linked to its commit, does both.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/lutzleonhardt/casefile/main/install.sh | sh
casefile skills install
```

The first line installs the `casefile` CLI (single-file Python, stdlib
only) to `~/.local/bin` — nothing else. The second, deliberately
separate, writes the six skills for the agents it finds — Claude Code
(`~/.claude/skills/`) and Codex (`~/.codex/skills/`) — overwriting
those six names. Both scripts are short — read them first. Re-running
either is the update.

## First five minutes

Install done — this is the loop, once per task.

<details>
<summary>Home mode — your own repo</summary>

Write a short spec (`docs/specs/feature.md`), then in Claude Code:
`/plan docs/specs/feature.md` → approve the task list →
`/start-task 1` → approve the briefing, let it implement →
`/wrap-up 1` → `/review` → `/commit 1`. The plan and log land in
`docs/work/<scope>/` (scope derived from the branch), committed next
to the code. From then on, `casefile why <file>:<line>` answers from
the log.

`/review` defaults to a quick per-task triage; `/review full` is the
deeper pre-PR pass, `/review coverage` maps a large diff into an
ordered walkthrough. It reads best from a session that did not write
the code: run it in a fresh agent session and hand the findings back
to the implementing session to verify and fix.

</details>

<details>
<summary>Casefile mode — a client repo</summary>

Once per repo: `casefile enable <client>/<project>` — creates the
private casefile repo at `~/casefile` if needed; config lives in
`.git/config`, never committed. The task loop is identical; `/commit`
ends with `casefile link`, which attaches the git note, commits the
casefile repo, and backs up the notes ref. `casefile doctor` checks
the setup; `casefile disable` turns it off.

</details>

## The skills

| Skill | Job |
|---|---|
| `/plan` | Slice a spec into right-sized, testable tasks; key locations verified against the code; writes only after approval. |
| `/start-task N` | Brief the task from the plan block, the predecessor log, and bounded history — then wait for approval. |
| `/wrap-up N` | Write or extend the task log; merges across sessions; records plan deviations; handles BLOCKED with a re-plan. |
| `/review` | Guided review brief — quick per task, full before a PR, coverage for large diffs. Cross-checks the log's claims. |
| `/commit N` | Stage code + log from the log's own record, show the plan, commit after confirmation; casefile mode links via git notes. |
| `/why FILE:LINE` | The demo above, as a skill: blame → commit → log → answer, with the evidence chain cited. |

## Evidence

devtools is developed with casefile in home mode, in the open: browse
the [task logs](https://github.com/native-federation/devtools/tree/main/docs/work/resolution-model/task-log)
or a [single commit](https://github.com/native-federation/devtools/commit/76eca17)
carrying code, design doc, and log together. The demo at the top is
reproducible: clone devtools, install casefile, run the command.

## Status

A reference setup, extracted from daily use — not a framework looking
for users. Read the skills, adapt them, keep what earns its place.
Issues and discussion welcome; roadmap promises not included.

Built by [Lutz Leonhardt](https://lutzleonhardt.de/). MIT.
