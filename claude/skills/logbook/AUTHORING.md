# Logbook (OpenKnowledge) — authoring engine

Shared spec for the `logbook` plugin's **document-writing** skills —
`/logbook:guide`, `/logbook:runbook`, `/logbook:document`. Each of those reads
`ENGINE.md` first (the layers, the MCP tools, the link rule, the watermark), then
the vault's own `wiki/CLAUDE.md` (which outranks both), then **this** file, then
its own workflow. Everything common to writing a long document — where the
evidence comes from, how it is checked, the skeleton, the closing loop — is here
once.

The three sibling skills are a different job and do not read this file:
`/logbook:entry` captures raw, `/logbook:ingest` synthesizes raw into `wiki/`,
`/logbook:lint` audits. These three **author** a document that did not exist as a
document anywhere — from the code, from the vault, and (gated) from the web.

## The rule that defines these skills

**Nothing lands in the document because you remember it.** Every claim — a flag,
a path, a default, a version, an ordering, a keybinding, a file name — traces to
something you opened *in this run*: a file in the repo, a command's own output,
a page in the vault, a `sources/` capture. The conversation that led here is a
**lead**, never evidence; so is training memory. Neither is citable.

This is not pedantry, it is the observed failure mode: a plausible,
confidently-worded, wrong assertion costs more than saying nothing, because it
gets acted on. And in config it hides especially well — a wrong key is usually a
*silent no-op*, not an error. Two of this vault's own recorded cases: two gopls
settings sat in the nvim config for months looking load-bearing after gopls had
removed both, and only `gopls api-json` said so; a Ghostty keybinding is only
real if `ghostty +list-keybinds` prints it. **Enumerate, don't trust the config,
and never trust the recollection.**

A document produced by these skills is read later by someone who cannot ask the
session that wrote it. That is the whole reason it is being written down.

## The four evidence channels

In this order — the vault is cheapest and the web is the most expensive and the
most gated.

### 1. The vault, first and always

Run `/logbook:query`'s workflow before anything else: `search` for ranked hits,
`exec` with `grep -rln <topic>` for exhaustive literal ones, `links` (backlinks
and forward links) out of whatever you land on. Thirty seconds of this avoids
re-deriving what the vault already knows, and it answers the question that comes
before the writing: **does this document already exist?**

Classify what you find as *covered* / *partial* / *not covered*, and **propose
extending an existing document rather than opening a second one** whenever the
topic is coherent with a page that already exists. Two documents on one topic is
the failure this layer is built to avoid.

### 2. The code and the machine

The authority on a tool is the tool:

| Claim | Where it is verified |
|---|---|
| A flag, a subcommand, a config key | `<tool> --help`, `<tool> api-json`, `ghostty +show-config`, `+list-keybinds`, `brew info` |
| A version | `<tool> --version` — never a changelog, never a lockfile you did not open |
| What a script does, and in what order | Read the script. Top to bottom. The README is a claim, the script is the fact |
| Structure: who calls what, dead code, call chains | `codebase-memory-mcp` (`search_graph`, `trace_path`, `get_code_snippet`); `index_repository` first if the project is not indexed |
| Literal text, configs, non-code files | `Grep` / `Glob` / `Read` |
| A performance or size number | Measure it here. A README's benchmark describes someone else's machine |
| A command's real output shape | Run it, and paste what it actually printed |

When the repo and the vault disagree, **the repo wins** and the disagreement is
itself worth a line in the document.

### 3. A library's current API

`context7` — for a third-party library's signatures and current usage, which is
exactly where a training cutoff betrays you. Not a general search engine: for a
mature language's stable core, or for anything that is not a library, it is only
a round-trip.

### 4. The live web — gated

Follow the **external-research procedure in the vault's `wiki/CLAUDE.md`**, not
your own: scan the vault first, agree a rubric with the user (a scoped question,
3–7 dimensions, 3–8 candidate sources, 2–3 success criteria) and **stop until
they confirm**, then capture each source in `sources/` *at the moment you bring
it in* — one at a time, never a batch at the end.

