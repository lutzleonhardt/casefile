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
