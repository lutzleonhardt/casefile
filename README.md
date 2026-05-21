# Skill Kit: Agentic Workflow Skills

Sechs Claude-Code-Skills für einen reproduzierbaren Agentic-Coding-Workflow: **Plan → Start-Task → Wrap-Up → Commit**, plus `/handoff` für Context-Engpässe und `/review` als Qualitäts-Check. Gedacht für Senior Developers, die mit Claude Code in Legacy-Enterprise-Codebasen arbeiten und ihr Senior Judgment behalten wollen — nicht wegautomatisieren. Installation: entweder per `git clone` + Copy, oder einfach _„Claude, lies die `README.md` in diesem Repo und leg die Skills projekt-lokal an."_ (Details unten.)

---

## Pattern, keine Vorgabe

Das hier ist **ein** Weg, nicht *der* Weg. Die sechs Skills sind die Form, in der *mein* Agentic Workflow am zuverlässigsten läuft — ich habe gute Erfahrungen damit gemacht, deshalb sind sie hier aufgeschrieben. Niemand ist darauf angewiesen, genau diese Skills in genau dieser Form zu übernehmen — auch nicht meine.

Skills sind billig und trivial änderbar: eine Markdown-Datei, ein paar Zeilen YAML-Frontmatter, Aufruf über Slash-Command. Daraus folgt: **Bau dir deine eigenen**, entlang deiner eigenen Best Practices. Wer zum Beispiel streng nach Test-Driven Development arbeitet, modelliert Red/Green/Refactor als eigene Skills. Wer feste Release-Rituale hat, baut dafür einen. Wer in Pair-Programming-Mustern denkt, formalisiert die dort. Die Taktung und die Trigger-Wörter gehören dir.

**Eine einzige Leitplanke:** Nicht zu viel automatisieren. Jeder Skill, der Entscheidungen ohne den Menschen trifft, nimmt Senior Judgment raus — und genau das ist die Substanz, die hier geschützt werden soll. Skills sollen Vorarbeit leisten (Kontext einsammeln, Templates vorbereiten, Artefakte ablegen), nicht Urteile fällen. Der Mensch bleibt in der Mitte, egal wie das Skill-Set zugeschnitten ist.

---

## Verzeichnisstruktur im Überblick

Das vollständige Bild, bevor es in die Installation geht — was liegt wo, und welcher Skill produziert welche Datei?

```
project-root/
├── .claude/
│   └── skills/
│       ├── plan/SKILL.md          # Spec → Task-Plan
│       ├── start-task/SKILL.md    # Task-Bootstrap
│       ├── wrap-up/SKILL.md       # Task-Summary schreiben / erweitern
│       ├── commit/SKILL.md        # Summary + Code atomar committen
│       ├── handoff/SKILL.md       # Context-Übergabe (Exception)
│       └── review/SKILL.md        # Review-Brief
├── docs/
│   ├── specs/                     # Intent: was wird gebaut und warum (Input für /plan)
│   │   └── <feature>.md
│   └── work/                      # Branch-scoped Arbeitsgedächtnis
│       └── <branch-scope>/
│           ├── plan.md            # Scope: Task-Reihenfolge
│           └── task-log/          # Protokoll: was tatsächlich passiert ist
│               └── task-{N}-{slug}.md
├── handoff.md                     # Temporär, gitignored (Output /handoff)
└── .gitignore
```

**Drei Schichten, drei Lebenszyklen:**

- **`.claude/`** — Tool-Config, an Claude Code gebunden. Beim Tool-Wechsel wandert das nicht mit.
- **`docs/`** — Prozess-Gedächtnis, tool-agnostisch, versioniert, teilbar. Das Herz des Workflows.
- **`handoff.md`** — ephemer. Entsteht nur bei Context-Not, wird nach Erfolg gelöscht, bleibt aus dem Repo raus.

**Datenfluss zwischen den Skills:**

`docs/specs/X.md` → `/plan` → `docs/work/<branch-scope>/plan.md` → `/start-task N` → Implementierung → `/wrap-up N` → `docs/work/<branch-scope>/task-log/task-N-{slug}.md` → `/commit N` → atomarer Commit (Code + Summary). Der Plan nennt im Preamble explizit seine Quelle, z. B. `Spec: docs/specs/X.md`.

`<branch-scope>` wird automatisch aus dem aktuellen Git-Branch abgeleitet: `main` bleibt `main`, `master` bleibt `master`, `feature/f1234-user-import` wird zu `f1234-user-import`. Dadurch bleibt der tägliche Flow kurz (`/start-task 2`), aber parallele Worktrees schreiben nicht mehr in denselben globalen Task-Log.

`/wrap-up N` darf über mehrere Sessions hinweg mehrfach laufen — neue Findings werden in dieselbe Log-Datei gemerged, bis `/commit N` den Task abschließt.

`/handoff` ist der Seitenausstieg bei Context-Knappheit (schreibt `handoff.md`), `/review` der Qualitäts-Check zwischendurch oder vor PR (schreibt nichts, produziert einen Brief an den Menschen).

---

## Installation

Jeder Skill ist eine `SKILL.md`-Datei in einem eigenen Unterordner. Das Repo liefert beides: eine aufgesplittete Form unter [`skills/`](./skills/) — und die eingebetteten Versionen weiter unten in dieser README, damit Claude sie aus einer einzigen Datei anlegen kann.

### Option 1 — Claude liest die README und legt die Skills an (empfohlen)

```
"Claude, lies die README.md in diesem Repo und leg die sechs Skills projekt-lokal unter .claude/skills/ an.
Lege außerdem docs/specs/ an und ergänze handoff.md in .gitignore. docs/work/<branch-scope>/ wird vom ersten /plan angelegt."
```

Das funktioniert, weil die vollständigen Skill-Bodies weiter unten eingebettet sind. Für den Moment, in dem das System zum ersten Mal in einem Repo eingerichtet wird, ist das der kürzeste Weg — Claude holt sich nebenbei den Kontext, *warum* die Skills so aussehen, wie sie aussehen.

### Option 2 — Git-Clone + Copy

```bash
git clone https://github.com/<user>/skill-kit-agentic-workflow.git
cd <dein-projekt>

# Skill-Ordner (projekt-lokal, versionierbar, teambar)
mkdir -p .claude/skills
cp -r /pfad/zu/skill-kit-agentic-workflow/skills/* .claude/skills/

# Prozess-Artefakt-Ordner
mkdir -p docs/specs
touch docs/specs/.gitkeep

# handoff.md ist temporär — nicht versehentlich committen
echo "handoff.md" >> .gitignore

git add .claude/ docs/ .gitignore
git commit -m "chore: agentic workflow scaffold"
```

