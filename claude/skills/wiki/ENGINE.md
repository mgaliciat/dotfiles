# LLM wiki (OpenKnowledge) — engine

Shared spec for the `wiki` plugin's three skills (`/wiki:ingest`, `/wiki:query`,
`/wiki:lint`). **Each of those skills reads this file first**, then runs its
workflow. Everything common — where the contract lives, which tools to use, the
layers, the watermark — is here once; the skills hold only their own steps.

The `bitacora` skill captures work as immutable per-invocation notes, but capture is
write-only: notes pile up, they never come back synthesized. This plugin is the
read/synthesis layer on top. Raw stays messy on purpose; the wiki is the ordered
layer, and the agent — not the human — keeps it ordered.

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
  - `bitacora/*` — the active gate: one file per invocation, written by the
    `bitacora` skill.
  - `claude_sessions/*` — frozen legacy raw, from before the bitácora. Ingested,
    never appended to; two entry gates produce drift.
- **`fuentes/*`** — external material captured verbatim (`type: source`), immutable
  after capture, so pages cite a local document and never the live web. Analysis
  does not go here.
- **`specs/*`** — feature specs agreed before implementing.
- **`wiki/<topic>`** — the synthesized layer, one page per concept / service /
  decision / entity / repo. This is the only layer these three skills write to,
  plus `wiki/index.md` and `wiki/log.md`.

## Links

Relative markdown links (`[servicio-x](./servicio-x.md)`, `[nota](../bitacora/….md)`).
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
ingest" = every `bitacora/` note whose timestamp is **≥** the end of that range
(inclusive). Because each note is one immutable file whose name sorts
chronologically, a note that appears after an ingest is always a *new* file with a
later name — never an edit to one already read — so nothing falls in the crack the
old one-file-per-day model had. Re-reading the boundary minute is a safe no-op:
page writes integrate facts, they don't duplicate them.

## Language

Vault prose follows the vault (usually Spanish). These skill files are English
because they are versioned in a public repo; the vault's content is not.