The document then cites the local `sources/` capture, never the live URL. If a
fetch returns a model's summary instead of the raw text, say so and try a raw
route (`gh api`, `curl -sL`, or ask for the paste); if it still cannot be done
the capture declares `capture: partial`. **If a necessary source cannot be
fetched, ask for it — never fill the gap from memory.**

## Before writing: the plan, out loud

State, in the chat, before the first `write`:

1. **The target** — folder, file name, and whether this is a new document or an
   extension of one that exists.
2. **The skeleton** — the section headings, in order. The skeleton comes before
   the prose, not after; each finding is written when its source is finished, not
   in a final pass. A section you cannot fill from evidence gets cut here, not
   padded later.
3. **The evidence plan** — which files, which commands, which vault pages. If it
   needs the live web, this is where the rubric gate applies and you wait.

## Detail means structure, not volume

These skills exist to produce *detailed* documents, and detail is a property of
coverage, not of word count:

- **Enumerate exhaustively where the set is finite** — every flag, every keymap,
  every step, every failure mode. A table beats a paragraph for anything with
  more than three members, and a partial enumeration presented as complete is a
  defect.
- **Exact commands, exact paths, exact output.** `./install.sh`, not "the
  installer". `~/.claude/settings.json`, not "the settings file".
- **The thing that breaks silently gets its own section.** A guide, runbook or
  document whose reader can hit a no-op with no error message and no clue is
  unfinished — that is the highest-value paragraph in the file.
- **Say what you could not verify.** An explicit `## Open questions` (or a
  sentence marking one claim as unverified) beats a confident sentence with
  nothing behind it. Prose padding to look thorough is the opposite of thorough.
- **Dense, not verbose.** Synthesize; do not dump the file you read.

## Frontmatter and writing rules

Shared across the three; the per-skill file names its `type` and its folder.

```yaml
type: guide | runbook | document   # required by OKF — a document without one is not done
title: …                           # this IS the H1; the body carries no `#` heading (MD025)
description: …                     # one sentence; the SINGLE source of the index one-liner
resource: …                        # the original this mirrors, when there is one — and it wins
tags: [repo/<name>, …]             # mirror the repo tag so raw ↔ synthesized cross-reference
timestamp: YYYY-MM-DD              # the date in your context, not a guess
```

- **`write` for a document that does not exist; `edit` for one that does.** A
  `write` with `position: replace` at a live path destroys the whole body — that
  is how this vault lost its `log.md` once. Passing `frontmatter` alongside
  literal `content` silently forces `replace`, so never combine the two on a live
  page.
- **Check the path first** with `exec` (`ls <folder>/`) before the first write.
- **Relative markdown links only** (`[nvim](../wiki/nvim.md)`); never the
  root-absolute `/folder/x.md` form, which duplicates the segment and dies
  silently.
- **English**, whatever language the session is being conducted in — paths,
  file names, headings and prose alike.

## Closing the loop

A document nobody can find is not finished:

1. **The folder's `index.md`** gets its entry, reusing the document's own
   `description` **verbatim** — that field is the single source, do not write the
   one-liner twice. The index lists every file in the folder, not a selection.
2. **Cross-link both ways.** The document links the neighbours it names; one or
   two of those neighbours get an inbound link back. Retrieval here is a lexical
   loop (BM25 + recency + graph traversal, semantics off), so links, folders,
   titles and folder descriptions **are** the index — every link shortens the next
   agent's loop. An under-linked document is an island.
3. **`wiki/log.md`** gets one entry prepended (newest-first), `## YYYY-MM-DD: <op>
   | <summary>`, naming what was written and from which sources.
4. **`audit`** scoped to the folder, after the writes. The tools' success
   messages do not prove a section landed where you meant it to.

## What these skills do not do

- **They do not write a raw note.** `entries/` belongs to `/logbook:entry` and is
  immutable.
- **They do not move the ingest watermark.** Only `/logbook:ingest` does.
- **They do not edit `entries/`, `claude_sessions/` or `sources/`** — raw and
  captures are immutable after they land.
- **MCP down → say so and stop.** No `curl` at the endpoint, no writing the
  document to a local file "for later". The user reconnects with `/mcp`. A
  document that only exists in this session's context is not persisted work —
  that is the vault's own recorded lesson.
