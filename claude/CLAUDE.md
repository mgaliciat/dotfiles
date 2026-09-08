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

## No attribution trailers in commits or PRs

**Never add a `Co-Authored-By: Claude …` trailer** — or any other authorship footer or "generated with" line — to a git commit message or a pull request description. This holds for every route that writes on the user's behalf: `git commit`, `gh pr create`, the GitHub web UI, a git GUI, or any app/MCP that opens a PR.

Why: the commit is the user's. The trailer adds a line of noise to every entry in a history that is read far more often than it is written, and it names a co-author nobody can actually ask about the change.

**The `Claude-Session:` permalink is the one exception, and it is allowed.** When the harness asks for it, add it. It is not an authorship claim — it is a link back to the conversation that produced the change, which is the one thing a reader of that commit cannot reconstruct and might actually want. The banned trailer names a co-author nobody can ask; this one names the transcript.

The `attribution` key in `settings.json` already stops the harness from injecting it; this rule covers what that setting can't reach — a PR body composed by hand, a commit made through another tool, a machine whose settings predate the change.

If a repo's own convention *requires* a trailer, that repo wins — same precedence as the English-only rule above.

## Verify against a source, never against the conversation

**Every factual claim gets checked against something outside this session** — the code itself, the tool's own output, its live docs, the vault. Training memory and what was said earlier in the conversation are *leads*, not evidence. If a claim can't be traced to a source, say it's unverified rather than asserting it.

The source depends on the claim, and the tools below are the instruments:

- **A tool's own config, flags or API surface** → ask the binary. `gopls api-json`, `<tool> --help`, `ghostty +show-config`, `ghostty +list-keybinds`, `brew info`, `--version`. A tool is the only authority on itself.
- **A product's documented behaviour** (Claude Code's settings, an API's contract) → fetch the doc page. Don't quote a flag or a key from memory.
- **A performance or size claim** → measure it here. Never repeat a README's benchmark as if it described this machine.
- **A library's signatures, this codebase's structure, or why one of our systems is the way it is** → the three MCPs below, each of which states its own trigger and its own limits. Those sections are the detail; this is only the reminder that recall is not one of the options.

**The failure this prevents is specific**: an assertion that is plausible, confidently worded, and wrong — which costs more than saying nothing, because it gets acted on. It hides especially well in config, where a wrong key is usually a *silent no-op* rather than an error: `completeUnimported` and `analyses.useany` sat in the gopls block for months looking load-bearing after gopls had removed both, and only `gopls api-json` said so. Same shape as the `rg` vs `tgrep` benchmark below, and as the `+list-fonts` rule in the project `CLAUDE.md`: **enumerate, don't trust the config.**

This is not a licence to re-derive settled facts. Something established *in this session by an actual check* stays established — don't re-run it. The rule is about the first assertion, not about repeating the verification.

## Tools installed by this dotfiles repo

**A down MCP is never worked around.** If a server's tools aren't available in the session, reaching that service by any other route is **forbidden** — no `curl` against its endpoint, no hand-rolled JSON-RPC handshakes, no touching the files behind it. Say the MCP isn't active and stop; the user reconnects it with `/mcp`. Note that `claude mcp list` can report "Connected" while the tools were never registered in the session — the real test is whether `ToolSearch` finds them.

Each tool's own schema and skill say what it does. What follows is only what neither of those will tell you.

**rtk** — a `PreToolUse` hook rewrites Bash calls transparently; nothing to invoke. Its filtering truncates, so `tee = "always"` in our `claude/install/rtk-config.toml` leaves a recoverable log: when output looks cut, the inline `[see remaining: tail -n +N <log>]` marker is real — read that log instead of re-running the command. `rtk proxy <cmd>` bypasses filtering for one call. Never quote `rtk gain` as money or tokens saved: it is a counterfactual, and the one independent measurement ([JetBrains, jul-2026](https://blog.jetbrains.com/ai/2026/07/rtk-claude-code-token-savings/)) found no saving and no quality change.

**codebase-memory-mcp** — prefer it over raw Grep/Glob/Read for *structural* code questions (call chains, who-calls-what, dead code); run `index_repository` if the project isn't indexed. Grep/Glob/Read remain right for plain text, configs and non-code files.

**context7** — for a library's current API signature, which is exactly where training-cutoff knowledge betrays you. Not a general-purpose search: for a mature language's stable core, or anything that isn't a library, it just costs a round-trip.

**open-knowledge** — the cross-repo *why* layer (which service touches which and the reasoning), against codebase-memory-mcp's mechanical *what*. Use the vault's own `exec`/`search`, never `Read`/`Grep`: the vault is remote and its tools return frontmatter, backlinks and attribution with the text. **`write` with `position: replace` overwrites a whole document** — use `edit` on anything that already exists.

## Logbook — the daily log and its wiki

A `PostToolUse` hook fires `/logbook:entry` after every `git commit`. **Deciding whether that commit is a unit of work or a WIP step is yours** — say so and skip when it isn't, rather than writing a note per commit.

The vault's layout, language rule and note format are deliberately not here: `ENGINE.md` carries them for the synthesis skills, `entry/SKILL.md` for capture, `AUTHORING.md` for the four that author documents (`/logbook:guide`, `/logbook:runbook`, `/logbook:document`, `/logbook:walkthrough` → `guides/`, `runbooks/`, `docs/`, `flows/`), and the vault's own `wiki/CLAUDE.md` outranks all of them.

**Those four are the "verify against a source" rule above, made into a workflow** — they build a document from the code, the binaries' own output, the vault and (gated) captured web sources, and cut or mark any claim that only came from the conversation.

**`/logbook:walkthrough` takes it one step further**: it traces one process end to end and every node of every mermaid diagram carries a `file:line` anchor, pinned to a recorded commit SHA. That makes the page **re-verifiable mechanically** — `git diff <sha>..HEAD` over the anchor paths says whether it may have gone stale — instead of only verified at the moment it was written. An edge it could not resolve (async hop, DI binding, dynamic dispatch) is drawn as unresolved rather than guessed.
