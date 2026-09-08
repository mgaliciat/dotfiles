---
name: walkthrough
description: Trace a process through the real code and write it up as a flow document (flows/<repo>-<process>, type flow) in the OpenKnowledge vault — mermaid diagrams whose every node carries a code anchor (symbol + file:line), pinned to a commit SHA so the document can be mechanically re-verified later. Use when the user says "walkthrough", "flujo", "cómo funciona X por dentro", "traza el proceso", "/logbook:walkthrough", or asks how a service, repo or feature actually executes end to end.
---

# logbook · walkthrough

**Read three files first, in this order**: `~/.claude/skills/logbook/ENGINE.md`
(the layers, the MCP tools, the link rule), the vault's own `wiki/CLAUDE.md`
(the per-vault contract — it outranks everything), and
`~/.claude/skills/logbook/AUTHORING.md` (the evidence rule, the four channels,
the frontmatter and the closing loop). Then run this workflow.

**A walkthrough answers one question: how does this process actually execute?**
It follows one flow — a request, a job, a command, a feature — from its
entrypoint to its last effect, through the code that really runs, and writes it
up with diagrams. Its siblings each hold a different half and the walkthrough
**links** them rather than repeating them: the *why* is the `wiki/` page, the
*how do I run it* is a `runbook`, the *what are the flags* is a `guide`, the
*argued treatment* is a `document`.

Target: **`flows/<repo>-<process>.md`**, `type: flow`, kebab-case, no `#`
heading in the body.

## What makes this skill different: it is re-verifiable

Every other authored document is verified once, when it is written. A flow
document is built so a **future reader can mechanically re-check it**, which is
the only defence against a diagram that quietly stopped matching the code:

- It is **pinned to a commit SHA** in frontmatter. Every claim in it is true *at
  that commit* and makes no claim about `HEAD`.
- **Every node in every diagram has an anchor** — a symbol and a `file:line`, in
  one table. A node you cannot anchor does not go in the diagram.
- It carries its own **re-verification commands**, so checking it is a paste, not
  an investigation.

If you cannot anchor a step, that is a finding about the code (dynamic dispatch,
a queue, framework magic), and it gets **written as such** — never smoothed over
with a plausible arrow.

### Bootstrapping `flows/`

Created on first use. `exec` `ls -A`; if `flows/` is absent, create it before the
first document:

- `flows/.ok/frontmatter.yml` — the folder's `title`, `description` and `tags`.
  The folder description is part of the retrieval index, not decoration.
- `flows/index.md` — hand-written, no frontmatter, `## <Category>` headings,
  `- [flow](./flow.md) — <its description>` entries. Do **not** enable the `okf`
  plugin's index generation; it would replace this file.

## Workflow

### 1. Pin the ground truth first

Before reading a single line, in the repo the process lives in:

```
git rev-parse HEAD
git status --short
git remote get-url origin
```

**A trace taken over a dirty tree is pinned to nothing** — say so and either
stash, or record explicitly that the anchors include uncommitted work. The SHA,
the branch and the remote go in frontmatter (`commit`, `branch`, `resource`).

### 2. Scope the flow to one answerable question

Name the **entrypoint** and the **terminus** out loud: "from the HTTP handler for
`POST /invoices` to the row committed in `invoices` and the event published".
A walkthrough with no terminus expands until it is the whole repo and helps
nobody. If the user's ask covers several flows, say so and pick one, or write
several files.

Then `/logbook:query`'s workflow over the vault: an existing `wiki/` page or flow
on this process is extended and linked, not duplicated.

### 3. Trace it, with the graph and then against it

**The structural tools first** (`codebase-memory-mcp`; `index_repository` if the
project is not indexed):

| Need | Call |
|---|---|
| Find the entrypoint by name / route / label | `search_graph` |
| The call chain from it | `trace_path(mode=calls)` |
| What happens to the payload | `trace_path(mode=data_flow)` |
| Where it crosses a service boundary | `trace_path(mode=cross_service)` |
| Exact source and its line range for an anchor | `get_code_snippet` |
| A shape the above cannot express | `query_graph` |

**Then the things a call graph structurally cannot see**, with `Grep` / `Read` —
this is where a confident-and-wrong diagram comes from:

- routing tables, middleware order, decorators and framework hooks
- dependency injection and container wiring: the interface in the chain is not
  the implementation that runs — **find the binding and name the concrete type**
- dispatch through a string, a map, an enum, reflection or a plugin registry
- **asynchronous boundaries**: a queue publish, an event bus, a webhook, a cron,
  a background worker. The chain does not *end* at `publish()` — say which
  consumer picks it up and how you found it, or mark the edge as unresolved
- SQL, migrations, stored procedures, triggers; template and view rendering
- configuration and env vars that change the path taken
- retries, timeouts, transactions and their boundaries — where does a partial
  failure leave the system?

