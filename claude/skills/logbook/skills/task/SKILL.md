---
name: task
description: Capture, list and close pending work on a per-repo board (tasks/<repo>, type task-board) in the OpenKnowledge vault — something that surfaced mid-work and was not worth derailing for, or something the tech lead raised — with enough context to resume cold, and a code anchor confirmed against the real code when the task is technical. Use when the user says "task", "pendiente", "apunta esto", "queda pendiente", "me lo pidió mi lead", "/logbook:task", or wants to see or close what is open.
---

# logbook · task

Deliberately **self-contained**, like `/logbook:entry` and for the same reason:
this fires **in the middle of doing something else**. A capture gate that makes
you read three spec files first is a capture gate nobody uses. Read
`~/.claude/skills/logbook/ENGINE.md` only when something here is ambiguous.

Working on one thing and finding another — a retry that is not idempotent, a
migration nobody ran, a `TODO` older than the feature, something the tech lead
mentioned in passing. Fixing it now derails the current work; keeping it in your
head loses it. This skill drops it on a **per-repo board** with enough context to
pick it up cold, weeks later, without the session that found it.

Three operations, one verb:

| You want to | You type |
|---|---|
| Capture a pending item | `/logbook:task <whatever it is>` |
| See what is open | `/logbook:task list [repo]` |
| Close or drop one | `/logbook:task done <which>` / `drop <which>` |

## Where

**`tasks/<repo>.md`** — one board per repository, `type: task-board`, written
through the `open-knowledge` MCP. `<repo>` is the repository slug, bare, the same
one `/logbook:entry` uses.

- **Never `write` at a board that exists.** `write` with `position: replace`
  destroys the whole body — every open task on it. Boards change constantly, so
  **the board is always `edit`**; `write` is only for creating one that is not
  there.
- **Bootstrap on demand**: if `tasks/` is absent, create `tasks/.ok/frontmatter.yml`
  (the folder's `title` / `description` / `tags`) and a hand-written
  `tasks/index.md` listing every board. A new repo's board starts as the two
  headings, `## Open` and `## Done`, and nothing else.
- **MCP down → say so and stop.** No `curl`, no writing the task to a local file
  "for later". A pending item that only exists in this session's context is
  exactly the thing this skill exists to prevent.

## Capturing

**Fast path. This must not derail the work you interrupted** — you are filing a
task, not starting it. Do not begin fixing the thing.

### 1. Is it technical?

**Technical** means it points at code that exists. Then it gets an anchor, and
the anchor gets **confirmed before it is written**:

- Open the file and read the lines. Do not file from what you remember seeing
  five minutes ago — that is how a task describes code that was already fixed.
- Record `path:line` **relative to the repo root**, the symbol, and the commit:
  `git rev-parse --short HEAD`. The anchor is true at that SHA and claims nothing
  about later.
- **If confirming would take more than a quick look, file it as unverified** with
  the exact question to answer — and say so in the chat. A bounded capture that
  says "unverified" beats an accurate one that ate twenty minutes of the work you
  were actually doing.

**Non-technical** — something the tech lead asked for, a decision waiting on
somebody, a process item. No anchor, and the board says so. Record **who raised
it and when**: a task with no origin is one nobody can chase. If it *is*
checkable against code but you have not checked it, that is an unverified claim
and gets written as one, with what to check.

### 2. Write it

One `edit` on the board, inserting **right under `## Open`** — a stable anchor
that survives two sessions capturing at once, which a line-number-based insert
does not.

```markdown
- [ ] **Retries are not idempotent** · `2026-09-08`
  - **Where**: `internal/queue/worker.go:88` @ `a1b2c3d` — `Worker.process`
    re-enqueues with no dedup key
  - **Why it matters**: a redelivery double-charges the customer
  - **Origin**: found while tracing the invoice flow
```

- The checkbox line is the scannable layer: a **bold title that names the
  problem**, not the fix, plus the date.
- **Where** — anchor + SHA + symbol, or `unverified —` and what to check.
- **Why it matters** — the consequence. A task with no consequence gets deferred
  forever and should probably be dropped now instead.
- **Origin** — `found while <doing what>`, or `raised by the tech lead,
  <date>`, or whoever asked.
- Link out when it helps: the `wiki/` page, the flow, the `entries/` note from
  the session that found it. Relative links only.

**One task per item.** Two problems in one checkbox is one that never gets
closed.

## Listing

`exec` and read — this is a plain read, keep it cheap:

- One repo: `cat tasks/<repo>.md`.
- Everything open, across repos: `grep -n "^- \[ \]" tasks/`.
- Report **open first**, grouped by repo, oldest first — age is the signal. Say
  out loud which ones carry a stale-looking anchor (an old SHA on a file that has
  moved on) rather than presenting them all as equally live.

## Closing

Closing on belief is how a board stops being trusted. **Check first, then close:**

- **Technical** — re-read the anchor. Is the problem actually gone? If the file
  moved or the symbol was renamed, find it before deciding. `git log --oneline
  <sha>..HEAD -- <anchor path>` shows what touched it since the task was filed.
- **Non-technical** — say what actually happened and who confirmed it. "The lead
  said it is no longer needed" is a valid close and a different one from "done".

Then **one `edit`**: flip `- [ ]` to `- [x]`, move the whole block under
`## Done`, and append a closing line — the date, and the commit that closed it or
the reason it was dropped.

```markdown
  - **Closed**: 2026-09-14, fixed in `9f3750f` — dedup key on the message id
```

**Dropping is a real outcome and gets the same treatment.** A task dropped with
its reason recorded is knowledge; one silently deleted is a decision nobody can
review. Never delete a task line.

## What this skill does NOT do

- **It does not fix the task.** Capture and close only.
- **It does not write to `entries/`, `wiki/`, `sources/` or the authored
  layers.** When a task is closed by real work, `/logbook:entry` records that
  work and this board records the close — two different files, cross-linked.
- **It does not touch `wiki/log.md`.** That log tracks vault operations
  (ingest / lint / query); a board edit is not one.

## Language

**English on the board**, whatever language the session is in — same rule as the
repo and the rest of the vault. Chat replies follow the user.
