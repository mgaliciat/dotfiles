# CLAUDE.md (user-level)

General working rules that hold in **every** project — unlike a per-project `CLAUDE.md`, this travels to any machine and any repo. So nothing specific to one project belongs here, and neither does a description of a skill, an MCP or a tool: those announce themselves, and the user says which to use.

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

**A repo's own convention wins** — same precedence as the English-only rule above. When the surrounding code carries dense *why* comments on purpose, and says so, match it. Matching an existing style is not the same as adding narration: the bullets above stay banned everywhere.

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

- **A tool's own config, flags or API surface** → ask the binary: `<tool> --help`, `--version`, and whatever subcommand dumps its resolved config or lists what it actually has registered. A tool is the only authority on itself.
- **A product's documented behaviour** (Claude Code's settings, an API's contract) → fetch the doc page. Don't quote a flag or a key from memory.
- **A performance or size claim** → measure it here. Never repeat a README's benchmark as if it described this machine.
- **A library's signatures, or this codebase's structure** → a tool that can actually look it up. Whichever ones the session has, each states its own trigger and its own limits; the point here is only that recall is not one of the options.

**The failure this prevents is specific**: an assertion that is plausible, confidently worded, and wrong — which costs more than saying nothing, because it gets acted on. It hides especially well in config, where a wrong key is usually a *silent no-op* rather than an error: a setting the tool dropped releases ago sits there looking load-bearing, and only the binary's own output says otherwise. **Enumerate, don't trust the config.**

This is not a licence to re-derive settled facts. Something established *in this session by an actual check* stays established — don't re-run it. The rule is about the first assertion, not about repeating the verification.

## A down MCP is never worked around

If a server's tools aren't available in the session, reaching that service by any other route is **forbidden** — no `curl` against its endpoint, no hand-rolled JSON-RPC handshakes, no touching the files behind it. Say the MCP isn't active and stop; the user reconnects it with `/mcp`.

`claude mcp list` can report "Connected" while the tools were never registered in the session — the real test is whether `ToolSearch` finds them.
