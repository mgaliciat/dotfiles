---
name: guide
description: Author a detailed reference or usage guide (guides/<topic>, type guide) in the OpenKnowledge vault — a cheatsheet, a keymap table, how a tool is used day to day — built from verified sources (the code and the binary itself, the vault, and gated web research), never from the conversation's own context. Use when the user says "guide", "guía", "cheatsheet", "/logbook:guide", or asks for reference documentation on a tool or config.
---

# logbook · guide

**Read three files first, in this order**: `~/.claude/skills/logbook/ENGINE.md`
(the layers, the MCP tools, the link rule), the vault's own `wiki/CLAUDE.md`
(the per-vault contract — it outranks everything), and
`~/.claude/skills/logbook/AUTHORING.md` (the evidence rule, the four channels,
the frontmatter and the closing loop). Then run this workflow.

**A guide is the WHAT you consult while working**: a cheatsheet, a tool's
keymaps, a palette, the flags you actually use, how something is operated day to
day. It is not a procedure with an order and a verification — that is
`/logbook:runbook`. It is not the synthesis of why something was decided — that
is the `wiki/` page, and the guide **links to it** rather than repeating it. It
is not a design document or an analysis — that is `/logbook:document`.

Target: **`guides/<topic>.md`**, `type: guide`, kebab-case slug, no `#` heading
in the body. `guides/index.md` is hand-written and lists every file in the folder.

## Workflow

1. **Scope it, and check for a twin.** `exec` `ls -A guides/` plus `search` and a
   `grep -rln` for the topic. If a guide already covers it, **extend that one
   with `edit`** — a second guide on one topic is the failure this step exists to
   prevent. State the target path and whether it is new or an extension.

2. **Enumerate from the source, never from recall.** This is the step that makes
   a guide worth having, and the one AUTHORING.md's evidence rule is about. For
   each thing the guide will list, name where it came from:
   - keymaps → the config files that define them (`keys = {}` blocks, the
     keymap file), plus the tool's own lister where it has one
     (`ghostty +list-keybinds`, `tmux list-keys`, `<leader>fk`)
   - flags, keys and subcommands → `<tool> --help`, `<tool> api-json`,
     `ghostty +show-config`, `brew info`. A tool is the only authority on itself
   - what is installed and at which version → `--version`, not a lockfile you
     did not open
   - structure and call chains → `codebase-memory-mcp`
   - a library's current signatures → `context7`
   - anything the vault already established → `/logbook:query`'s workflow

   **A partial enumeration presented as complete is a defect.** If a set is too
   large to enumerate, say which slice the guide covers, in the guide.

3. **Skeleton before prose.** Post the section order in the chat before the first
   write. A guide's usual shape, adapt it rather than following it blindly:
   - a two-line orientation at the top: what config this describes, and the one
     escape hatch (`:help`, `--help`, the key that lists every key)
   - the conventions the reader needs to parse the rest (what `<leader>` is,
     what a column means)
   - sections by task, not by source file — the reader is looking for "how do I
     rename a symbol", not for "what is in keymaps.lua"
   - tables for anything with more than three members
   - the deliberate absences: what was removed, disabled or is *not* bound, and
     why. This is the section a reader cannot reconstruct alone
   - a closing pointer to the `wiki/` page holding the why

4. **Write it.** `write` for a new file (`document`, `content` + `frontmatter` in
   one call), `edit` for one that exists. Frontmatter per AUTHORING.md: `type:
   guide`, `title`, one-sentence `description`, `resource` pointing at the repo
   file this mirrors when there is one (**and that original wins when the two
   differ** — say so in the body), `tags` including `repo/<name>` and `guide`,
   `timestamp`.

5. **Close the loop** — `guides/index.md` entry reusing the `description`
   verbatim, links out to the `wiki/` pages the guide names and at least one link
   back in from a neighbour, one entry prepended to `wiki/log.md`, then `audit`
   scoped to `guides/`.

## What makes a guide fail review

- A keybinding, flag or default that was never enumerated from the tool — it is
  either wrong today or will be after the next upgrade, and it is silent either
  way.
- Explaining *why* here instead of linking the `wiki/` page. The guide rots when
  the decision changes and nobody updates two files.
- Restating `--help` verbatim. The guide's value is the subset that is actually
  used, in the order it is actually used, with the traps annotated.
- A section with no evidence behind it, padded to look complete.
