---
name: wiki-ingest
description: Synthesize the raw Bitacora/ daily notes into cross-linked Wiki/ pages (OKF v0.1) — one per service/concept/decision. Use when the user says "ingest", "sintetiza la bitácora", "wiki ingest", "/wiki-ingest", or asks to process the bitácora into the wiki.
---

# wiki · ingest

**First read `~/.claude/skills/wiki/ENGINE.md`** (the shared engine: OKF frontmatter,
`log.md` format, links rule, "before any workflow", bootstrap). Then run this workflow.

Synthesize `Bitacora/` daily notes not yet processed:

1. Determine the range: the user's, or since the most recent `**Ingest**` bullet in `log.md`.
2. For each service / concept / decision that appears: **create or update** its `Wiki/<topic>.md`. Integrate new facts into the existing page — a running history, never a duplicate page.
3. Give every page OKF frontmatter (see ENGINE.md): set `type` (required), fill `title`/`description`/`resource`/`tags`, and bump `timestamp` on every update. Missing `type` = the page isn't done.
4. Cross-link each page to the others it mentions and to its source daily note(s) (`[[YYYY-MM-DD]]`). A page with no backlink to its source is unfinished. External sources (URLs, docs) go under a `# Citations` section (OKF §8: `[n] [Title](url)`), separate from the bitácora backlinks.
5. Preserve the `#repo/<name>` tag from the bitácora on the service page (also mirror it into frontmatter `tags`), so raw and wiki cross-reference.
6. Update `index.md` (reuse each page's `description` for its one-liner — §6); prepend one `**Ingest**` bullet under today's date in `log.md`.

- **Never move or edit the bitácora.** Unlike Karpathy's `/raw/processed`, "already processed" is tracked in `log.md`, keeping the raw immutable.
- Use judgment on what deserves a page: a one-line unrelated entry doesn't. Log the skip so the next run can reconsider if the topic recurs.