### Global vs. projekt-lokal

- **Global** (`~/.claude/skills/`) — über alle Projekte verfügbar, nicht versioniert. Gut für den Solo-Einstieg.
- **Projekt-lokal** (`.claude/skills/`) — im Repo versioniert, teambar, per Fork anpassbar. **Das ist für den Workshop und Team-Setups die bessere Wahl.**

### Branch-Scope und Migration

Neue Arbeit lebt unter `docs/work/<branch-scope>/`. Der Scope kommt aus
dem aktuellen Git-Branch: `main` bleibt `main`, `master` bleibt `master`,
`feature/f1234-user-import` wird zu `f1234-user-import`.

Wichtig:

- Lege den Feature-Branch **vor** `/plan` an. Wer auf `main` plant,
  bekommt bewusst `docs/work/main/`.
- Ein Branch hat genau einen aktiven Work-Plan:
  `docs/work/<branch-scope>/plan.md`.
- Wenn ein Branch umbenannt wird, benenne auch
  `docs/work/<old-scope>/` um. Die Skills raten nicht über andere
  Work-Ordner.
- Alte Artefakte aus `docs/plans/` und `docs/task-log/` werden nicht
  automatisch gelesen. Migriere sie einmalig in den passenden
  `docs/work/<branch-scope>/`-Ordner.

Beispiel-Migration:

```bash
mkdir -p docs/work/f1234-user-import/task-log
git mv docs/plans/user-import.md docs/work/f1234-user-import/plan.md
git mv docs/task-log/task-*.md docs/work/f1234-user-import/task-log/
```

### Trennung: Tool-Config vs. Prozess-Artefakte

Wichtig für das Mental Model:

- **`.claude/`** ist Tool-Konfiguration — Skills und `settings.json`. Bleibt klein, bleibt Claude-Code-spezifisch.
- **`docs/`** ist das Prozess-Gedächtnis des Projekts — tool-agnostisch, sprechend benannt, lesbar auch ohne Claude Code:
  - `docs/specs/` — was gebaut werden soll und warum
  - `docs/work/<branch-scope>/plan.md` — Reihenfolge und Scope für den aktuellen Branch
  - `docs/work/<branch-scope>/task-log/` — was tatsächlich passiert ist (Task-Summaries)

Task-Summaries gehören **nicht** in `.claude/` — sie sind Projekt-Dokumentation, keine Tool-Config. Wenn das Team morgen auf Cursor oder Codex wechselt, wandert der Task-Log mit, die Skills nicht.

---

## Übersicht

| Skill         | Typ           | Phase                                              | Trigger                                                                  |
| ------------- | ------------- | -------------------------------------------------- | ------------------------------------------------------------------------ |
| `/plan`       | Routine       | Spec → Plan (vor Task-Beginn)                      | "Plan spec X" / "Schneide spec X in Tasks"                               |
| `/start-task` | Routine       | Task-Beginn                                        | "Starte Task N"                                                          |
| `/wrap-up`    | Routine       | Task-Ende (DONE oder BLOCKED), auch mehrfach       | "Bin fertig" / "Task blockiert, re-plan"                                 |
| `/commit`     | Routine       | Abschluss eines Tasks nach `/wrap-up`              | "Commit Task N"                                                          |
| `/handoff`    | **Exception** | Context knapp *vor* Task-Ende, oder bewusste Pause | "Context wird knapp, Übergabe vorbereiten" / "Ich pausiere hier manuell" |
| `/review`     | Routine       | Zwischen `/wrap-up` und `/commit`, oder vor PR     | "Review bitte" / "Review full"                                           |

**Wichtig — Routine vs. Exception:** `/wrap-up` + `/commit` sind der Normalabschluss jedes Tasks, `/handoff` die Ausnahme. Im Happy-Path kommt `/handoff` nie zum Einsatz. Du brauchst ihn nur, wenn (a) der Context-Verbrauch kritisch wird, bevor du den Task fertig hast, oder (b) du einen Task bewusst pausierst, um ihn manuell nachzuarbeiten. Beide Fälle sind Spezialfälle — in der Summe deutlich seltener als `/wrap-up`.

**Minimales Setup:** `/wrap-up` allein bringt schon viel Wert — die Log-Datei entsteht, der manuelle `git commit` klappt danach mit Copy/Paste. `/commit` macht aus dem Paar eine klickfertige Einheit und erzwingt, dass der Staging-Satz 1:1 aus dem Log kommt. Der Rest ist optional und addiert sich inkrementell.

**Empfohlene Reihenfolge beim Einführen:** `/wrap-up` → `/commit` → `/start-task` → `/plan` → `/review` → `/handoff`
*(Der Exception-Skill `/handoff` zuletzt — wer die Routine-Skills nicht nutzt, braucht die Ausnahme erst recht nicht. `/plan` kommt bewusst erst nach `/start-task`: die Task-Seed-Kette trägt bereits ohne ihn, er veredelt sie nur um das front-loaded Sizing. `/commit` direkt nach `/wrap-up`, weil die beiden als Paar die meiste Ergonomie gewinnen.)*

**Bewusst kein eigener Skill:**
- **Re-Planning** ist in `/wrap-up` integriert. Wenn ein Task BLOCKED endet, liefert `/wrap-up` zusätzlich eine Escalation-Bewertung und einen Re-Plan-Vorschlag. Ein separater `/replan`-Skill wäre doppelt gemoppelt — ein BLOCKED-Task ohne Re-Plan-Gedanken ist eh sinnlos.
- **Einfaches Debugging** (klarer Stacktrace, reproduzierbar) läuft über die normale Task-Tool-Delegation an einen Subagenten — kein Skill nötig.
- **Exploratives Debugging / Isolations-Experimente** (eigener Nebenkriegsschauplatz, der später zurückgekoppelt werden soll) passiert auf Tool-Ebene, nicht auf Skill-Ebene. Siehe Abschnitt *Isolations-Experimente — ohne eigenen Skill* weiter unten — die Entscheidung zwischen neuer Instanz, `/handoff`, `/branch`, Rewind und ephemerer Frage ist ein Senior-Call.

### /wrap-up vs. /handoff — wann was?

