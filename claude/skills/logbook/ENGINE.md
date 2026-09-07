# Logbook (OpenKnowledge) — engine

Shared spec for the `logbook` plugin's synthesis skills (`/logbook:ingest`,
`/logbook:query`, `/logbook:lint`). **Each of those reads this file first**, then
runs its workflow. Everything common — where the contract lives, which tools to
use, the layers, the watermark — is here once; the skills hold only their own
steps. The fourth skill, `/logbook:entry`, is the capture gate and is
self-contained on purpose: it fires from a commit hook and does not read this file.

`/logbook:entry` captures work as immutable per-invocation notes, but capture is
write-only: notes pile up, they never come back synthesized. The other three are
the read/synthesis layer on top. Raw stays messy on purpose; the wiki is the
ordered layer, and the agent — not the human — keeps it ordered.

**Vault paths, not skill names.** The raw layer is `entries/` and the synthesized
one `wiki/`; `logbook` is the name of the tooling and never a path. `entries/` was
`bitacora/` until 2026-09-06 — a folder `move` carried all 199 notes and rewrote
the inbound links, so nothing outside these docs still says the old name.

Pattern: **the vault is the source of truth, the LLM is a processing layer.** The
knowledge should *compound*, not just accumulate.

## The contract lives in the vault, not here

**Read `wiki/CLAUDE.md` (in the vault) before every workflow.** It is the per-vault
config and it **outranks this file** on everything it covers: the type vocabulary,
the frontmatter fields, the repo-tag alias table, the index and log formats, the
external-research procedure, the human/agent split, the cadence. This file is the
engine; that one is the configuration, and it is versioned inside the vault so it
travels with the content rather than with these dotfiles.

If `wiki/CLAUDE.md` is missing you are pointed at the wrong project — stop and say
so. Do **not** bootstrap a replacement from memory: a hand-written contract that
disagrees with 200 existing documents is worse than no contract.

Two things it defers to in turn:

- **OKF semantics** — the `okf-knowledge-base` skill (installed separately, ships
  with OpenKnowledge). It carries OKF v0.2: reserved files, the open type
  vocabulary, provenance (`generated` vs `verified`, ISO 8601 with an explicit UTC
  offset), `sources`, and what the `okf` plugin's warnings mean. Read it instead of
  re-deriving the spec here. This engine only records where *this* vault
  deliberately sits: it still carries the legacy `timestamp` field rather than
  v0.2 `generated.at`, and migrating a page is a decision, not a cleanup — never
  invent provenance for a page you did not generate.
- **The `.ok/okf/*.schema.json` files** in the vault, for exact field contracts.
  Generated; read them, never edit them.

## Tools: use the MCP, not the filesystem

The vault is remote (an HTTP OpenKnowledge server). There is no local copy, so
`Read`/`Grep`/`Glob` cannot reach it at all — and even where a project has an
`.ok/` on disk, the native tools skip the frontmatter, backlinks, unresolved
comments and attribution that `exec` returns per file. The mapping:

| Need | Tool |
|---|---|
| List, `cat`, `grep`, `find` over the vault | `exec` (read-only allowlist, one pipe per call) |
| Ranked lookup by title/body | `search` (lexical BM25 + recency; semantic is off) |
| Create a document | `write` (`document`, or `documents` for a batch) |
| Change part of one | `edit` (`find`/`replace`, or a `frontmatter` merge-patch) |
| Backlinks, forward links, dead, orphans, hubs, suggest | `links` |
| Broken links + lint violations in one pass | `audit` |
| Lint one doc, optionally auto-fix | `lint` |
| Who wrote a version, and when | `history` |

**`write` with `position: replace` overwrites the entire body.** That is correct
for a document that does not exist yet and destructive for one that does — it is
how this vault lost its `log.md` once. To change an existing page use `edit`; to
add to one, `write` with an explicit `append`/`prepend`, or `edit` against a
unique anchor. Passing `frontmatter` alongside literal `content` silently forces
`replace`, so never do that to a live page.

`exec` is read-only and is **not a shell**: one command or one pipe, no `&&`, no
`;`, no redirection. Several things = several calls.

## The layers

Authoritative list is `wiki/CLAUDE.md`; this is the shape, so a workflow knows what
it may write to.

- **Raw — immutable. Read, never edit, never move.**
  - `entries/*` — the active gate: one file per invocation, written by
    `/logbook:entry`.
  - `claude_sessions/*` — frozen legacy raw, from before the bitácora. Ingested,
    never appended to; two entry gates produce drift.
- **`sources/*`** — external material captured verbatim (`type: source`), immutable
  after capture, so pages cite a local document and never the live web. Analysis
  does not go here.
- **`specs/*`** — feature specs agreed before implementing.
- **`wiki/<topic>`** — the synthesized layer, one page per concept / service /
  decision / entity / repo. This is the only layer the synthesis skills write to,
  plus `wiki/index.md` and `wiki/log.md`.

## Links

Relative markdown links (`[servicio-x](./servicio-x.md)`, `[nota](../entries/….md)`).
**Never mix in the root-absolute form** `/carpeta/x.md`: prefixing `./` to a
root-style path from a document already inside that folder duplicates the segment
(`wiki/wiki/x.md`) and the link dies silently. A page with no backlink to the raw
note(s) it synthesizes is unfinished.

Links are not decoration here. OpenKnowledge retrieval is a **lexical loop** —
BM25 plus recency plus graph traversal, with semantic search off — so links,
folders, titles and folder descriptions *are* the index. Every link shortens the
next agent's loop.

## index.md and log.md

Both are hand-written and reserved. `wiki/index.md` lists **every** page in the
folder, reusing each page's own `description` verbatim as its one-liner — a partial
index makes pages unreachable for anyone reading the bundle without listing the
directory. `wiki/log.md` is **newest-first**, one `## YYYY-MM-DD: <op> | <summary>`
heading per operation.

**Do not turn on the `okf` plugin's index generation.** Generated indexes are
machine-owned and OpenKnowledge replaces their contents, taking these four
hand-written ones with them.

### The watermark

The most recent **ingest** entry in `wiki/log.md` carries the source range it
processed, and that range **is** the processed marker — it replaces moving files
into a `processed/` folder, which is what keeps the raw immutable. "Since the last
ingest" = every `entries/` note whose timestamp is **≥** the end of that range
(inclusive). Because each note is one immutable file whose name sorts
chronologically, a note that appears after an ingest is always a *new* file with a
later name — never an edit to one already read — so nothing falls in the crack the
old one-file-per-day model had. Re-reading the boundary minute is a safe no-op:
page writes integrate facts, they don't duplicate them.

## Language

**English, everywhere, since 2026-09-06** — every path segment the vault creates
(folders, files, page slugs, template names) and all new prose. The vault's own
`wiki/CLAUDE.md` carries the rule; it outranks this file if the two ever drift.

**The synthesized layers were translated on 2026-09-06** — every `wiki/` page, its
contract and index, plus `guides/`, `runbooks/`, `specs/`, the folder descriptions
and both templates. What stays Spanish is what cannot be rewritten without
destroying its value: the 199 `entries/` notes and the `sources/` captures (raw and
immutable), `claude_sessions/` (frozen), and `wiki/log.md` — append-only history
whose ingest watermarks are read out of it. Tags moved with their pages, so a wiki
tag no longer matches the raw one; `wiki/CLAUDE.md` carries the equivalence table
`ingest` and `lint` need to slice across both.

Translate a page whole or not at all — a half-translated one is worse than a
consistent one. **When you rename for this rule, use `move`**: it rewrites the
inbound links in the same pass, which is the only reason the rule is affordable.
