---
name: bitacora
description: Append a dated work-log entry to today's Obsidian daily note (Bitacora/YYYY-MM-DD.md) recording what changed and why, tagged by repo/service so a day spanning many agents/services can be read and cross-referenced in one place. Use when the user says "bitácora", "guarda resumen", "resumen del día", or after landing a git commit / opening a PR.
---

# Bitácora diaria (Obsidian)

Working across many agents and services in parallel and losing the thread of what
got done where. This skill drops one dated note per day that every session appends
to, so at end of day there is a single place to read the day's work and
cross-reference the parts of a problem that spanned several repos.

The summary is yours to write from the session context — nothing else can generate
it. Keep it to the *reasoning* git won't preserve, not a commit-log dump.

## When to append

- After you land a `git commit` or open a PR — one entry per **meaningful unit of
  work**, not per WIP commit.
- Whenever the user says "bitácora" / "guarda resumen" / "resumen del día".

## Where

One file per day: **`Bitacora/YYYY-MM-DD.md`** in the Obsidian vault. Fixed folder
on purpose — no dependence on the Daily Notes plugin or its config.

- Append via the obsidian MCP (`vault_append`, or read-then-write).
- If the file doesn't exist yet, create it with an `# YYYY-MM-DD` H1, then the entry.
- Today's date is in your context — don't guess it.
- **Obsidian closed → the MCP fails.** Say so and append to the file on disk
  instead; never silently skip the entry.

## Entry format

Append, never rewrite. Make it cross-referenceable:

```markdown
## HH:MM — <repo / service>
#repo/<name> #<topic-if-shared>

- What changed and **why** — the decision/context that won't survive in git.
- Anything left open, gotchas, follow-ups.
```

- The `#repo/<name>` tag is what lets you slice the day by service.
- When one problem spans several services, give their entries a **shared `#topic`
  tag** (and/or `[[YYYY-MM-DD]]` links). That's what makes the payoff query work:
  *"read today's bitácora and tell me how these three services relate."*

## Language

Write entries in whatever language the session is working in.
