---
name: okf
description: The Open Knowledge Format (OKF v0.2) as the Logbook vault uses it — the conformance floor, reserved files, the frontmatter families (sources, generated, verified, status, stale_after), the actor convention, and what the server's okf diagnostics mean. Read by the other logbook skills before they write frontmatter; use directly when the user asks about OKF, frontmatter fields, provenance, trust or conformance.
---

# logbook · okf

The vault is an OKF bundle: a tree of markdown files with YAML frontmatter. OKF is
Google's format, specified in one self-contained document, [SPEC.md at
v0.2](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/ad30107c31c06aec8a7d5636e0d1058118604e6f/SPEC.md)
(Apache-2.0). Section numbers below cite it. This file is the part of it the
logbook needs, plus how the Logbook server checks it; when the two disagree, the
spec wins, and the vault's own `wiki/CLAUDE.md` outranks both on what *this* vault
chooses.

## The floor — the only hard rules (§11)

A bundle is conformant when:

1. Every non-reserved `.md` file has a **parseable YAML frontmatter block**.
2. Every frontmatter block has a **non-empty `type`**.
3. The reserved files follow their structure (below).

That is all. A concept carrying only `type` is fully conformant. Everything else
is guidance, and a consumer must not reject a bundle for missing optional fields,
unknown `type` values, unknown keys, broken links or missing `index.md` files.

## Reserved files (§3.1, §8, §9)

`index.md` and `log.md` are reserved **at every level** and are never concept
documents — they need no `type`.

- **`index.md`** lists the folder for progressive disclosure: sections of
  `[Title](relative-url) - description` entries, each description copied from the
  linked concept's own `description`. It carries **no frontmatter**, with one
  exception: the vault-root `index.md` may declare `okf_version: "0.2"`.
- **`log.md`** is the scope's update history, **newest first**, grouped under
  `YYYY-MM-DD` headings (ISO 8601 — required). Entries are prose.

## Frontmatter (§4.1)

| Key | Status | Notes |
| --- | --- | --- |
| `type` | required | Open vocabulary, never registered centrally. Pick something self-explanatory; consumers tolerate unknown values. |
| `title` | recommended | Display name. Absent → derived from the filename. |
| `description` | recommended | One sentence. It is what `index.md` entries, search snippets and previews reuse — write it once, here. |
| `resource` | recommended | A URI for the underlying asset. Absent for abstract concepts. |
| `tags` | recommended | A YAML **list** of short strings — never a comma-separated string. |

Producers may add any other key; consumers preserve unknown keys when
round-tripping. **Every timestamp is ISO 8601 with an explicit UTC offset**:
`2026-06-30T14:00:00Z`, never a bare local time (§5).

## Provenance, trust, lifecycle (§5)

All optional. Absence carries meaning — an unverified concept is a valid state,
never an error.

- **`sources`** (§5.1) — what the concept derives from. Each entry needs a
  `resource`: a URL, a vault path (this vault uses `../sources/<slug>.md`), or a
  scope descriptor in prose. Optional `id`, `title`, and the credibility signals
  `author`, `usage_count`, `last_modified` (+ a sibling `usage_window`).
  **Per-claim attribution is a markdown footnote whose label is the `id`**
  (`claim.[^ga4-schema]`), keyed rather than positional so reordering the list
  never misattributes.
- **`generated`** (§5.2) — `{ by, at }`: who produced the current content and when
  it last meaningfully changed. `by` is required inside it.
- **`verified`** (§5.2) — a list of `{ by, at }` confirmation events, independent
  of `generated`. A single bare mapping counts as a one-element list.
- **Trust tiers** (§5.3), derived, never stored: no `verified` → *unverified*;
  only non-human verifiers → *machine-confirmed*; any `human:` verifier →
  *human-reviewed*.
- **`status`** (§5.4) — `draft`, `stable` (the default when absent) or
  `deprecated`. Only worth writing to say draft or deprecated.
- **`stale_after`** (§5.5) — an absolute instant; stale when `now >= stale_after`.

## The actor convention (§7)

`generated.by` and `verified[].by` are actors:

| Who | Form | Example |
| --- | --- | --- |
| An agent or tool | `<producer>/<version>` | `claude-code/claude-opus-5-5` |
| A person | `human:<id>` | `human:ahormati` |
| An automated process | `process:<id>` | `process:finance-nightly` |

**`human:` is a trust claim.** Tiers key off that prefix, so an agent never writes
`human:` for content it produced, and never adds a `verified` entry on a person's
behalf. Provenance you did not observe is not provenance — leave the key out.

## Links and paths (§6)

Standard markdown links. OKF accepts both the root-absolute form (`/folder/x.md`,
its recommendation) and the relative form (`./x.md`); **this vault uses relative
links only** (`ENGINE.md` says why). A link to a missing target is not malformed
in OKF — it may be knowledge not yet written — but the server's `audit` still
reports it, because in this vault it is usually a typo. A `references/` folder
conventionally mirrors external material and code (§6.3).

## v0.1 leftovers (§13.1)

Two fields were retired in v0.2, and this vault still carries both on older pages:

- **`timestamp` → `generated.at`.** Consumers fall back to `timestamp` when
  `generated` is absent, so the old pages stay readable. Migrating one means
  writing a `generated.by` too, and inventing an author for a page you did not
  write is worse than leaving it — migrating is a decision, not a cleanup.
- **A body `# Citations` list → `sources`.** Legacy lists may stay; new documents
  put their sources in frontmatter.

## What the Logbook server checks

| Diagnostic | Source | Meaning |
| --- | --- | --- |
| `invalid-frontmatter` | `frontmatter` | The YAML block does not parse — the page breaks the floor. An error, not a warning. |
| `missing-type` | `okf` | No `type`, or a blank one, on a non-reserved page — the floor again. |
| `no-wiki-links` | `okf` | A `[[wiki-link]]`: other OKF consumers render it as literal text and lose the edge. Use a markdown link. |
| `dead-link` | `links` | Only from `audit`: a link whose target is not in the vault. |
| `mermaid-parse-error` | `mermaid` | A fence mermaid will not draw. Also returned in `write`/`edit` `warnings`. |

Only the first two make a bundle non-conformant; fix those first. The app's REST
surface refuses to save a page that breaks the floor, but an MCP `write` is not
refused and its response does not mention it — the page lands, and only `lint` or
`audit` will say so. Give every new page its `type` in the same call that creates
it.
