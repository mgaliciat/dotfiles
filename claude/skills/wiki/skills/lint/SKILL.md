---
name: lint
description: Health-check the Obsidian wiki for rot — missing frontmatter, contradictions, orphans, stale claims, missing cross-refs, gaps. Report, don't fix without confirming. Use when the user says "lint wiki", "/wiki:lint", or asks to check the wiki for rot.
---

# wiki · lint

**First read `~/.claude/skills/wiki/ENGINE.md`** (the shared engine: OKF frontmatter,
`log.md` format, links rule, "before any workflow"). Then run this workflow.

Health-check that keeps the wiki from rotting. **Report, don't fix without
confirming.** Prepend a `**Lint**` bullet under today's date in `log.md`
summarizing findings.

- **Frontmatter (the OKF §9 hard rule): a page with unparseable frontmatter or a missing/empty `type`.** This is the only failure that makes the bundle non-conformant — flag it first.
- Contradictions between pages.
- Stale claims (source note is old, or was contradicted by a later one).
- Orphan pages (no backlinks — check the MCP's `backlinks` field — or absent from `index.md`).
- Missing cross-refs (a page names a topic that has its own page but doesn't link it). Asymmetric links count.
- Drift between a page's `description` frontmatter and its `index.md` one-liner (should match — §6).
- Gaps (topics frequent in `Bitacora/` with no page yet).
