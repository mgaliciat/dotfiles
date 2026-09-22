# logbook

One plugin, two hosts. Claude Code and Antigravity both load this directory in
place, through a symlink each installer creates, so a `git pull` is the whole
upgrade path.

| Host | Discovery | Manifest | Loads |
|---|---|---|---|
| Claude Code | `~/.claude/skills/logbook` | `.claude-plugin/plugin.json` | `skills/`, plus `hooks/logbook.{sh,ps1}` registered as a PostToolUse hook by the installers |
| Antigravity | `~/.gemini/config/plugins/logbook` | `plugin.json` | `skills/`, `rules/AGENTS.md` |

The skills invoke as `/logbook:<name>` on both hosts: `entry`, `ingest`, `query`,
`lint`, `task`, and the four authoring skills `guide`, `runbook`, `document`,
`walkthrough`. Each SKILL.md reads `ENGINE.md` (the vault's layers and MCP tools)
and, for authoring, `AUTHORING.md` (the evidence rule) from this root first, so
the spec is single-source.

Everything writes through the `logmd` MCP server (it replaced OpenKnowledge on
2026-09-22 with the same tools). Its URL and Cloudflare Access token are secrets, so
no `mcp_config.json` ships here: `claude/install/binaries.sh` and
`install-windows.ps1` register the same server for both hosts from `LOGMD_MCP_URL`
and a 1Password template, `~/.config/claude/logmd-headers.json.op`.

The hook is Claude Code only. Antigravity gets the equivalent trigger as prose in
`rules/AGENTS.md`.