|               | `/wrap-up` (+ `/commit`)                                     | `/handoff`                                                   |
| ------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Situation** | Task ist fertig (oder blockiert)                             | Task ist nicht fertig, aber Context wird knapp               |
| **Ergebnis**  | Task-Summary im Repo, von `/commit` gemeinsam mit Code committet | Temporäre `handoff.md` für die nächste Session               |
| **Danach**    | Nächster Task                                                | Gleicher Task fortsetzen in frischer Session                 |
| **Datei**     | `docs/work/<branch-scope>/task-log/task-{N}-{slug}.md` (persistent) | `handoff.md` im Projekt-Root (temporär, nach Erfolg löschen) |
| **Analogie**  | Schichtprotokoll + Übergabe zum Commit                       | Staffelstab                                                  |

### Der Closing-Flow im Detail

`/wrap-up N` schreibt oder **erweitert** `docs/work/<branch-scope>/task-log/task-{N}-{slug}.md`. Wird der Skill mehrfach für denselben Task aufgerufen (egal in welcher Session), merged er die neuen Findings in dieselbe Datei — keine Overwrites, kein Datenverlust, kein Date-in-Filename-Streit. Erst `/commit N` zieht den Schlussstrich: Skill liest das Log, baut Staging-Liste und Commit-Message daraus auf, zeigt den Plan, wartet auf Bestätigung, führt dann `git add` + `git commit` aus. Für DONE ein `task-N:`-Commit, für BLOCKED mit Re-Plan ein `replan:`-Commit.

Damit ergeben sich mehrere legitime Rhythmen:

- **Schnell** — `/start-task N` → Arbeit → `/wrap-up N` → `/commit N` → `/start-task N+1`.
- **Mit Review** — `/start-task N` → Arbeit → `/wrap-up N` → `/review` → Fixes in frischer Session → `/wrap-up N` (merged) → `/commit N`.
- **Über mehrere Sessions** — Session A: Teilarbeit + `/wrap-up N`. Session B: Rest + `/wrap-up N` (merged). `/commit N` dann wo es passt.

Die Freiheit liegt im Split zwischen „Protokoll erweitern" und „committen". Solange kein Zwischen-Commit dazwischenfunkt, bleibt alles in einem atomaren Commit pro Task.

---

## 1. /plan

Nimmt eine Spec (aus `docs/specs/`, Chat oder Issue) und schlägt einen passend geschnittenen Task-Plan für `docs/work/<branch-scope>/plan.md` vor. Die Slicing-Regeln sind so gewählt, dass Plan-Entry und späterer `/commit`-Commit denselben Standard teilen — *ein Task = ein kohärenter, testbarer Commit*.

**Datei:** `.claude/skills/plan/SKILL.md` · [im Repo ansehen](./skills/plan/SKILL.md)

````markdown
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

Before locating or writing plan artifacts, determine the active work root:

1. Run `git branch --show-current`.
2. If the branch name is empty (detached HEAD), stop and ask the user to
   switch to a branch before planning task work.
3. Derive `<scope>` from the branch name:
   - `main` stays `main`; `master` stays `master`.
   - Otherwise take the part after the final slash, so
     `feature/f1234-user-import` becomes `f1234-user-import`.
   - Normalize to lowercase kebab-case: replace characters outside
     `a-z`, `0-9`, `.`, `_`, and `-` with `-`, collapse repeated `-`,
     and trim leading/trailing punctuation.
4. Use `docs/work/<scope>/` as the work root.

Do not infer scope from other `docs/work/*` directories. If a branch is
renamed, rename the matching `docs/work/<old-scope>/` directory in the
same commit or keep using the old branch name. Legacy artifacts in
`docs/plans/` and `docs/task-log/` must be migrated before using the
scoped workflow.

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
   `/wrap-up`, `/commit`, `/handoff`) can keep the fast daily shape
   (`/start-task N`) while avoiding collisions between parallel
   worktrees. `task-N-{slug}.md` only has to be unique inside
   `docs/work/<scope>/task-log/`.

4. **Propose a task breakdown** following the rules below.
   Present it to the user **before** writing any file.

5. **Wait for user approval.** Only then write to
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
> (quick per-task, full before a PR) between wrap-up and commit;
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
3. The plan now feeds `/start-task N` for execution.
````

### Warum funktioniert das?

Das Sizing-Kriterium hier ist dasselbe, das `/wrap-up` + `/commit` später durchsetzen: *ein Task = ein zusammenhängender, getesteter Commit*. Plan-Entry und Commit-SHA beschreiben dieselbe Einheit, nur an unterschiedlichen Punkten in der Zeit. Das hat drei praktische Effekte:

- **Schlechtes Sizing fällt beim Schreiben auf.** Wer die Acceptance leer lassen muss, merkt sofort: der Task hat keinen testbaren Kern — zu groß oder zu vage.
- **Jeder nächste Task startet auf validiertem Boden.** Jeder Baustein trägt seinen eigenen Beweis; Folgeschritte bauen auf etablierten, nicht bloß vermuteten Zuständen auf. Die Acceptance wird zum Review-Guard für den darauffolgenden Task.
- **„Testing am Ende" fällt aus.** Das Anti-Pattern „erst baue ich vier Dinge, dann mache ich einen Test-Task drauf" wird durch die Regel *keine Standalone-Test-Tasks* explizit verboten — Tests leben dort, wo sie etwas validieren, nicht in einer eigenen Aufräum-Phase.

Die AC-ID-Konvention (`T{N}-AC-{NN}`) verschärft diesen Effekt zusätzlich: jeder Acceptance-Punkt muss ID-würdig formulierbar sein — so präzise, dass „cover T3-AC-04" drei Wochen später noch eindeutig referenziert. Bullets, die das nicht aushalten, sind keine Acceptance, sondern Hoffnungen, und das wird beim Schreiben sichtbar. Gleichzeitig werden die IDs zur Klammer durch den gesamten Lifecycle: Test-Plan-Targets in `/start-task`, Coverage-Status pro Session in `/wrap-up`, Body-Referenzen bei Teilabdeckung in `/commit`, Finding-Anker in `/review`. Acceptance hört damit auf, ein einmaliges Plan-Artefakt zu sein, und wird zur durchgehenden Coverage-Surface mit stabilen Bezugspunkten.

