# LLM wiki (Obsidian) — engine

Shared spec for the `wiki` plugin's three skills (`/wiki:ingest`, `/wiki:query`,
`/wiki:lint`). **Each of those skills reads this file first**, then runs its
workflow. Everything common — the layers, the OKF frontmatter, the link rule, the
`log.md` format, the bootstrap — lives here once; the skills hold only their own
steps.

The `bitacora` skill captures work as immutable per-invocation notes, but capture is
write-only: notes pile up, they never come back synthesized. This plugin is the
read/synthesis layer on top. Raw stays messy on purpose; the wiki is the ordered
layer, and the agent — not the human — keeps it ordered.

Pattern: **the vault is the source of truth, the LLM is a processing layer.** The
knowledge should *compound*, not just accumulate.

The `Wiki/` layer follows **OKF v0.1** (Google's Open Knowledge Format — a
directory of markdown files with YAML frontmatter). We adopt it where it adds
mechanical value (typed frontmatter, index/log structure) and deviate where the
Obsidian substrate needs it (links — see below). OKF conformance (§9) is only
three hard rules: parseable frontmatter, a non-empty `type`, and the reserved
files following their structure. Everything else is soft guidance.

## The three layers

- **Raw (`Bitacora/*`)** — immutable. The per-invocation notes `bitacora` writes (one file per invocation, `YYYY-MM-DD-HHMM-<repo>.md`). Read, never edit or move.
- **Wiki (`Wiki/<topic>.md`)** — synthesized "concept" pages (OKF term): one per service, concept, decision, entity. Each carries OKF frontmatter (below). The agent writes here.
- **Schema (`Wiki/CLAUDE.md`)** — this vault's conventions and taxonomy. **Read it first** every run; it governs naming, categories, and tag rules. If it's missing, bootstrap it (see below) before doing anything else.

`Wiki/index.md` (catalog by category — OKF §6) and `Wiki/log.md` (update log — OKF §7) live in `Wiki/`.

## Page frontmatter (OKF v0.1)

Every `Wiki/<topic>.md` starts with YAML frontmatter. This is the one hard OKF
rule (§9): parseable frontmatter with a non-empty `type`. The rest is
*recommended* — it improves `index`/`lint` but never blocks.

```yaml
---
type: service            # REQUIRED. service | incident | decision | concept | entity (soft, open set)
title: Servicio de Pagos # recommended — human display name
description: cobros y conciliación; toca inventario y el gateway X   # one sentence — feeds index.md
resource: https://github.com/org/pagos   # canonical URI of the underlying asset (repo/dashboard/doc)
tags: [repo/pagos]       # mirrors the bitácora's #repo/<name>
timestamp: 2026-07-19    # ISO 8601 last-modified
---
```

- **`type` is the only required field.** Keep the set open — `lint` flags a *missing* type, never an "unknown" one (§9: consumers must tolerate unknown types and preserve unknown keys).
- **`description` is the single source** for that page's one-liner in `index.md` (§6 says index entries SHOULD reuse the concept's `description`) — don't write the summary twice.
- **`resource`** is the OKF field for "the thing this page is about": the service's repo, a dashboard, a doc. Nothing in the wiki captured this before.

## Links: keep `[[wikilinks]]`, do NOT adopt OKF's link syntax

OKF recommends bundle-relative (`/tables/x.md`) or relative (`./x.md`) markdown
links. **We deliberately don't** — Obsidian backlinks, Dataview, and the obsidian
MCP all key off `[[wikilinks]]`; OKF-style links would go dark in all three. This
is *not* a conformance gap: §9's hard rules don't mandate link syntax, and
"consumers MUST tolerate broken links" regardless. Same call the repo makes
elsewhere — the substrate's convention wins over upstream's. A future run must
not "fix" wikilinks into OKF links.

## Before any workflow

1. Read `Wiki/CLAUDE.md`. It's the per-vault schema — the plugin is the engine, that file is the config. Everything defers to it.
2. If `Wiki/CLAUDE.md`, `Wiki/index.md`, or `Wiki/log.md` don't exist, create the missing ones (bootstrap). A starter schema is at the end of this file.
3. Obsidian closed → the obsidian MCP fails. Say so and fall back to reading/writing the vault files on disk; never silently skip.

## log.md format (OKF §7)

Date-grouped, **newest date first**. One `## YYYY-MM-DD` (ISO 8601) heading per
day; under it, one bullet per operation as `* **Label**: description`. OKF's own
example labels are Creation/Update/Initialization — we keep the three operation
labels the wiki needs; §7's structure is `* **<label>**: <text>` with a free-text
label, so they're conformant.

```markdown
# Directory Update Log

## 2026-07-19
* **Ingest**: Bitacora 2026-07-10-0900..2026-07-18-1720 -> updated [[servicio-pagos]], created [[gateway-x]]
* **Lint**: 1 orphan ([[foo]]), 2 missing cross-refs

## 2026-07-11
* **Query**: "how does pagos reconcile?" -> filed [[servicio-pagos#conciliacion]]
```

The **Ingest** bullet's source range is **load-bearing**: it's the processed
watermark (replaces Karpathy's `/raw/processed` move, keeping the bitácora
immutable). "Since the last ingest" = every `Bitacora/` note whose timestamp is
**≥** the most recent `**Ingest**` bullet's end (inclusive boundary). Because each
note is one immutable file per invocation (`YYYY-MM-DD-HHMM-<repo>`, sorts
chronologically), a note that appears after an ingest is always a *new* file with a
later timestamp — never an edit to one already read — so nothing falls in the crack
the old one-file-per-day model had (a late append to an already-processed day).
Re-reading the boundary minute is a safe no-op: page writes integrate facts, never
duplicate. Order-agnostic, but newest-first (§7) puts it at the top.

## Language

Wiki prose in whatever language the vault's notes use (the bitácora is usually
Spanish). These skill files are English because they're versioned in a public
repo; the vault content is not.

## Bootstrap: starter Wiki/CLAUDE.md

If `Wiki/CLAUDE.md` is absent, create it with this, then let the user tune the taxonomy:

```markdown
# Wiki — schema

Conventions for the agent that maintains this wiki (see the `wiki` plugin for the
workflows). This vault follows OKF v0.1.

## Frontmatter (OKF)
Every page starts with YAML frontmatter. `type` is required (open set below);
`title` / `description` / `resource` / `tags` / `timestamp` are recommended.
`description` is a single sentence and is the source for the page's `index.md` one-liner.

## Conventions
- One page = one concept. Kebab-case filenames: `Wiki/servicio-pagos.md`.
- Cross-link with `[[wikilinks]]` — NOT OKF's `/path.md` links (would break Obsidian backlinks/Dataview/MCP). Also link `[[YYYY-MM-DD-HHMM-<repo>]]` back to the source per-invocation note(s).
- External sources go under a `# Citations` section; keep the `#repo/<name>` tag (and mirror it into frontmatter `tags`).
- Dense and short: a 500-word synthesized page beats dumping the raw note. Synthesize the *why*.

## index.md (OKF §6)
No frontmatter except `okf_version: "0.1"` on this root index. Body: `# <Category>` headings, entries `* [[page]] - <description from the page's frontmatter>`.

## Types
<!-- the frontmatter `type` set — tune to your world -->
service | incident | decision | concept | entity
```
