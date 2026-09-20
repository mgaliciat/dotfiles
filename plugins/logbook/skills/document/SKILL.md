---
name: document
description: Author a long-form technical document (docs/<topic>, type document) in the OpenKnowledge vault — a design doc, an architecture explanation, a deep analysis or a comparison — researched from verified sources (the code and the tools themselves, the vault, and gated web research), never from the conversation's own context. Use when the user says "document", "documento", "design doc", "documenta X a fondo", "/logbook:document", or asks for a detailed written treatment of a system or decision.
---

# logbook · document

**Read three files first, in this order**: `~/.claude/skills/logbook/ENGINE.md`
(the layers, the MCP tools, the link rule), the vault's own `wiki/CLAUDE.md`
(the per-vault contract — it outranks everything), and
`~/.claude/skills/logbook/AUTHORING.md` (the evidence rule, the four channels,
the frontmatter and the closing loop). Then run this workflow.

**A document is the long form**: a design doc, an architecture explanation, a
deep analysis of how something actually works, a comparison behind a decision, a
post-mortem written up properly. It is the layer for the treatment that is too
long, too argued and too sourced to be a `wiki/` page.

It is none of its neighbours, and picking the wrong one is the most common way to
misuse this skill:

| If it is… | It belongs in |
|---|---|
| A reference you consult while working (cheatsheet, keymaps, flags) | `/logbook:guide` → `guides/` |
| An ordered procedure with verification and undo | `/logbook:runbook` → `runbooks/` |
| One synthesized topic page, extending a running history from raw notes | `/logbook:ingest` → `wiki/` |
| A feature agreed *before* implementing, with status | `specs/` (by hand) |
| External material captured verbatim to be cited | `sources/` (via the research procedure) |

**Say which one you picked and why, before writing.** If it is not a document,
hand it to the right skill instead of forcing it into `docs/`.

Target: **`docs/<topic>.md`**, `type: document`, kebab-case slug, no `#` heading
in the body.

### Bootstrapping `docs/`

The folder is created on first use. Check with `exec` `ls -A`; if `docs/` is not
there, create it before the first document:

- `docs/.ok/frontmatter.yml` with the folder's `title`, `description` and `tags`
  — the folder description is part of the retrieval index, not decoration.
- `docs/index.md` — hand-written, no frontmatter, `## <Category>` headings and
  `- [doc](./doc.md) — <the doc's description>` entries. Do **not** turn on the
  `okf` plugin's index generation: it would replace this file.

## Workflow

1. **Classify and scope.** Name the layer (the table above), the exact target
   path, and whether this is new or an extension. `exec` `ls -A docs/` plus
   `search` and `grep -rln <topic>` across the vault — including `wiki/`, because
   a document usually *deepens* a page that already exists and must link it
   rather than restate it.

2. **Build the evidence base before writing a line.** AUTHORING.md's four
   channels, in order — and a long document is exactly where the temptation to
   write from recall is strongest:
   - **The vault** — `/logbook:query`'s workflow. What is already known, and what
     the vault explicitly does *not* know (state that in the document).
   - **The code and the machine** — read the real files; `codebase-memory-mcp`
     (`search_graph`, `trace_path`, `get_code_snippet`) for call chains, who calls
     what, dead code and impact; `Grep`/`Read` for text and config; the binary
     itself (`--help`, `--version`, `api-json`) for its own surface; a measurement
     for any performance or size claim.
   - **`context7`** for a third-party library's current API.
   - **The live web**, only through the vault's external-research procedure:
     scan, agree a rubric with the user and **stop until they confirm**, capture
     each source into `sources/` as you fetch it, cite the local capture. If a
     source cannot be fetched, ask for it — never fill the gap from memory.

   Keep a claim → source map as you go. **A claim with no source is cut or marked
   unverified.** It never ships as an assertion.

3. **Skeleton before prose, posted in the chat, and confirmed.** A document is
   long enough that a wrong outline wastes the whole write, so state it and give
   the user the chance to correct it. The usual shape:
   - **What this is and who it is for** — one paragraph, including what it does
     not cover.
   - **The problem / the context** — what forced this to exist.
   - **How it actually works** — the mechanism, traced through the real code, in
     the order the system executes it. Name files and symbols; a diagram in
     mermaid or a table when the shape is not linear.
   - **The constraints** — what could not be changed, and what imposed it.
   - **The trade-offs and the alternatives rejected**, each with the reason it
     was rejected. This is the highest-value section and the one nobody can
     reconstruct from the code.
   - **Failure modes** — especially everything that fails *silently*.
   - **Open questions / unverified** — explicit, not omitted.
   - **`# Citations`** — the `sources/` captures and the vault pages used.

   Write each section when its evidence is finished, not in a final pass.

4. **Write it.** `write` for a new file (`content` + `frontmatter` in one call),
   `edit` for one that exists — a `write` at a live path replaces the whole body.
   Frontmatter per AUTHORING.md: `type: document`, `title`, one-sentence
   `description`, `resource` when it mirrors something canonical, `tags`
   including `repo/<name>` where one applies, `timestamp`.

5. **Do not mix your own analysis with the external material** unless asked —
   factual synthesis turning into opinion is how a document stops being citable.
   If asked for both, separate the two halves inside the file.

6. **Close the loop** — `docs/index.md` entry reusing the `description` verbatim,
   links out to every `wiki/` page, guide, runbook and source the document names
   plus a link back in from one or two of them, one entry prepended to
   `wiki/log.md` naming what was written and from which sources, then `audit`
   scoped to `docs/`.

## What makes a document fail review

- A mechanism described from how it is *supposed* to work rather than traced
  through the code that runs.
- Confident prose where the evidence ran out, instead of an open question.
- A restatement of a `wiki/` page that should have been a link.
- A wall of text with no enumeration, no failure modes and no rejected
  alternatives — length is not detail.
- Citing a live URL instead of a `sources/` capture.