Was das Per-Task-Sizing strukturell nicht abdeckt — Invarianten zwischen Tasks, die kein einzelner allein beweisen kann (Audit-Log-Eindeutigkeit, Single-Clock über Module hinweg, R-Regeln, die mehrere Subsysteme gleichzeitig binden) — fängt die `Cross-Cutting Acceptance`-Sektion am Plan-Ende auf. Sie hat eigene `XC-NN`-IDs und pro Item eine `Touches:`-Liste, damit Trust-Invarianten eine eigene Heimat bekommen, ohne das Per-Task-Sizing zu verwässern. Bewusst geprüft wird sie nicht in jedem `/start-task` (das würde das Context-Budget pro Task sprengen), sondern in `/review full` vor einer PR — also genau einmal an der Stelle, an der eine Integrationslücke noch billig zu reparieren ist.

Das Muster ist in vergleichbarer Form in Produktions-Agenten (z.B. Brokks `createOrReplaceTaskList`) operationalisiert. Die harten Regeln — ein Ziel pro Task, keine Test-only-Tasks, Diff + Test als ein Commit — haben sich dort bewährt. Die Skill-Version übernimmt den Kern und lässt Brokks Tool-Call-Mechanik (Verbatim-Copy bei Inkremental-Updates, `List<TaskListEntry>`-Strukturierung) weg, die nur in einer Agent-UI sinnvoll ist.

---

## 2. /start-task

Bootstrapped eine neue Task-Session mit dem richtigen Kontext. Verhindert, dass du den Seed-Prompt jedes Mal manuell tippen musst.

**Datei:** `.claude/skills/start-task/SKILL.md` · [im Repo ansehen](./skills/start-task/SKILL.md)

````markdown
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
````

---

## 3. /wrap-up

Schreibt oder **erweitert** die Task-Summary unter `docs/work/<branch-scope>/task-log/`. Das Kern-Skill des gesamten Workflows — sorgt für die Seed-Kette zwischen Tasks. Läuft entweder einmal am Ende (fast path) oder mehrfach über mehrere Sessions, bevor `/commit` den Task schließt.

**Datei:** `.claude/skills/wrap-up/SKILL.md` · [im Repo ansehen](./skills/wrap-up/SKILL.md)

````markdown
---
name: wrap-up
description: Generate or extend a structured task summary
  at the end of a completed or blocked task.
  For BLOCKED tasks, also evaluates escalation
  triggers and proposes a re-plan.
---
# Task Wrap-Up

The task is finished (or has been declared blocked).
Write (or extend) the task summary file at
`docs/work/<scope>/task-log/task-{N}-{slug}.md`.

- `{N}` = task number from the plan
- `{slug}` = short kebab-case description (e.g. `login-service`)
- `<scope>` = derived from the current git branch (see Work scope)

One task gets exactly one log file. No date in the filename —
the date lives in git history (commit date) and optionally in
session markers inside the file.

If the task is NOT finished but the context is filling up,
use `/handoff` instead — this skill is for completed or
blocked tasks only.

## Work scope

Resolve the active work root before reading or writing task logs:

1. Run `git branch --show-current`.
2. If the branch name is empty (detached HEAD), stop and ask the user to
   switch to a branch before writing task logs.
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
work root. Legacy `docs/task-log/` is not an automatic fallback.

## Task identity — `$ARGUMENTS`

Use `$ARGUMENTS` to identify the task being closed
(e.g. `/wrap-up 3` means Task 3). The skill must know
the task number before it writes anything.

Resolution rules, in order:

1. If `$ARGUMENTS` contains a number, use that.
2. Else, if this session was primed by `/start-task N`
   (or an earlier `/wrap-up N` / `/commit N`) and N is
   unambiguous in context, use N.
3. Else, **stop** and tell the user:
   > Task number required. Run as `/wrap-up N`.
   Do not guess, do not scan the plan, do not write a file.

Fresh sessions (review-fix, retroactive wrap-up, cross-session
handoff) always need the explicit argument — session context
alone is not enough.

## Precondition — run BEFORE committing the task's code

Wrap-up must happen **before** the task's code changes are
committed. The intended flow is:

1. Finish the code changes (do NOT commit yet).
2. Run `/wrap-up N` → scoped summary file is written (or extended).
3. Run `/commit N` → commits code + summary together.

If the task's code has already been committed when
`/wrap-up N` is invoked, stop and tell the user:

> Task-N code was already committed as `<hash>`. The
> wrap-up summary belongs in that commit. Either:
>
>   (a) amend the commit to include the summary (only if
>       the commit has not been pushed), or
>
>   (b) land the summary as a separate follow-up commit
>       (`docs: task-N wrap-up summary`) and accept the
>       broken single-commit rule for this task.

Ask the user which option before writing the file, so the
summary lands in the right commit from the start.

## Log-file lookup — merge or fresh

Before writing, check for an existing log:

```
ls docs/work/<scope>/task-log/task-{N}-*.md 2>/dev/null
```

- **No file** — fresh write, normal path.
- **Exactly one file** — read it, **merge** with the new
  session's findings (see merge rules below). Show the user
  the proposed merged file and wait for approval before
  writing.
- **Multiple files** — the filename convention was violated inside
  this work scope. Stop and tell the user; ask which file to extend,
  or let them rename/consolidate manually before continuing.

## Merge rules (when a log file already exists)

Read the existing file, then integrate the new session's
output as follows:

- **Task** (one-sentence summary): keep existing unless the
  new session materially changes scope; if it does, rewrite
  and flag the change.
- **Status**: replace with the current status. If the prior
  status was BLOCKED and the new status is DONE, drop the
  Escalation Assessment and Re-Plan Proposal sections
  entirely (they are historical noise once unblocked).
- **Files Modified**: union the lists. If the same file
  appears in both, keep the most informative reason or
  merge both reasons on one line.
- **Files Read (Context Only)**: union the lists.
- **Key Decisions**: append new decisions under a session
  marker (see below). Do not rewrite prior decisions — they
  are part of the record.
- **Test Evidence**: append new evidence under a session
  marker. Accumulates across sessions.
- **Acceptance Coverage**: union the AC IDs. If an AC was
  partial/skipped in the prior session and is now passed, replace
  it. If it was passed and now regresses, surface that explicitly
  instead of silently downgrading it.
- **Open Issues**: merge; drop issues that are now resolved
  (note them in the session marker if helpful).
- **Context for Next Task**: replace with the current view —
  this is forward-looking, not historical.
- **Git State**: replace with current output of
  `git diff --stat` and `git status --short`.

### Session marker

When a merge happens, append a short marker to the `Key
Decisions` and/or `Test Evidence` sections to preserve
temporal order. Format:

```
— session 2026-04-24
```

Use `date +%Y-%m-%d` to get the date. One marker per
session-contribution, placed before the lines added by
that session. Keeps the log readable without introducing
a new top-level Session heading.