**Run it where you safely can** — a test that covers the flow, a `--dry-run`, a
local request, a log with the chain in it — and say that you did. An executed
path beats a read one.

### 4. Draw only what you can anchor

Mermaid renders natively in the vault: a plain ` ```mermaid ` fence, no library,
no `<Diagram>` component. **Several small diagrams beat one large one** — each
answers a question a reader actually has:

| The process is… | Diagram |
|---|---|
| A call crossing components / services | `sequenceDiagram` — participants are real modules, messages are real calls |
| Branching, with decisions and error paths | `flowchart TD` |
| An entity moving through states | `stateDiagram-v2` |
| Writes across tables | `erDiagram`, limited to the tables this flow touches |

Rules, all of them enforced by the anchor table below:

- **Every node id is an anchor id.** `H1`, `S2`, `Q1` — short, stable, and the
  first column of the table. Never invent a node for symmetry.
- **A node with no code behind it is marked as such**: an external API, a broker,
  a human step, a scheduled trigger. Say it in the label (`(external)`), do not
  silently draw it like the rest.
- **An edge you could not resolve is drawn as one** — mermaid's dotted arrow
  (`-->>`/`-.->`) with a label saying why (`async, consumer unresolved`). A
  guessed solid arrow is the failure this whole skill exists to prevent.
- Label edges with the real call or the real message, not with prose.
- Keep the palette out of it: the vault themes the diagram, and hand-picked
  colours break in the other theme.

After writing, **check the tool's response for a `mermaid-parse-error`
warning** — the edit lands anyway and the fence silently fails to render. Fix and
re-edit.

### 5. The anchor table — the section that makes the document verifiable

One table, every node in every diagram, no exceptions:

| id | Symbol | Anchor | What it does |
|---|---|---|---|
| `H1` | `handlers.InvoiceHandler.Create` | `internal/http/invoice.go:142` | Validates the payload, opens the tx |
| `Q1` | *(broker — external)* | — | `invoices.created`, consumed by [worker](#) |

- The anchor is `path:line` **relative to the repo root**, at the pinned commit.
- **Re-read every anchor after you finish writing.** Line numbers move while you
  work; an anchor that drifted during the session is simply a wrong anchor. This
  re-read is the last step before publishing, not an optional one.
- Rows with no anchor carry `—` and an explicit reason. A silent blank is not
  allowed.

### 6. Write the document

`write` for a new file (`content` + `frontmatter` in one call), `edit` for one
that exists — a `write` at a live path replaces the whole body.

```yaml
type: flow
title: …
description: …                 # one sentence, entrypoint → terminus
resource: …                    # the repo, ideally the permalink at this commit
commit: a1b2c3d4               # full or short SHA — the pin
branch: main
tags: [repo/<name>, flow, …]
timestamp: YYYY-MM-DD
```

Body shape:

1. **Scope** — entrypoint, terminus, and what this flow deliberately does not
   cover. One paragraph.
2. **The path in one breath** — 5–10 numbered lines, each naming its anchor id.
   A reader who stops here should already be able to find the code.
3. **The diagrams**, each under a heading that is the question it answers.
4. **Step by step** — one subsection per meaningful step: what it receives, what
   it decides, what it changes (DB, queue, filesystem, network), and what happens
   when it fails.
5. **The anchor table.**
6. **Where the trace goes blind** — every dynamic dispatch, async hop, DI
   binding, framework hook and unresolved edge, with how you established what you
   did establish. **This section is required**; "none" is an acceptable value and
   an assertion you are making.
7. **Failure modes and boundaries** — transactions, retries, timeouts, partial
   states, what is idempotent and what is not.
8. **Re-verify this document** — the literal commands, ready to paste:

   ```
   git -C <repo> fetch && git -C <repo> diff --stat <commit>..HEAD -- <anchor paths>
   ```

   plus the note that a non-empty diff means the anchors need re-checking, not
   that the document is necessarily wrong.
9. **`# Citations`** — the `wiki/` page holding the why, the runbook that operates
   it, any `sources/` capture used.

### 7. Close the loop

`flows/index.md` entry reusing the `description` verbatim; links out to the
`wiki/` page, the runbook and the guide this flow relates to, plus one link back
in from a neighbour; one entry prepended to `wiki/log.md` naming the process, the
repo and the pinned SHA; then `audit` scoped to `flows/`.

## What makes a walkthrough fail review

- **A diagram node with no anchor.** The single hardest rule here.
- An arrow that represents what the code is *supposed* to do — an interface, a
  base class, a handler you assumed was registered — rather than the
  implementation that actually runs.
- A chain that stops at an async boundary without saying it stopped.
- No commit SHA, or a SHA taken over a dirty tree without saying so.
- Anchors read at the start and never re-read at the end.
- Explaining *why* the design is this way instead of linking the `wiki/` page.
- One enormous diagram that answers no question in particular.
