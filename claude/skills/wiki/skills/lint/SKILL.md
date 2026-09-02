---
name: lint
description: Health-check the OpenKnowledge wiki for rot — OKF conformance, broken links, orphans, contradictions, stale claims, missing cross-refs, gaps. Report, don't fix without confirming. Use when the user says "lint wiki", "/wiki:lint", or asks to check the vault for rot.
---

# wiki · lint

**First read `~/.claude/skills/wiki/ENGINE.md`** (the shared engine: where the
contract lives, which MCP tools to use, the layers, the link rule). Then read the
vault's own `wiki/CLAUDE.md`. Then run this workflow.

Monthly health-check that keeps the wiki from rotting. **Report, don't fix without
confirming** — then prepend one lint entry to `wiki/log.md` summarizing the
findings, including the ones left unfixed.

## Mechanical pass — the tools find these, you don't

- `audit` — lint violations and broken internal links in one call, grouped by the
  file to fix. Its output is capped per file and project-wide, so when it reports
  omitted findings, re-run it scoped to a folder rather than reporting the cap as
  the total.
- `links` with `["dead", "orphans", "hubs", "suggest"]` in one call:
  - **dead** — broken references.
  - **orphans** — unreachable pages. Skills, templates and the root `index.md`
    always surface here and are **not** defects: nothing should link to them.
  - **hubs** — the most-linked pages. One growing on its own is a candidate to
    split into sub-pages.
  - **suggest** — prose mentions not yet wrapped in a link. The cheapest lever for
    densifying the graph; run it over the hubs. Its excerpts are normalized
    snippets, **not** edit-ready literals: re-read the document with `exec`, find
    the real text, then `edit`.
- The OKF hard rule (unparseable frontmatter, or a missing/empty `type`) is the
  only failure that makes the bundle non-conformant. Flag it first.

## Judgment pass — the tools cannot find these

- Contradictions between pages.
- Stale claims: the source note is old, or a later note contradicted it. Prefer
  `history` over guessing at who wrote what and when.
- Pages absent from `wiki/index.md`, and drift between a page's `description`
  frontmatter and its `index.md` one-liner — they must match, `description` being
  the single source.
- Missing cross-refs: a page names a topic that has its own page and doesn't link
  it. Asymmetric links count.
- Gaps: topics frequent in `bitacora/` with no page yet.
- Repo-tag aliases that drifted from the table in `wiki/CLAUDE.md`. The fix lands
  on the wiki page — the raw note is immutable and the watermark depends on it.

## Fixing

`lint({ document, fix: true })` handles the auto-fixable rule violations. Everything
else is a content edit through `edit`, and everything else needs the user's yes
first — a lint that quietly rewrites pages is how a wiki stops being trustworthy.
Renaming a page file is never a small fix: the filename is a link identifier
embedded in other pages and in the log, so a rename means sweeping every backlink
in the same pass, and it is usually right to move the *tag* and leave the file.
