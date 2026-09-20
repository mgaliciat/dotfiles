---
name: runbook
description: Author a detailed operating procedure (runbooks/<repo>-<topic>, type runbook) in the OpenKnowledge vault — prerequisites, the exact commands in the order that works, per-step verification, troubleshooting and undo — built by reading the real scripts and running the real commands, never from the conversation's own context. Use when the user says "runbook", "procedimiento", "/logbook:runbook", or asks how to bring something up, deploy, migrate or recover it step by step.
---

# logbook · runbook

**Read three files first, in this order**: `~/.claude/skills/logbook/ENGINE.md`
(the layers, the MCP tools, the link rule), the vault's own `wiki/CLAUDE.md`
(the per-vault contract — it outranks everything), and
`~/.claude/skills/logbook/AUTHORING.md` (the evidence rule, the four channels,
the frontmatter and the closing loop). Then run this workflow.

**A runbook is an ordered procedure someone executes under pressure**: what to
run, in what order, how to know each step worked, what to do when it did not, and
how to undo it. It is not a reference table — that is `/logbook:guide`. **The
*why* does not go here**; it goes on the repo's `wiki/` page, and the runbook
links it. An operator halfway through a migration does not want the rationale.

Target: **`runbooks/<repo>-<topic>.md`**, `type: runbook` — the file name leads
with the repo slug (`dotfiles-macos`, `dotfiles-preflight`), kebab-case, no `#`
heading in the body. `runbooks/index.md` is hand-written and lists every file.

## Workflow

1. **Scope it, and check for a twin.** `exec` `ls -A runbooks/` plus `search` and
   `grep -rln`. An existing runbook for the same procedure gets **extended with
   `edit`**, never duplicated. Say which OS / environment / variant this one
   covers — a runbook that does not name its target is a runbook nobody can trust.

2. **Derive the steps from the script, not from the README.** This is the whole
   evidence rule of AUTHORING.md applied to procedures:
   - **Read the actual script top to bottom** and take the order from it. A
     README, a wiki page or a memory of how it went is a claim; the script is the
     fact. Where they disagree, the script wins and the disagreement is worth a
     line in the runbook.
   - **Every command goes in exactly as it is typed**, with its real flags and
     real paths. No "run the installer".
   - **Run what is safe to run** and paste the output shape you actually saw —
     `--version`, `--help`, a `--dry-run`, a status query. Never invent an
     expected output.
   - Guards, idempotency checks and their markers (`✓`, `OK`, `⚠️`) are part of
     the procedure: the operator reads those to know whether a step was skipped
     or done.
   - Anything the vault already recorded about this procedure comes from
     `/logbook:query`'s workflow first.

3. **Skeleton before prose.** Post it in the chat before the first write. A
   runbook's shape:
   - **Scope and preconditions** — what this covers, what it does not, and what
     must already be true (an OS version, a tool, a credential, a network).
   - **Order that avoids a second run** — the steps that must happen *before* the
     main command because otherwise you run everything twice. Name them first.
   - **The steps**, numbered, each one: the command, what it changes, and **its
     own verification** — a command with a concrete expected result, not "check it
     worked".
   - **What breaks silently** — every step whose failure produces no error: a
     no-op guard, a wrong binary that still runs, a symlink that was ignored, a
     value that falls back without saying so. This is the section that earns the
     runbook.
   - **Troubleshooting** — symptom → cause → fix, as a table.
   - **Undo** — how to get back, per step where it differs. A procedure with no
     undo is a procedure nobody dares start.
   - **After a `git pull` / re-run** — what has to be reloaded, restarted or
     re-sourced, and what is safe to re-run (idempotency is a claim: verify it in
     the script).

4. **Write it.** `write` for a new file (`content` + `frontmatter` in one call),
   `edit` for one that exists. Frontmatter per AUTHORING.md: `type: runbook`,
   `title`, one-sentence `description` naming the target environment, `resource`
   pointing at the repo's own runbook file when one exists — **that original is
   canonical and wins when the two differ**, and the body should say so — `tags`
   including `repo/<name>`, `runbook` and the environment, `timestamp`.

5. **Close the loop** — `runbooks/index.md` entry reusing the `description`
   verbatim, a link to the repo's `wiki/` page for the why plus a link back from
   it, one entry prepended to `wiki/log.md`, then `audit` scoped to `runbooks/`.

## What makes a runbook fail review

- A step reconstructed from memory or from the conversation rather than read out
  of the script. The order is the one thing a runbook exists to get right.
- A verification that is not a command with an expected result.
- Rationale in the body instead of a link to the `wiki/` page — two files then
  disagree the first time the decision changes.
- No undo section, or an undo that was never traced through the script.
- Silence about the steps that fail quietly.
