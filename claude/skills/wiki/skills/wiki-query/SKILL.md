---
name: wiki-query
description: Answer a question from the Obsidian wiki without re-deriving from scratch, filing any new knowledge worth keeping. Use when the user says "query wiki", "pregunta a la wiki", "/wiki-query", or asks a question meant to be answered from the wiki.
---

# wiki · query

**First read `~/.claude/skills/wiki/ENGINE.md`** (the shared engine: OKF frontmatter,
`log.md` format, links rule, "before any workflow"). Then run this workflow.

The question is whatever the user passed after the invocation. Answer it from the
wiki — the point of a compounding wiki is not re-deriving from scratch:

1. Search the wiki pages first; drop to the raw `Bitacora/` only if the wiki can't answer.
2. Answer with citations to the pages used (`[[page]]`).
3. If the answer is new knowledge worth keeping, file it — a new page or an addition to an existing one (with OKF frontmatter) — and prepend a `**Query**` bullet under today's date in `log.md`.
