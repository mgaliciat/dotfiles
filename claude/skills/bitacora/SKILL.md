---
name: bitacora
description: Write one immutable per-invocation work-log note (Bitacora/YYYY-MM-DD-HHMM-<repo>.md) recording what changed and why, tagged by repo/service so a day spanning many agents/services can be read, cross-referenced, and later synthesized by the wiki skill. Use when the user says "bitácora", "guarda resumen", "resumen del día", or after landing a git commit / opening a PR.
---

# Bitácora (Obsidian)

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
  work**, not per WIP commit.
- Whenever the user says "bitácora" / "guarda resumen" / "resumen del día".

## Where

One file **per invocation**: **`Bitacora/YYYY-MM-DD-HHMM-<repo>.md`** in the
Obsidian vault (fixed folder — no dependence on the Daily Notes plugin). `<repo>`
is the primary repo/service slug. If that exact path already exists (same repo,
same minute), suffix `-2`, `-3`, … — **never append to or overwrite an existing
note**; each invocation is its own file.

- Write via the obsidian MCP (`vault_write`). Create the file; never touch another.
- Date and time are in your context — don't guess them. `HHMM` (no colon — it's a
  filename), so the name sorts chronologically.
- **Obsidian closed → the MCP fails.** Say so and stop. Never work around it:
  no writing the file to disk, no curl against the endpoint. The user reconnects
  with `/mcp`, and then the note gets written.

## Note format

The file *is* the entry — one H1, one tag line, the body:

```markdown
# YYYY-MM-DD HH:MM — <repo / service>
#repo/<name> #<topic-if-shared>

- What changed and **why** — the decision/context that won't survive in git.
- Anything left open, gotchas, follow-ups.
```

- The `#repo/<name>` tag is what lets `ingest` and `lint` slice by service.
- When one problem spans several services or sessions, give the notes a **shared
  `#topic` tag** — that shared tag is what makes `ingest` link them together into
  (or across) the same wiki page. That's the payoff: several invocations on one
  topic come out linked after ingestion.

## Language

Write notes in whatever language the session is working in.
