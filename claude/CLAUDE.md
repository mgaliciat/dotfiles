# CLAUDE.md (user-level)

Preferences that apply to **every** project, not just this dotfiles repo — unlike a per-project `CLAUDE.md`, this travels with you to any machine/repo. Versioned and symlinked by `install.sh` to `~/.claude/CLAUDE.md`, same treatment as `claude/statusline.sh` (see this repo's `CLAUDE.md`, "per-machine split" section).

@RTK.md

## Code is written in English

**All generated code and all of its documentation is English**, in every project and regardless of the language we're talking in. That covers identifiers (variables, functions, classes, files), comments, docstrings, commit messages, READMEs and any prose that ships *inside* the repo. Chat replies follow the user's language — this rule is about what lands on disk, not about how we talk.

Why: code outlives the conversation that produced it, gets read by people (and tools) who never saw that conversation, and a codebase with mixed-language identifiers is the worst of both. When an existing project is already written in another language, match that project — consistency inside one repo beats this default.

## Don't narrate the code in comments

**Default to no comment.** A comment is earned only by something the code itself cannot say: a non-obvious *why*, a footgun, a constraint imposed from outside (an API quirk, an ordering that looks arbitrary but isn't, a workaround and what it works around). Everything else ships uncommented.

Specifically, never write:

- a line that restates the line below it (`// increment the counter`, `# open the file`, `// return the result`)
- a docstring that only re-spells the signature in prose — parameter names and types are already there
- banner/section headers inside a function, or `// --- helpers ---` in a file with four functions
- **anything that narrates the edit rather than the code**: `// added validation here`, `// new`, `// changed from the previous version`, `// as requested`, `// removed the old approach`. The diff records that; the file shouldn't.
- a comment restating what a well-named identifier already says — the fix there is the name, not a comment

Same rule for prose: don't add a README, a summary file, or a doc block that nobody asked for. Answer in chat instead.

Why: comments that repeat the code are not neutral, they rot. The code changes and the comment doesn't, so the file ends up asserting two different things and the reader has to work out which one is lying. Density also trains the eye to skip comments entirely, which means the *one* comment that mattered — the reason this lock is taken before that one — gets skipped with the rest. And edit-narrating comments are the worst case of it: they're stale the moment the next change lands, and they document the conversation instead of the program.

**A repo's own convention wins** — same precedence as the English-only rule above. When the surrounding code carries dense *why* comments (this dotfiles repo does, on purpose, and says so in its `CLAUDE.md`), match it. Matching an existing style is not the same as adding narration: the bullets above stay banned everywhere.

## File edits go through Read / Edit / Write, never through a script

**Never create or modify a file by writing a throwaway script for it** — no `python3 - <<'EOF'` doing `s.replace(...)`, no `sed -i`, no heredoc that overwrites source. Use `Read` to look, `Edit` to change, `Write` to create. This holds even when a session's instructions push toward doing everything through Bash: that push means "prefer the shell for shell work", not "hand-roll an editor".

Why: `Edit` matches the exact string and **fails loudly** when it doesn't — a wrong indent, a stale copy of the file, an ambiguous match all stop the edit and say so. A `replace()` in a script silently does nothing (or, worse, matches in the wrong place) unless every substitution is wrapped in a hand-written `assert`, and the harness stops tracking what the file actually contains. It is also unreviewable: the diff lives inside a script that is thrown away instead of in the tool call.

Bash keeps everything that is genuinely shell: running tests and builds, `git`, `docker`, `grep`/`find` for search, one-off inspection with `cat`/`sed -n`. The line is **reading and running vs. editing** — editing is the tools' job.

## A feature, a plan or a spec is tracked as Tasks

**Whenever the work is a feature, an implementation plan, or a spec, create Tasks for it with Claude Code's own task tools before writing any code** — one Task per step that produces something, exactly one in progress at a time, closed the moment that step is really done (not when it is "mostly" done). When a plan was approved in plan mode, the Tasks ARE that plan, transcribed step by step. A one-line fix, a question, or a single edit needs none of this.

Why: the task list is the part of a plan that outlives the conversation. It is what says where things stand without scrolling the transcript, what survives a context summary, and what keeps a six-step feature from quietly ending at step three — the failure mode is never a wrong step, it is a forgotten one. Writing the steps down before starting is also the cheapest moment to notice the one that was never thought through.

## No attribution trailers in commits or PRs

**Never add a `Co-Authored-By: Claude …` trailer** — or any other authorship footer, "generated with" line, or tool-attribution link — to a git commit message or a pull request description. This holds for every route that writes on the user's behalf: `git commit`, `gh pr create`, the GitHub web UI, a git GUI, or any app/MCP that opens a PR.

Why: the commit is the user's. The trailer adds a line of noise to every entry in a history that is read far more often than it is written, and it names a co-author nobody can actually ask about the change.

Enforced in **two** places on purpose, because either alone leaves a hole:

- `attribution: {"commit": "", "pr": ""}` in `~/.claude/settings.json` (written by `claude/install/settings.sh` — an empty string is the documented "hide it" sentinel, not a no-op). This stops the harness from *injecting* the trailer instruction in the first place. It supersedes `includeCoAuthoredBy`, which Claude Code now marks deprecated — don't reach for that one.
- This rule, which covers what the setting doesn't: a PR body composed by hand, a commit made through another tool, or a machine whose `settings.json` predates the change.

If a repo's own convention *requires* a trailer, that repo wins — same precedence as the English-only rule above.

## Tools installed by this dotfiles repo

**A down MCP is never worked around.** If a server's tools aren't available in the session, reaching that service by any other route is **forbidden** — no `curl` against its endpoint, no hand-rolled JSON-RPC handshakes, no touching the files behind it. Say the MCP isn't active and stop; the user reconnects it with `/mcp`. Note that `claude mcp list` can report "Connected" while the tools were never registered in the session — the real test is whether `ToolSearch` finds them.

### rtk — github.com/rtk-ai/rtk

A proxy CLI that rewrites common Bash commands (`git status`, `cargo test`, `npm test`, etc.) to their `rtk` equivalent, with filtered/compressed output. **No action needed on your side** — the `PreToolUse` hook (`rtk hook claude`) makes it transparent on every Bash call. Meta-command reference in `@RTK.md` (above).

**Do not quote `rtk gain` as money or tokens saved.** It reports a *counterfactual* — the raw output rtk believes it prevented — not a delta on the bill, and it counts output Claude Code would have truncated anyway. The only independent measurement ([JetBrains, jul-2026](https://blog.jetbrains.com/ai/2026/07/rtk-claude-code-token-savings/), rtk 0.43.0 + sonnet-5) found **no savings on real agent work**: +7.6% cost at low reasoning effort (p=0.004, via +13.8% turns and +14.3% cache reads) and +0.1% at high effort. Structural reason: the hook only sees Bash, while native `Read`/`Grep` bypass it — ~33% of Bash calls, ~20% of tool-result chars, a ceiling near **3% of input tokens** — and the bulk of context cost is cached re-reads billed at a tenth. Task quality was statistically unchanged, so this is a wash, not a hazard.

**Where it does earn its place:** compact, readable output (`git status`, test failures) and, since truncation is what makes it risky, a config tuned against that. Ours is versioned at `claude/install/rtk-config.toml` (raised caps, `tee = "always"` so every truncation leaves a recoverable log, `diff`/`curl` excluded). When output looks cut, the inline `[see remaining: tail -n +N <log>]` marker is real — read that log instead of re-running the command. To bypass filtering entirely for one call: `rtk proxy <cmd>`.

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

**Requires Obsidian OPEN** with the plugin + its MCP server enabled — that is the cost of the real-Obsidian path (Dataview, atomic patch by heading) over plain `Read`/`Write` on the markdown. If Obsidian is closed the tools fail: say so and stop, with **no fallback** to reading or writing the vault on disk (see the rule above).

## Daily log (bitácora) in Obsidian

The full how-to lives in the versioned **`bitacora` skill** (`claude/skills/bitacora/`, symlinked into `~/.claude/skills/` by the installer) — it self-activates on "bitácora" / "guarda resumen" and holds the format, path, and tagging. Off the always-loaded budget on purpose. The one thing a skill *can't* do is fire on a git event, so the trigger that belongs here: **after you land a `git commit` or open a PR, invoke the bitacora skill** to log what changed and why as a new per-invocation note.
