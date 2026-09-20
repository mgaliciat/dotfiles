# Logbook & OpenKnowledge Rules

When this plugin is active, follow these rules for knowledge capture and vault interaction:

## 1. Core Principles
- **The vault is the source of truth, the LLM is a processing layer.** Knowledge must compound over time, not just accumulate.
- **Evidence over recollection:** Nothing lands in documentation from model memory or casual recollection. Every claim (flag, default, version, ordering, path) must trace to an opened file, command output, or vault page verified in the current session.
- **Vault paths:** Raw immutable notes live under `entries/YYYY-MM-DD-HHMM-<repo>.md`. Synthesized wiki pages live under `wiki/`. `logbook` is the tooling/plugin name, never a folder path in the vault.

## 2. Tooling
- Always use the `open-knowledge` MCP tools (`write`, `edit`, `search`, `links`, `exec`, `checkpoint`) to interact with the vault.
- Do not use standard filesystem tools (e.g. direct file writes) for remote or managed OpenKnowledge vaults.
- If the `open-knowledge` MCP server is unreachable, report it to the user rather than silently writing to temporary local files.

## 3. Capture Workflow (Logbook Entry)
- **Trigger:** After landing a `git commit` or opening a PR that closes a meaningful unit of work (not a WIP step), or when the user mentions "logbook", "bitácora", "guarda resumen", or invokes `/logbook:entry`:
  - Run the `logbook:entry` skill to write an immutable note in `entries/YYYY-MM-DD-HHMM-<repo>.md`.
  - Focus on the **why** and architectural rationale that git diffs do not preserve.
