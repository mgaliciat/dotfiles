# logbook

One plugin, two hosts. Claude Code and Antigravity both load this directory in
place, through a symlink each installer creates, so a `git pull` is the whole
upgrade path.

| Host | Discovery | Manifest | Loads |
|---|---|---|---|
| Claude Code | `~/.claude/skills/logbook` | `.claude-plugin/plugin.json` | `skills/`, plus `hooks/logbook.{sh,ps1}` registered as a PostToolUse hook by the installers |
| Antigravity | `~/.gemini/config/plugins/logbook` | `plugin.json` | `skills/`, `rules/AGENTS.md` |

The skills invoke as `/logbook:<name>` on both hosts: `entry`, `ingest`, `query`,
`lint`, `task`, `run`, `template`, `okf`, and the four authoring skills `guide`,
`runbook`, `document`, `walkthrough`. Each SKILL.md reads `ENGINE.md` (the vault's
layers and MCP tools) and, for authoring, `AUTHORING.md` (the evidence rule) from this
root first, so the spec is single-source.

`skills/`, `ENGINE.md` and `AUTHORING.md` are copied from
[logbook-md/logbook-plugin](https://github.com/logbook-md/logbook-plugin) and carry its
version in both manifests; refresh them from there rather than editing them here. Its
`.mcp.json` and `hooks/hooks.json` stay out: the vault is registered by hand, and the
installers register this directory's own hooks, whose commit pattern also catches
`git -C` and `git -c`.

Everything writes through the `logbook-mcp` MCP server, a Logbook server (it replaced
OpenKnowledge on 2026-09-22 with the same tools, and was registered as `logmd` until
2026-09-28). Its URL and Cloudflare Access token are secrets, and which vault a machine
writes to is that machine's choice, so neither this plugin nor the installers register
it: each vault's 1Password item carries the one-line command that does.

The hook is Claude Code only. Antigravity gets the equivalent trigger as prose in
`rules/AGENTS.md`.