## Base summary structure (always):

### Task
One-sentence summary of what was worked on.

### Status
DONE | BLOCKED
If BLOCKED, explain why and what needs to happen
to unblock. (For in-progress tasks, use `/handoff`.)

### Files Modified
Each file with a one-line description of what
changed and why. Format:
- `path/to/file.ts` (new|modified|deleted) — reason

### Files Read (Context Only)
Files that were read for understanding but NOT
modified. This helps the next session know what
context was used.

### Key Decisions
Technical decisions made during this session and
the reasoning behind them. Include alternatives
that were considered and rejected.

### Test Evidence
What was tested and how. Include:
- Test commands run and their output
- Manual verification steps taken
- Screenshots or log snippets if relevant

### Acceptance Coverage
One line per AC ID from the task's plan block.

Status values:
- `passed` — automated test exists and is green; reference the
  test file/test name or command output.
- `partial` — covered manually, or automated coverage stops short
  of the full AC; explain the gap.
- `skipped` — explicitly not addressed this session; explain why
  and reference a follow-up task if applicable.
- `N/A` — AC was dropped by an approved plan amendment; leave a
  one-line note and keep the ID visible.

If any AC is `skipped` and that was not a deliberate scope decision,
the task is not ready for `/commit N`. Finish the AC or split the
remaining work into a follow-up task before committing.

### Open Issues
Unfinished work, known issues, open questions.
Reference follow-up tasks where applicable.
Format: "Issue description (→ Task N)"

### Context for Next Task
What the next session needs to know to continue.
Include:
- Key interfaces and their signatures
- State assumptions
- Dependencies between this task and the next
- Any gotchas discovered during implementation

### Git State
Run these commands and include their output:
- `git diff --stat`
- `git status --short`

## Additional sections for BLOCKED tasks only:

If Status is BLOCKED, also evaluate the escalation
triggers and produce a re-plan proposal. Append the
following sections to the summary:

### Escalation Assessment
For each trigger, state: CLEAR | WARNING | TRIGGERED
with evidence.

1. **Scope creep:** `git diff --stat` — are more files
   modified than the plan specified? Which ones are
   outside planned scope?
2. **API changes:** Has any public interface changed
   that was not planned? Check exports, function
   signatures, shared types.
3. **Failed attempts:** How many implementation
   attempts? Check git log for reverts or repeated
   changes to the same files.
4. **Test failures outside scope:** Are tests failing
   in modules not targeted by this task?
   Run the test suite and check.
5. **Explainability:** Can you summarize what this
   task accomplished in 5 bullet points or fewer?
   If not, scope is probably too large.

### Re-Plan Proposal
Based on the assessment, propose:
- What to keep from the current task (already valuable)
- How to split the remaining work into smaller tasks
- Updated task list with revised scope

Then propose an updated plan patch for `docs/work/<scope>/plan.md`.
Do NOT overwrite the old plan — the old version stays
in git history. Write the revision as an edit.

## After generating the summary:

Do **not** commit. The commit is `/commit N`'s job.

Tell the user:

> Summary is ready at `docs/work/<scope>/task-log/task-{N}-{slug}.md`.
> When you are done with this task's work, close it out with
> `/commit {N}` — that reads this log, stages code + summary
> together, and commits with a message derived from the log's
> title and status.
>
> You can run `/wrap-up {N}` again from another session
> before committing — findings are merged into this same
> file.

The single-commit rule still matters: the final committed
summary describes *this exact code state*. `/wrap-up` builds
the summary; `/commit` makes the atomic commit. Keeping them
split lets you extend the summary across sessions without
amend-dance, and the final commit still contains one coherent
story per task.
````

---

## 4. /commit

Liest das Task-Log, baut Staging-Liste und Commit-Message daraus auf, zeigt dem User den Plan und führt nach Bestätigung `git add` + `git commit` aus. Der eine Skill im Kit, der tatsächlich Git-Zustand verändert — deshalb strikt mit Confirmation-Gate.

**Datei:** `.claude/skills/commit/SKILL.md` · [im Repo ansehen](./skills/commit/SKILL.md)

````markdown
---
name: commit
description: Commit a task's code and its wrap-up summary
  together in a single commit. Reads the task log to derive
  staging list and message, shows the plan to the user, then
  executes git add + git commit after confirmation.
---
# Task Commit

The task's wrap-up summary already exists (written by
`/wrap-up N`). Stage and commit the task's code changes
together with the summary file in a single commit.

This skill **executes** `git add` and `git commit` after
showing the user the full plan and waiting for explicit
confirmation. If the user says anything other than a clear
"yes" / "ok" / "commit", abort without running any git
command.

## Work scope

Resolve the active work root before locating the task log:

1. Run `git branch --show-current`.
2. If the branch name is empty (detached HEAD), stop and ask the user to
   switch to a branch before running git commands.
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
work root. Legacy `docs/task-log/` is not an automatic fallback.

## Task identity — `$ARGUMENTS`

Use `$ARGUMENTS` to identify the task being committed
(e.g. `/commit 3` means Task 3). Required.

Resolution rules, in order:

1. If `$ARGUMENTS` contains a number, use that.
2. Else, if this session ran `/wrap-up N` or `/start-task N`
   and N is unambiguous in context, use N.
3. Else, **stop** and tell the user:
   > Task number required. Run as `/commit N`.
   Do not guess. Do not run git commands.

## Workflow

### 1. Locate the log file

```
ls docs/work/<scope>/task-log/task-{N}-*.md
```

- **Exactly one file** — continue.
- **No file** — stop. Tell the user:
  > No wrap-up summary found for Task N. Run `/wrap-up N`
  > first.
- **Multiple files** — stop. Filename convention violated inside this
  work scope; ask the user to consolidate before committing.

### 2. Read the log file

Extract:

- **Title** (from `### Task` — the one-sentence summary).
- **Status** (`DONE` or `BLOCKED`).
- **Files Modified** list — the canonical list of source
  files that should be staged.
- **Acceptance Coverage** — note covered, partial, skipped, or
  deferred AC IDs for the optional commit body.
- For BLOCKED: note the Re-Plan Proposal if present and
  identify the plan file path referenced.

### 3. Check current git state

```
git status --short
git diff --stat
```

Reconcile against the Files Modified list:

- Files listed in the log that are **missing** from the
  working tree / index → flag to user. Possible causes:
  file was reverted, already committed separately, or log
  is stale.
- Files present in the working tree that are **not** in
  the log → flag to user. Either the log is incomplete
  (re-run `/wrap-up N` to refresh) or these files belong
  to a different task.
