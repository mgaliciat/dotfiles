# Logbook Plugin (Universal for Claude Code & Antigravity)

Unified plugin for **Claude Code** and **Antigravity** providing automated work-log capture, synthesis, document authoring, and vault linting backed by an **OpenKnowledge** vault.

---

## Directory Structure

```text
plugins/logbook/
├── .claude-plugin/
│   └── plugin.json          # Claude Code plugin manifest
├── plugin.json              # Antigravity plugin manifest
├── rules/
│   └── AGENTS.md            # Antigravity operational rules (always loaded when plugin is active)
├── hooks/
│   ├── logbook.ps1          # PostToolUse git-commit hook (Windows PowerShell)
│   └── logbook.sh           # PostToolUse git-commit hook (Linux / macOS Bash)
├── skills/                  # Skills exposed to both platforms (/logbook:<name>)
│   ├── document/SKILL.md
│   ├── entry/SKILL.md       # Capture immutable per-invocation work notes
│   ├── guide/SKILL.md
│   ├── ingest/SKILL.md      # Synthesize raw notes into cross-linked wiki pages
│   ├── lint/SKILL.md
│   ├── query/SKILL.md
│   ├── runbook/SKILL.md
│   ├── task/SKILL.md
│   └── walkthrough/SKILL.md
├── AUTHORING.md             # Shared authoring engine specification
├── ENGINE.md                # Shared runtime engine specification
└── README.md
```

---

## Compatibility

### 1. Claude Code
* **Manifest:** `.claude-plugin/plugin.json` specifies `"skills": "./skills/"`.
* **Invoking Skills:** Skills are namespaced with the plugin name:
  * `/logbook:entry`
  * `/logbook:ingest`
  * `/logbook:query`
  * `/logbook:guide`, `/logbook:runbook`, `/logbook:document`, `/logbook:walkthrough`
  * `/logbook:task`, `/logbook:lint`
* **Commit Hook:** `hooks/logbook.ps1` (or `.sh`) monitors successful `git commit` commands and automatically prompts the agent to invoke `/logbook:entry`.

### 2. Antigravity
* **Manifest:** `plugin.json` declares the plugin in `.agents/plugins/` or your global customizations.
* **Skills:** Automatically discovered under `skills/<skill_name>/SKILL.md`.
* **Rules:** `rules/AGENTS.md` is automatically loaded into the agent's context when the plugin is enabled, enforcing evidence-based documentation and vault interaction standards.
* **MCP:** Interacts with the `open-knowledge` MCP server configured either globally (`~/.gemini/config/mcp_config.json`) or via your environment.
