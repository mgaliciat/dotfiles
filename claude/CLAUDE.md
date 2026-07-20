# CLAUDE.md (user-level)

Preferences that apply to **every** project, not just this dotfiles repo — unlike a per-project `CLAUDE.md`, this travels with you to any machine/repo. Versioned and symlinked by `install.sh` to `~/.claude/CLAUDE.md`, same treatment as `claude/statusline.sh` (see this repo's `CLAUDE.md`, "per-machine split" section).

@RTK.md

## Tools installed by this dotfiles repo

### rtk — github.com/rtk-ai/rtk

A proxy CLI that rewrites common Bash commands (`git status`, `cargo test`, `npm test`, etc.) to their `rtk` equivalent, with filtered/compressed output to save context tokens. **No action needed on your side** — the `PreToolUse` hook (`rtk hook claude`) makes it transparent on every Bash call. Meta-command reference in `@RTK.md` (above) — e.g. `rtk gain` to see the accumulated savings.

### codebase-memory-mcp — github.com/DeusData/codebase-memory-mcp

MCP server that indexes each project's code into a persistent knowledge graph. **Prefer its tools over raw Grep/Glob/Read** for any structural code exploration:

- `search_graph` / `search_code` instead of grep to find functions, classes, routes
- `trace_path` for call chains (who calls what, data flow, cross-service)
- `get_code_snippet` to read a single function/class without opening the whole file
- `get_architecture` for a project overview (languages, entry points, hotspots, layers, clusters)
- `query_graph` for complex Cypher patterns (dead code, high complexity, etc.)
- `list_projects` to see which projects are already indexed (with their absolute `root_path`) and query them without being inside that folder
- If a project isn't indexed yet, run `index_repository` first

Grep/Glob/Read are still the right tools for plain text, configs, and non-code files.

It also installs the `codebase-memory` skill (self-activating on triggers like "explore the codebase", "who calls this function", "dead code", etc. — no need to invoke it by hand). It brings a decision matrix, exploration/tracing workflows, and Cypher examples for `query_graph` — more detail than this list. Use it whenever the trigger applies.

### context7 — github.com/upstash/context7

Hosted MCP server that injects **current** documentation for a library into context. Nothing is installed locally — `binaries.sh` only registers the endpoint, and the API key comes from the environment (`~/.zshenv.local`), so a machine without a key simply won't have these tools.

Two tools, used in order:

- `resolve-library-id` — turn a library name ("drizzle", "polars") into the id Context7 indexes it under
- `query-docs` — ask a question against that library's live docs

**Use it when the failure mode is a wrong API signature**, which is exactly where training-cutoff knowledge betrays you: a library released or reworked after the cutoff, a fast-moving one (most JS/TS tooling), or any time you're about to write a call from memory and aren't certain the signature is current. Cheaper to ask than to ship a plausible, wrong argument list and debug it later.

**Not** a general-purpose search: for the stable core of a mature language, or for anything not a library (configs, your own code, prose), it just costs a round-trip. Well-known and stable → answer directly.

### obsidian — github.com/coddingtonbear/obsidian-local-rest-api

MCP server for a **local, per-machine Obsidian vault** — the "Local REST API" community plugin ships its own MCP at `/mcp/`. `binaries.sh` only registers the HTTP endpoint (`127.0.0.1:27123`); the vault itself is never versioned (per-machine, like `~/.claude/skills/`), and the key comes from `~/.zshenv.local` (or a Windows user env var — `install-windows.ps1` replicates it too, since native Windows has no `~/.zshenv.local`).

**Use it for cross-repo notes**: durable knowledge that has to outlive a single repo — most relevant here, *which service touches which and why* across a set of shared services. Write a note from one repo, read it from another. This is the "why" layer; `codebase-memory-mcp` is the "what/when" layer (mechanical call graph, `trace_path cross_service`). They complement — graph for the code, vault for the rationale.

**Requires Obsidian OPEN** with the plugin + its MCP server enabled — that is the cost of the real-Obsidian path (Dataview, atomic patch by heading) over plain `Read`/`Write` on the markdown. If Obsidian is closed, the tools fail; fall back to reading the vault files directly on disk.

## Daily log (bitácora) in Obsidian

The full how-to lives in the versioned **`bitacora` skill** (`claude/skills/bitacora/`, symlinked into `~/.claude/skills/` by the installer) — it self-activates on "bitácora" / "guarda resumen" and holds the format, path, and tagging. Off the always-loaded budget on purpose. The one thing a skill *can't* do is fire on a git event, so the trigger that belongs here: **after you land a `git commit` or open a PR, invoke the bitacora skill** to log what changed and why as a new per-invocation note.