- Files already staged that are **not** in the log → flag.
  The user might have staged something by hand; ask before
  sweeping it into the task commit.

Do not auto-resolve any of these — surface them and wait.

### 4. Build the staging list and commit message

**Staging list:**

- The log file: `docs/work/<scope>/task-log/task-{N}-{slug}.md`
- Every file in the log's `Files Modified` section that
  exists in the working tree or index.
- For BLOCKED with Re-Plan: also include
  `docs/work/<scope>/plan.md` (the updated plan).

**Commit message template:**

- **DONE:** `task-N: <title from log>`
- **BLOCKED with re-plan:** `replan: <reason> (task-N blocked)`
  The `<reason>` is a short human-readable phrase derived
  from the Re-Plan Proposal — ask the user if ambiguous.
- **BLOCKED without re-plan:** `task-N: blocked — <reason>`

Keep messages short (≤ 72 chars for the subject line). No
automatic body unless the user asks for one or the Acceptance
Coverage section contains anything other than `passed`.

When a body is warranted, keep it short and traceable:

```
Covers T{N}-AC-01..05
Partial T{N}-AC-06: <reason>
Defers T{N}-AC-07 -> Task M
```

Prefer `Covers` over `Closes`; AC IDs are not issue IDs.

### 5. Show the commit plan

Present a single block to the user containing:

- Commit message (subject line).
- Files to be staged, one per line, grouped as:
  - `[log]` — the task summary file
  - `[code]` — source files from Files Modified
  - `[plan]` — plan file (BLOCKED+replan only)
- Any discrepancies from step 3 (missing / extra / already-staged
  files) with a short note each.
- The exact commands that will run:
  ```
  git add <file1> <file2> ...
  git commit -m "<message>"
  # or: git commit -m "<message>" -m "<body>" when a body is used
  ```

End with a confirmation prompt, e.g.:

> Commit Task N as shown above? (yes / no / edit message)

### 6. Act on the response

- **`yes` / `ok` / `commit`** — run `git add <files>` then
  `git commit -m "<message>"` (plus `-m "<body>"` if the shown
  plan included a body). Show the resulting commit hash and a
  one-line confirmation.
- **`edit message`** — accept a revised message from the
  user and re-show the plan for confirmation. Do not
  commit until re-confirmed.
- **`no`** or anything ambiguous — abort. Do not stage,
  do not commit. Tell the user nothing was changed.

### 7. After a successful commit

Tell the user:

> Committed as `<hash>`. Task N is closed.
>
> Next: `/start-task N+1` to begin the next task, or
> `/review` for a quick per-task review, or
> `/review full` before opening a PR.

Do **not** push. Pushing is an explicit human action.

## What this skill does not do

- It does not run tests. Test evidence lives in the wrap-up.
- It does not amend or rewrite history. If the user needs
  to amend a prior commit, they do that by hand.
- It does not push to a remote.
- It does not sweep files with `git add -A` or `git add .`.
  Every path in the staging list is explicit and traceable
  to the log.
````

### Warum die Trennung wrap-up / commit?

Der Grund, dass das zwei Skills sind und nicht einer, liegt in der Realität gemischter Session-Rhythmen. Wer alles in einer Session macht, könnte sie zusammenfassen — aber sobald ein Review in einer zweiten Session dazwischenkommt oder Arbeit über Tage gestreckt wird, braucht man die Freiheit, das Protokoll mehrfach zu erweitern, bevor der atomare Commit fällt. Das Paar macht beide Muster sauber: Schnell-Rhythmus ist `wrap-up` → `commit` direkt hintereinander; Spread-Rhythmus ist `wrap-up` → (Pause, Review, mehr Arbeit) → `wrap-up` → `commit`. Keine Overwrites, keine stillen Datenverluste, keine Amend-Rituale.

Die Acceptance-Coverage-Sektion in der Wrap-up-Summary nutzt genau diese Mehrsessionsfähigkeit aus: AC-Status können sich zwischen Sessions verändern (`partial` → `passed`, oder umgekehrt als Regression-Flag), die Merge-Regel erkennt das und zwingt zum sichtbaren Surface-Up statt zu stillem Überschreiben. `/commit` schaltet seinen optionalen Body-Block automatisch nur dann an, wenn die Coverage etwas anderes als komplett `passed` zeigt — Traceability genau dort, wo sie Wert bringt, und still, wenn nicht.

---

## 5. /handoff

> **Exception-Skill, kein Routine-Baustein.** Der Normalabschluss eines Tasks ist `/wrap-up`. `/handoff` ist nur für zwei Fälle gedacht: (a) Context wird knapp *bevor* der Task fertig ist, oder (b) du pausierst den Task bewusst, weil manuelle Nacharbeit ansteht und du später in frischer Session weitermachst.

Extrahiert den relevanten Kontext aus einer laufenden Session in ein temporäres Übergabe-Dokument. Die neue Session liest die `handoff.md` und setzt die Arbeit ohne Explorations-Overhead fort.

**Datei:** `.claude/skills/handoff/SKILL.md` · [im Repo ansehen](./skills/handoff/SKILL.md)

````markdown
---
name: handoff
description: Extract relevant context from the current 
  session into a temporary handoff document for seamless 
  continuation in a fresh session.
---
# Session Handoff

The user's context window is filling up (typically 40-50%).
The current task is NOT finished — analysis is done but 
implementation remains. Create a handoff document that 
enables a fresh session to continue without re-exploration.

## Create `handoff.md` in the project root.

### Document structure:

#### Background
2-3 sentences: What is the task? What is the goal?
No history, no conversation recap — just the objective.

#### Already Done
What was already implemented in THIS session or earlier.
Include concrete code references (file, method, pattern).
This serves as a **few-shot example** for the remaining 
work — the next session will use it to understand the 
expected solution style.

#### TODO
For each remaining fix/change:

1. **Title** — one-line description
2. **File and method** — exact location with line numbers
3. **Current code** — the actual snippet that needs changing
4. **Problem** — why it's wrong (one sentence)
5. **Proposed fix** — concrete code or pseudocode
6. **Complexity** — Very low / Low / Medium / High
7. **Risk** — None / Performance / Breaking change / etc.

Be specific. Vague TODOs waste context in the next session.

#### Key Files to Read
Table format:
| File | Why |
|------|-----|
Each entry: file path + one sentence explaining what 
the next session needs from this file.

Only include files that are NECESSARY for the remaining 
work. Not everything that was read — only what matters.

