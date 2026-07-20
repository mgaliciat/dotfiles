---
name: ingest
description: Synthesize the raw Bitacora/ per-invocation notes into cross-linked Wiki/ pages (OKF v0.1) — one per service/concept/decision, linking notes that share a topic. Use when the user says "ingest", "sintetiza la bitácora", "wiki ingest", "/wiki:ingest", or asks to process the bitácora into the wiki.
---

# wiki · ingest

**First read `~/.claude/skills/wiki/ENGINE.md`** (the shared engine: OKF frontmatter,
`log.md` format, links rule, "before any workflow", bootstrap). Then run this workflow.

Synthesize `Bitacora/` per-invocation notes not yet processed:

1. Determine the range: the user's, or since the most recent `**Ingest**` bullet in `log.md` — every note with a timestamp **≥** that watermark's end (inclusive; see ENGINE's watermark rule). Each note is one immutable file (`YYYY-MM-DD-HHMM-<repo>.md`), so the set to process is unambiguous.
2. For each service / concept / decision that appears: **create or update** its `Wiki/<topic>.md`. Integrate new facts into the existing page — a running history, never a duplicate page. **Notes carrying the same `#topic`/`#repo` converge on the same page (or cross-linked pages)** and each is backlinked — that's how several invocations on one topic come out linked at ingest.
3. Give every page OKF frontmatter (see ENGINE.md): set `type` (required), fill `title`/`description`/`resource`/`tags`, and bump `timestamp` on every update. Missing `type` = the page isn't done.
4. Cross-link each page to the others it mentions and to its source note(s) (`[[YYYY-MM-DD-HHMM-<repo>]]` — the specific per-invocation files it synthesizes). A page with no backlink to its source is unfinished. External sources (URLs, docs) go under a `# Citations` section (OKF §8: `[n] [Title](url)`), separate from the bitácora backlinks.
5. Preserve the `#repo/<name>` tag from the bitácora on the service page (also mirror it into frontmatter `tags`), so raw and wiki cross-reference.
6. Update `index.md` (reuse each page's `description` for its one-liner — §6); prepend one `**Ingest**` bullet under today's date in `log.md`.

- **Never move or edit the bitácora.** Unlike Karpathy's `/raw/processed`, "already processed" is tracked in `log.md`, keeping the raw immutable.
- Use judgment on what deserves a page: a one-line unrelated entry doesn't. Log the skip so the next run can reconsider if the topic recurs.
