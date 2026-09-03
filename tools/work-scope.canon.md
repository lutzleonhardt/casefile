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