#### Architecture Context
If the task requires understanding non-obvious 
relationships between components, include a brief 
sketch. Example:


MultiAnalyzer
├── delegates: Map<Language, IAnalyzer>
└── templateAnalyzers: Collection<ITemplateAnalyzer>


Only include this if it saves the next session from 
having to rediscover the architecture.

#### Complexity Summary
Table format:
| Fix | Complexity | Risk |
|-----|------------|------|

### What NOT to include:
- Conversation history
- Rejected approaches or dead ends
- Files that were read but aren't needed for the fix
- Broad project context that's already in CLAUDE.md

### Guiding principle:
**Maximum signal density.** Every line in handoff.md 
should save the next session from doing redundant work.
If a line doesn't directly help with implementation, 
cut it.

## After creating handoff.md:

1. Tell the user: "handoff.md is ready. In the new 
   session: `/clear` → then say 'Read handoff.md 
   and follow the instructions.'"
2. Do NOT commit handoff.md — it is temporary.
3. Remind the user to delete handoff.md after the 
   task is completed successfully.
````

### Warum funktioniert das?

Ein Praxisbeispiel aus einer realen Brokk-Session — drei Fixes in `ContextAgent.java` für Angular Template Support:

```
Session 1 (Analyse)                    Session 2 (Implementierung)
┌─────────────────────┐                ┌─────────────────────┐
│ Exploration         │                │ /clear              │
│ Architektur-Analyse │                │ "Lese handoff.md"   │
│ Fix-Strategie       │                │ → Sofort produktiv  │
│                     │                │ → Alle 3 Fixes      │
│ Context: 50% ──────►│── handoff.md ─►│ → BUILD SUCCESSFUL  │
│ (nur Analyse!)      │                │                     │
│                     │                │ Context: 28%        │
│                     │                │ (Analyse + Impl!)   │
└─────────────────────┘                └─────────────────────┘
```

Die handoff.md hatte 154 Zeilen und enthielt:

- **Already Done** — ein bereits implementierter Fix als Referenz-Pattern (implizites Few-Shot)
- **3× TODO** — jeweils mit aktuellem Code, Problem, konkretem Fix-Vorschlag
- **Leseliste** — 6 Dateien mit Begründung, warum jede gelesen werden muss
- **Architektur-Skizze** — `MultiAnalyzer → delegates vs. templateAnalyzers`
- **Komplexitätstabelle** — Fix A: trivial, Fix B: mittel (Performance-Risiko), Fix C: niedrig

Die neue Session las die handoff.md, arbeitete die Leseliste zielgerichtet ab (statt zu suchen), verwendete den Already-Done-Fix als Lösungsmuster, und implementierte alle drei Fixes in 3 Minuten — mit BUILD SUCCESSFUL beim ersten Versuch.

**Context ist ein Budget. Die handoff.md ist Budgetplanung.**

### Industrievalidierung

Sourcegraph Amp hat Session Handoff als **eingebautes Feature** mit eigenem Slash Command. Der Agent erkennt automatisch, wann der Context knapp wird, und bietet die Erstellung eines Handoff-Dokuments an. Das Pattern ist so fundamental, dass professionelle Coding-Agents es als First-Class-Feature behandeln.

---

## 6. /review

Generiert einen Guided Review Brief mit Hotspots, Cross-Task Concerns und Blind Spots.

**Datei:** `.claude/skills/review/SKILL.md` · [im Repo ansehen](./skills/review/SKILL.md)

````markdown
---
name: review
description: Generate a guided review brief. 
  Default is quick mode (hotspots + blind spots only, 
  for per-task reviews). Use 'full' for end-of-feature 
  or pre-PR reviews.
---
# Guided Review

You are a senior code reviewer. You have full git access.
Your job is not to list changes — the developer can read 
diffs. Your job is to compress risk and direct attention.

## Modes

Check `$ARGUMENTS`:

- `/review` or `/review quick` (default) — **Quick mode.** 
  Per-task review. Output: Hotspots + Blind Spots only.
- `/review full` — **Full brief.** End-of-feature or 
  pre-PR review. Output: All sections including 
  Cross-Task Concerns and Confidence Assessment.

Quick mode is the daily driver. Full mode is for the 
moment before the PR leaves the author.

## Review scope — commit range vs. working tree

Before running the workflow, decide **what** is being reviewed.
`/review` has to cover both committed history and work in the
working tree, because `/wrap-up` produces summary + code
*uncommitted by design* — the most common review moment is exactly
*before* that commit goes out.

Check git state first:

- `git status --short` — any uncommitted or staged changes?
- `git log --oneline -10` — recent commit history.

Pick the scope:

- **Working-tree only** (nothing committed yet for the current
  task): review `git diff HEAD` — this covers staged + unstaged
  changes together. Split with `git diff` (unstaged) and
  `git diff --cached` (staged) if that distinction matters.
- **Committed only** (no working-tree changes): review
  `git diff <start-commit>..HEAD`.
- **Mixed** (some commits already landed for the task, more
  changes still in the working tree): review both —
  `git diff <start-commit>..HEAD` for the committed part and
  `git diff HEAD` for what is still pending. Call out the split
  in the output so the user can see which findings belong to
  which slice.

If the user passed an explicit range in `$ARGUMENTS` (e.g.
`/review HEAD~3..HEAD`), honour it verbatim and skip scope
detection.

## Workflow (both modes):

1. **Understand recent history and current state:**
   - `git status --short` — working-tree state
   - `git log --oneline -10`
   - Identify the review scope per the rules above
     - Quick: just the current task (working tree, its
       commits, or both)
     - Full: the whole feature — all its commits plus any
       pending working-tree changes
   - Read commit messages for intent

2. **Review the actual changes:**
   - For committed parts: `git diff <start-commit>..HEAD`
   - For pending parts: `git diff HEAD` (and/or
     `git diff --cached` vs. `git diff` if staged/unstaged
     need to be distinguished)
   - Read modified files in full (not just diffs)
     to understand surrounding context
   - Check if tests were added or updated
   - Check the relevant `docs/work/<scope>/task-log/` entry for
     Acceptance Coverage and AC IDs when reviewing a task with a
     wrap-up log. Derive `<scope>` from the current git branch the
     same way as `/start-task`.

3. **Look deeper if something seems off:**
   - `git log -p <file>` for evolution of suspicious files
   - `git blame` to understand who/what introduced patterns
   - Check `docs/work/<scope>/task-log/` for task summaries that
     explain intent.

