---
name: wiki
description: Maintain an LLM wiki in Obsidian — synthesize the raw Bitacora/ daily notes into cross-linked Wiki/ pages (one per service/concept/decision), answer questions from those pages, and lint the wiki for rot. Karpathy's "LLM wiki" pattern (gist 442a6bf) over the bitacora capture layer. Use when the user says "wiki", "ingest", "sintetiza la bitácora", "query wiki", or "lint wiki".
---

# LLM wiki (Obsidian)

The `bitacora` skill captures work as immutable daily notes, but capture is
write-only: notes pile up, they never come back synthesized. This skill is the
read/synthesis layer on top. Raw stays messy on purpose; the wiki is the ordered
layer, and the agent — not the human — keeps it ordered.

Pattern: **the vault is the source of truth, the LLM is a processing layer.** The
knowledge should *compound*, not just accumulate.

## The three layers

- **Raw (`Bitacora/*`)** — immutable. The daily notes `bitacora` writes. Read, never edit or move.
- **Wiki (`Wiki/<topic>.md`)** — synthesized pages: one per service, concept, decision, entity. The agent writes here.
- **Schema (`Wiki/CLAUDE.md`)** — this vault's conventions and taxonomy. **Read it first** every run; it governs naming, categories, and tag rules. If it's missing, bootstrap it (see below) before doing anything else.

`Wiki/index.md` (catalog by category) and `Wiki/log.md` (append-only audit) live in `Wiki/`.

## Before any workflow

1. Read `Wiki/CLAUDE.md`. It's the per-vault schema — the skill is the engine, that file is the config. Everything below defers to it.
2. If `Wiki/CLAUDE.md`, `Wiki/index.md`, or `Wiki/log.md` don't exist, create the missing ones (bootstrap). A starter schema is at the end of this file.
3. Obsidian closed → the obsidian MCP fails. Say so and fall back to reading/writing the vault files on disk; never silently skip.

## Workflows

### ingest
Synthesize `Bitacora/` daily notes not yet processed.
1. Determine the range: the user's, or since the last `ingest` line in `log.md`.
2. For each service / concept / decision that appears: **create or update** its `Wiki/<topic>.md`. Integrate new facts into the existing page — a running history, never a duplicate page.
3. Cross-link each page to the others it mentions and to its source daily note(s) (`[[YYYY-MM-DD]]`). A page with no backlink to its source is unfinished.
4. Preserve the `#repo/<name>` tag from the bitácora on the service page, so raw and wiki cross-reference.
5. Update `index.md`; append one `ingest` line to `log.md`.
- **Never move or edit the bitácora.** Unlike Karpathy's `/raw/processed`, "already processed" is tracked in `log.md`, keeping the raw immutable.
- Use judgment on what deserves a page: a one-line unrelated entry doesn't. Log the skip so the next run can reconsider if the topic recurs.

### query
Answer a question from the wiki without re-deriving from scratch (the point of a compounding wiki).
1. Search the wiki pages first; drop to the raw only if the wiki can't answer.
2. Answer with citations to the pages used (`[[page]]`).
3. If the answer is new knowledge worth keeping, file it — a new page or an addition to an existing one — and append a `query` line to `log.md`.

### lint
Health-check that keeps the wiki from rotting. **Report, don't fix without confirming.** Append a `lint` line to `log.md` summarizing findings.
- Contradictions between pages.
- Stale claims (source note is old, or was contradicted by a later one).
- Orphan pages (no backlinks — check the MCP's `backlinks` field — or absent from `index.md`).
- Missing cross-refs (a page names a topic that has its own page but doesn't link it). Asymmetric links count.
- Gaps (topics frequent in `Bitacora/` with no page yet).

## log.md format

Append-only, one line per operation, parseable prefix:

```
## [YYYY-MM-DD] ingest | <sources processed>
## [YYYY-MM-DD] query  | <question> -> <page filed, if any>
## [YYYY-MM-DD] lint   | <findings>
```

## Language

Wiki prose in whatever language the vault's notes use (the bitácora is usually Spanish). This SKILL is English because it's versioned in a public repo; the vault content is not.

## Bootstrap: starter Wiki/CLAUDE.md

If `Wiki/CLAUDE.md` is absent, create it with this, then let the user tune the taxonomy:

```markdown
# Wiki — schema

Conventions for the agent that maintains this wiki (see the `wiki` skill for the workflows).

## Conventions
- One page = one topic. Kebab-case filenames: `Wiki/servicio-pagos.md`.
- Every page cross-links: `[[other-page]]` and `[[YYYY-MM-DD]]` back to its source daily note.
- Preserve the bitácora's `#repo/<name>` tag on the matching service page.
- Dense and short: a 500-word synthesized page beats dumping the raw note. Synthesize the *why*.

## index.md
Catalog by category (services / incidents / concepts), each entry `[[page]]` + one-line summary.

## Categories
<!-- tune these to your world: services, incidents, decisions, concepts, people... -->
```
