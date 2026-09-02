---
name: ingest
description: Synthesize the raw bitacora/ per-invocation notes into cross-linked wiki/ pages (OKF v0.2) in the OpenKnowledge vault — one per service, concept, decision or entity, linking notes that share a topic. Use when the user says "ingest", "sintetiza la bitácora", "wiki ingest", "/wiki:ingest", or asks to process the bitácora into the wiki.
---

# wiki · ingest

**First read `~/.claude/skills/wiki/ENGINE.md`** (the shared engine: where the
contract lives, which MCP tools to use, the layers, the link rule, the watermark).
Then read the vault's own `wiki/CLAUDE.md`. Then run this workflow.

Synthesize the `bitacora/` notes not yet processed:

1. **Determine the range.** The user's, or from the watermark: the most recent
   ingest entry in `wiki/log.md`, taking every note with a timestamp **≥** the end
   of its range (inclusive; see ENGINE). List the set with `exec` and state it
   before writing anything — an ingest whose range you cannot name is one nobody
   can resume.
2. **Open a task list before the first write.** It survives a compaction, and it is
   what makes a skipped step visible. Ingest is the long workflow here.
3. **Read the notes, then the pages they touch.** For each service / concept /
   decision that appears, pull the existing `wiki/<topic>` first — you are
   extending a running history, never opening a second page for a topic that has
   one. Resolve repo-tag aliases against `wiki/CLAUDE.md` **now**: the fix lands on
   the wiki page, never on the raw note.
4. **Create or update the page.** New page → `write`. Existing page → `edit`
   (`find`/`replace` on a unique anchor, or a `frontmatter` merge-patch); a `write`
   at a live path replaces the whole body. Notes carrying the same repo or topic tag
   converge on the same page, or on cross-linked pages — that convergence is the
   whole payoff.
5. **Frontmatter.** `type` is required and a page without one is not done; fill
   `title` / `description` / `resource` / `tags` when they carry real information,
   and bump the page's timestamp on every update. Do not invent a `resource`, a
   source, or provenance to fill a field.
6. **Cross-link.** Each page links the neighbours it mentions and the specific
   source note(s) it synthesizes (`[YYYY-MM-DD-HHMM-<repo>](../bitacora/….md)`).
   External sources go under `# Citations`, and anything fetched from the live web
   gets captured in `fuentes/` first — pages cite local documents, not URLs that
   rot. Relative links only; never the root-absolute form.
7. **Preserve the repo tag** from the bitácora on the service page and mirror it
   into frontmatter `tags`, so raw and wiki cross-reference.
8. **Close the loop.** Update `wiki/index.md` with any new page, reusing its
   `description` verbatim; prepend one ingest entry to `wiki/log.md` naming the
   source range you processed — that entry is the next run's watermark, so an
   ingest that skips it has to be redone by hand.
9. **Verify.** Run `audit` scoped to `wiki/` after the batch. The tools' success
   messages do not prove a section landed where you meant it to.

- **Never move or edit the bitácora.** "Already processed" is tracked in `log.md`
  precisely so the raw stays immutable.
- Use judgment on what deserves a page: a one-line unrelated entry doesn't, and a
  topic on its first appearance usually doesn't either — wait for the second or
  third occurrence rather than canonizing early. **Log the skip** so the next run
  can reconsider when the topic recurs.
