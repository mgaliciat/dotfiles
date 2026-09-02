---
name: query
description: Answer a question from the OpenKnowledge wiki without re-deriving it from scratch, filing any new knowledge worth keeping. Use when the user says "query wiki", "pregunta a la wiki", "/wiki:query", or asks a question meant to be answered from the vault.
---

# wiki · query

**First read `~/.claude/skills/wiki/ENGINE.md`** (the shared engine: where the
contract lives, which MCP tools to use, the layers, the link rule). Then read the
vault's own `wiki/CLAUDE.md`. Then run this workflow.

The question is whatever the user passed after the invocation. Answer it from the
vault — the point of a compounding wiki is not re-deriving what it already knows:

1. **Search the synthesized layer first.** `search` for ranked hits, `exec` with
   `grep` for exhaustive literal matches — they answer different questions, so run
   both when the first comes back thin. Follow `links` (backlinks and forward
   links) out of whatever you land on: the graph is the index.
2. **Drop to `bitacora/` only when `wiki/` cannot answer**, and say that you did —
   a question the wiki could not answer is itself a finding for `ingest`.
3. **Answer with citations** to the pages used, as relative links.
4. **Say what the vault does not know.** Missing knowledge stated plainly beats a
   confident answer assembled from your own priors — and if the vault contradicts
   an assumption of yours, the vault wins.
5. **Going outside is a separate, gated move.** If the answer needs the live web,
   follow the external-research procedure in the vault's `wiki/CLAUDE.md` — scan
   the vault first, agree a rubric with the user, capture each source in
   `fuentes/` as you fetch it, and only then write. Don't fetch first and tidy up
   after.
6. **File what is worth keeping.** If the answer is durable knowledge, write it —
   a new page, or an addition to an existing one with proper frontmatter — and
   prepend a query entry to `wiki/log.md`. An answer that only exists in this
   session's context is not persisted work.
