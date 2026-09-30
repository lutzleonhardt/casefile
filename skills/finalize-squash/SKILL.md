---
name: finalize-squash
description: Finalize a completed casefile scope after a squash merge.
  Takes the resulting commit hash, writes a summary and task-log index,
  and links that document to the commit through a backed-up Git Note.
---
# Finalize Squash

The user stays on the original feature branch and supplies the resulting
squash-commit hash in `$ARGUMENTS`: `/finalize-squash <sha>`. Complete
the summary, linking, and local notes backup in this invocation; do not
hand the user a sequence of CLI commands to execute.

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

**Home mode:** explain that co-committed task-log files survive the
squash, including their session references. No additional Git Note is
needed; finish without creating a summary or changing modes. `why`
may return several logs because the squash contains their combined
changes.

In casefile mode, the original local feature branch must still exist
and be checked out. Keep it until finalization succeeds. Do not switch
to the target branch or derive the scope from the squash commit. If the
original branch was deleted or the current scope is unclear, stop;
branch recovery is outside this workflow.

## Resolve the commit and evidence

- Require one explicit hexadecimal commit hash, abbreviated or full.
  Never substitute `HEAD`, a branch tip, or a commit guessed from its
  message. Resolve it to a full commit ID with
  `git rev-parse --verify '<sha>^{commit}'`. If missing locally, fetch
  from the configured upstream remote (or `origin` when unambiguous)
  and retry. Stop if the hash remains missing or ambiguous.
- Inspect the commit's changes against its parent. A squash normally
  has one parent; do not require a two-parent merge commit. The supplied
  hash is the user's association with this scope: Git alone cannot prove
  that association. Compare the patch with the scope's logs and branch
  history; clarify concrete contradictions before attaching a note.
  Do not require identical feature and target trees, since the target
  may also contain other work.
- Read the scope's `plan.md` if present and every task log in its
  `task-log/` directory, including research, fix, and unnumbered logs
  without a code commit. Follow relevant planning references. Exclude
  the summary for this same squash from its own source index; use an
  existing copy only to update it. If there are no source logs, stop
  rather than inventing a record.
- Reconcile the recorded work with what actually landed. Distinguish
  superseded decisions, deferred tasks, and merge adjustments from
  current behavior. Do not mark unfinished work or unrun checks as
  complete merely because the branch was merged.

## Write the summary and index

Use one stable document per squash:

```
<work-root>/task-log/squash-<full-sha>.md
```

Write or update it in the established language of the scope's documents.
Include:

- **Identity:** project, scope, original branch and its current commit
  ID, and the full squash ID. Branch-tip IDs are context, not a promise
  that the original commits have been archived.
- **Integrated outcome:** what landed, its boundaries, and any observed
  differences from the plan or original branch.
- **Key decisions:** the reasons that still apply, with links to the
  source logs. Mark superseded decisions as historical.
- **Source index:** one relative link and a short topic description for
  every source task log, plus links to the plan and relevant planning
  documents. Keep the original logs and their session references intact.
- **Validation and open points:** recorded evidence, what it was tested
  against, and any remaining limitations of the merged result. Separate
  earlier feature-branch checks from checks of the squash itself.

Check that every local index link resolves. Do not copy all raw sessions
or all log contents into the summary. Session IDs and archives remain
associated with their original project, scope, and task.

## Link and verify

The user's invocation authorizes this summary, its casefile commit,
the Git Note, and the backup into the local private casefile. Briefly
announce the concrete target and proceed without another routine
confirmation. Do not invoke `/commit` or ask the user to run the link
command themselves. Never push to the code repository's origin, amend
the squash commit, or modify the source repository's index or files.

Before linking, check the casefile repository's index and the working
tree under this project. `casefile link` stages the entire project and
commits the entire index. Only the intended summary may be pending in
that set. If other changes would be included, report their paths and
leave the prepared summary for a retry; do not commit, stash, or reset
unrelated work. Recheck the active scope, then run:

```
casefile link squash-<full-sha> <full-sha> --no-session
```

The named-log form resolves the summary in the current scope, appends
its `tasklog:` pointer to the target commit without replacing other
notes, commits the casefile, and backs up the notes ref there.
`--no-session` skips additional session archiving during finalization.
Existing task-session archives and references remain unchanged.

Verify that the exact summary pointer appears once in
`git notes show <full-sha>` and the summary is committed in the casefile.
Run `casefile doctor` and require `backup: in sync` to confirm that the
notes backup matches the local notes ref.
Reading `why` on the original feature branch does not verify the squash
link: blame there still points at the original commits.

Reruns reuse the same document and pointer. Avoid gratuitous rewrites;
the existing link command skips a duplicate pointer and retries its
backup. If a step fails, report what succeeded and what remains pending;
do not report completion until the document, note, and backup are all
verified.

Finish with the scope, squash hash, a link to the summary, and the
verified note/backup result. The resulting evidence chain is
`code line → squash → summary → original task logs`; precise attribution
to the original individual commits is outside this workflow.