4. **Full mode only — check for cross-task patterns:**
   - Are the same files modified across multiple tasks?
   - Is complexity growing in one area?
   - Are there emerging God-classes or God-modules?
   - Read the active plan at `docs/work/<scope>/plan.md`. If it has a
     `Cross-Cutting Acceptance` section, check each `XC-NN` against
     task logs and tests.

   Cross-cutting check statuses:
   - `passed` — at least one test or task log asserts the full
     invariant.
   - `unverified` — relevant modules were not touched, or no
     evidence exists yet.
   - `gap` — contributing tasks were touched but no evidence
     covers the invariant.

## Quick mode output:

### Hotspots
Ranked by risk. Each hotspot has:
- Risk level: [HIGH] [MEDIUM] [LOW]
- AC ID it touches (`T{N}-AC-{NN}` or `XC-NN`), or `no AC` if
  the finding is outside the stated acceptance surface
- File and line reference
- What the concern is
- What to check or consider

### Blind Spots
Areas that are likely relevant but were NOT 
inspected or modified. Be specific:
- Related test files not updated
- Documentation not adjusted
- Config files that might need changes
- Adjacent modules that depend on changed code
- Error handling paths not covered

For each blind spot, explain WHY it might matter.

## Full mode output:

### 1. Summary
What was done (1-3 sentences). 
Files changed with paths for quick navigation.

### 2. Hotspots
(as in quick mode)

### 3. Cross-Cutting Acceptance Check
If the active plan has a `Cross-Cutting Acceptance` section,
report each `XC-NN`:

- Evidence from task logs and tests.
- `passed` if the full invariant is asserted.
- `unverified` if the contributing modules were not touched or no
  final integration task has run yet.
- `gap` if contributing tasks were touched but no evidence covers
  the invariant.

A `gap` is a strong signal that an integration test or follow-up
task is missing.

### 4. Cross-Task Concerns
Patterns across recent commits that only become 
visible when looking at the bigger picture:
- Repeated modifications to the same file
- Growing complexity in one module
- Inconsistent patterns across tasks
- Architectural drift from the original plan

### 5. Blind Spots
(as in quick mode)

### 6. Confidence Assessment
Your honest assessment of:
- Functional correctness
- Error handling completeness
- Consistency with existing codebase patterns
- Test coverage adequacy

### 7. Recommended Actions
Concrete next steps, if any:
- Things to fix before merging
- Things to verify manually
- Things acceptable as follow-up tasks
````

---

## Isolations-Experimente — ohne eigenen Skill

Manchmal will man einen Nebenkriegsschauplatz aufmachen: einen Bug isoliert reproduzieren, eine Alternative durchspielen, eine Frage stellen, deren Antwort den Hauptkontext nicht belasten soll. Ursprünglich war dafür ein `/debug-fork`-Skill gedacht — er ist bewusst wieder rausgeflogen. Der Grund: **Isolation passiert auf Tool-Ebene, nicht auf Skill-Ebene.** Ein Skill kann dem Agenten nur sagen, er möge sich isoliert verhalten — er kann die Session nicht tatsächlich forken. Die eigentliche Isolation muss Claude Code selbst liefern, und dafür gibt es mehrere native Mechanismen mit unterschiedlichen Kontext-Semantiken.

**Die fünf Varianten im Überblick:**

- **Neue Agenteninstanz** — startet kontextlos. Passt für Fragen, bei denen der aktuelle Kontext keinen Mehrwert hätte.
- **`/handoff` → neue Session** — bewusster, kuratierter Kontext-Transfer. Passt, wenn der Ausflug handfeste Artefakte produziert (Bugfix, Prototyp), die manuell in den Haupt-Ast zurückgemeldet werden.
- **`/branch`** (Claude Code nativ) — zweigt die Session mit vollem Kontext ab, der Haupt-Ast bleibt unberührt. Meistens die richtige Wahl, wenn man zurückkoppeln will, ohne vorher manuell den Kontext auswählen zu müssen.
- **Frage + Rewind** — Frage stellen, Antwort lesen, Konversation zurückdrehen. Passt für kurze Recherche-Fragen, deren Antwort den Hauptkontext nicht aufblähen soll. (Achtung: Rewind spult die Konversation zurück, **nicht die Dateiänderungen** — wenn der Agent während der Frage etwas geschrieben hat, bleibt das auf der Platte.)
- **Ephemere Frage** — voller Kontext verfügbar, aber die Antwort landet nicht im Konversations-Kontext. Passt für schnelle Nachfragen, deren Antwort man nur kurz braucht, ohne den Folgeverlauf zu vergiften.

**Leitfragen für die Wahl:**

1. *Wie viel Kontext brauche ich am Start?* — leer, voll, oder kuratiert?
2. *Will ich das Ergebnis zurückkoppeln?* — wenn ja: `/branch` oder `/handoff`. Wenn nein: ephemere Frage, Rewind oder neue Instanz.

Keine dieser Varianten lohnt einen eigenen Skill — sie sind Tool-Features und jede Automatisierung der Wahl zwischen ihnen würde genau die Senior-Entscheidung wegnehmen, die der Skill-Kit-Ansatz ausdrücklich beim Menschen behalten will.

---

## Anpassung und Erweiterung

Die Skills sind bewusst als Instruktionen formuliert, nicht als Code. Das heißt: du kannst sie jederzeit anpassen, ohne etwas zu kompilieren oder zu deployen. Einfach die `SKILL.md` editieren.

**Typische Anpassungen:**

- Summary-Format ändern (z.B. andere Felder, anderes Schema)
- Review-Kriterien projektspezifisch erweitern (z.B. Security-Checks für Fintech)
- Escalation-Trigger anpassen (z.B. strengere Schwellen für regulierte Codebases)
- Commit-Message-Prefixes an Team-Konventionen anpassen
- Handoff-Struktur erweitern (z.B. mit Dependency-Graph oder API-Contracts)

**Eigene Skills bauen:**

Das Muster ist immer gleich: YAML-Frontmatter mit `name` und `description`, dann Markdown mit Instruktionen. `$ARGUMENTS` enthält alles was nach dem Slash-Command getippt wird (z.B. `/start-task 3` → `$ARGUMENTS = "3"`).

```
.claude/skills/<name>/SKILL.md
```

Der `name` im Frontmatter wird automatisch zum `/slash-command`.

---

## Lizenz & Beiträge

MIT — siehe [LICENSE](./LICENSE). Fork, passe an, teile zurück. Issues und Discussions sind der richtige Ort für Feedback aus der Praxis.
