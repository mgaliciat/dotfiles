# logbook

One plugin, two hosts. Claude Code and Antigravity both load this directory in
place, through a symlink each installer creates, so a `git pull` is the whole
upgrade path.

| Host | Discovery | Manifest | Loads |
|---|---|---|---|
| Claude Code | `~/.claude/skills/logbook` | `.claude-plugin/plugin.json` | `skills/`, plus `hooks/logbook.{sh,ps1}` registered as a PostToolUse hook by the installers |
| Antigravity | `~/.gemini/config/plugins/logbook` | `plugin.json` | `skills/`, `rules/AGENTS.md` |

The skills invoke as `/logbook:<name>` on both hosts: `entry`, `ingest`, `query`,
`lint`, `task`, `run`, and the four authoring skills `guide`, `runbook`, `document`,
`walkthrough`. Each SKILL.md reads `ENGINE.md` (the vault's layers and MCP tools)
and, for authoring, `AUTHORING.md` (the evidence rule) from this root first, so
the spec is single-source.

Everything writes through the `logbook-mcp` MCP server, a logmd server (it replaced
OpenKnowledge on 2026-09-22 with the same tools, and was registered as `logmd` until
2026-09-28). Its URL and Cloudflare Access token are secrets, and which vault a machine
writes to is that machine's choice, so neither this plugin nor the installers register
it: each vault's 1Password item carries the one-line command that does.

The hook is Claude Code only. Antigravity gets the equivalent trigger as prose in
`rules/AGENTS.md`.
