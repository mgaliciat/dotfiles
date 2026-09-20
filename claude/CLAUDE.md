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

## A down MCP is never worked around

If a server's tools aren't available in the session, reaching that service by any other route is **forbidden** — no `curl` against its endpoint, no hand-rolled JSON-RPC handshakes, no touching the files behind it. Say the MCP isn't active and stop; the user reconnects it with `/mcp`.

`claude mcp list` can report "Connected" while the tools were never registered in the session — the real test is whether `ToolSearch` finds them.
