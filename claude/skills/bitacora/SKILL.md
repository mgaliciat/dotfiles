---
name: bitacora
description: Write one immutable per-invocation work-log note (bitacora/YYYY-MM-DD-HHMM-<repo>) into the OpenKnowledge vault, recording what changed and why, tagged by repo so a day spanning many agents and services can be read, cross-referenced, and later synthesized by the wiki skill. Use when the user says "bitácora", "guarda resumen", "resumen del día", or after landing a git commit / opening a PR.
---

# Bitácora (OpenKnowledge)

Working across many agents and services in parallel and losing the thread of what
got done where. This skill drops **one immutable note per invocation** — a small,
atomic log entry written as it happens. Reassembly is the wiki `ingest` skill's
job: it reads these notes and synthesizes cross-linked pages, linking together the
ones that share a topic.

Why one file per invocation (not one shared daily note): each note is written once
and never touched again. That immutability is what lets `ingest` track exactly
what it has already processed — a note that shows up after an ingest is always a
*new* file, never an edit to an already-read one, so nothing falls in the crack a
same-day-appended note had.

The summary is yours to write from the session context — nothing else can generate
it. Keep it to the *reasoning* git won't preserve, not a commit-log dump.

## When to log

- After you land a `git commit` or open a PR — one note per **meaningful unit of
  work**, not per WIP commit. (A `PostToolUse` hook fires on every commit and
  reminds you; the judgment of whether *this* commit is a unit of work is still
  yours. Say so and skip when it isn't.)
- Whenever the user says "bitácora" / "guarda resumen" / "resumen del día".

## Where

One file **per invocation**: **`bitacora/YYYY-MM-DD-HHMM-<repo>`** in the
OpenKnowledge vault, written with the `open-knowledge` MCP's `write` tool
(`document`). `<repo>` is the primary repo/service slug — the **repository** name,
not the product's and not the org's; the vault's `wiki/CLAUDE.md` keeps the alias
table, and a raw note is never re-tagged after the fact.

- The path carries **no extension**: `write` appends `.md` itself.
- Date and time are in your context — don't guess them. `HHMM` (no colon — it's a
  filename), so the name sorts chronologically.
- **Check the path first** with `exec` (`ls bitacora/ | grep <YYYY-MM-DD-HHMM>`).
  If that exact name exists (same repo, same minute), suffix `-2`, `-3`, … A
  `write` at an existing path with `position: replace` **destroys** the note that
  was there — the one failure this whole layer is built to prevent.
- **MCP down → say so and stop.** No `curl` at the endpoint, no writing the note
  to a local file "for later". The user reconnects with `/mcp`, then the note gets
  written. (A note that only lives in this session's context is not persisted
  work — that is the vault's own recorded lesson.)

## Note format

Follows the vault's `nota-invocacion` template. Frontmatter plus the four
sections — pass `content` and `frontmatter` to `write` in one call:

```yaml
type: log                 # required by OKF; `log` is what this layer uses
date: 2026-09-02          # ISO 8601
repo: dotfiles            # the repository slug, bare
tags: [repo/dotfiles]     # plus a shared #topic when one applies
```

```markdown
# YYYY-MM-DD HH:MM — <repo / service>

## Qué cambió

## Por qué

## Notas

## Seguimiento
```

- **`Por qué` is the section that earns the note.** What changed is in the diff;
  the decision, the alternative rejected, and the constraint that forced it are not.
- The `repo/<name>` tag is what lets `ingest` and `lint` slice by service.
- When one problem spans several services or sessions, give the notes a **shared
  topic tag** — that shared tag is what makes `ingest` link them together into (or
  across) the same wiki page. That's the payoff: several invocations on one topic
  come out linked after ingestion.

## Language

Write notes in whatever language the session is working in — the vault is not the
repo, and its content is not held to this repo's English-only rule.

## What this skill does NOT do

Write to `wiki/`, `fuentes/` or `specs/`, update `index.md`, or touch `log.md`.
Capture is write-only and deliberately dumb; synthesis is `/wiki:ingest`. Raw stays
messy on purpose.
