# shellcheck shell=bash
# ─── Claude Code: marketplace plugins ───
#
# Mechanism 3 of 3 (see claude/install/README.md). No binaries, no jq: the Claude
# Code CLI does all the work (clones the marketplace, installs the plugin, writes
# extraKnownMarketplaces + enabledPlugins into settings.json).
# It is the cheapest way to add new skills/hooks — two lines.
#
# Sourced by install.sh and install-linux.sh — NOT a standalone executable.
# install-windows.ps1 replicates this by hand (PowerShell cannot source bash);
# there the block must run AFTER the script writes settings.json, or our write
# clobbers the enabledPlugins the CLI just put there.

# $1 = marketplace URL, $2 = plugin@marketplace, $3 = human-readable name.
#
# FULL https:// URL, never the `owner/repo` shorthand: the shorthand clones over
# SSH (git@github.com:...) and fails on a fresh machine with no SSH key registered
# on GitHub (verified by comparing the clone log of both forms).
#
# `</dev/null` on both commands: running install.sh in a real terminal, one of
# them hung waiting for an invisible interactive prompt. Closed stdin → EOF → the
# command continues with its default (same fix as rtk in binaries.sh).
#
# Idempotence: handled by the CLI itself (verified by running both commands twice
# in a row — the second detects "already on disk" / "already installed", it does
# not fail nor duplicate), so we invoke them on every run with no guard.
_claude_plugin_install() {
  local url="$1" plugin="$2" label="$3"

  if claude plugin marketplace add "$url" >/dev/null 2>&1 </dev/null; then
    echo "✓ $label: marketplace added (or already there)"
  else
    echo "⚠️  could not add the $label marketplace — check by hand"
  fi

  # Scope `-s user`: active in ALL projects, not just this repo.
  if claude plugin install "$plugin" -s user >/dev/null 2>&1 </dev/null; then
    echo "✓ $label: plugin installed (or already there)"
  else
    echo "⚠️  could not install $label — check by hand (claude plugin install $plugin)"
  fi
}

if ! command -v claude >/dev/null 2>&1; then
  echo "ℹ️  claude not detected in PATH — skipping plugins"
  return 0 2>/dev/null || exit 0
fi

# ── ponytail — "lazy senior dev" ──
# A single `install` brings the plugin AND its 6 bundled skills (ponytail,
# ponytail-review, ponytail-audit, ponytail-debt, ponytail-gain, ponytail-help)
# — there is no separate step for the skills. It stays active in ALL sessions
# (ruleset always injected): `/ponytail off` turns it off per session,
# PONYTAIL_DEFAULT_MODE=off by default. ~983 always-on tokens.
# Doc: https://github.com/DietrichGebert/ponytail
if ! command -v node >/dev/null 2>&1; then
  # The plugin's hooks are Node.js. Without node it still installs, but automatic
  # activation goes mute instead of erroring on every prompt (behavior documented
  # by the project). We do not force it as a hard dependency.
  echo "ℹ️  node not detected — ponytail installs anyway, but its automatic activation hooks will stay mute until node is in PATH"
fi
_claude_plugin_install \
  "https://github.com/DietrichGebert/ponytail" \
  "ponytail@ponytail" \
  "ponytail"

# ── andrej-karpathy-skills — behavior guidelines ──
# Think before coding, simplicity, surgical changes, goal-driven execution with
# tests. Lighter than ponytail: 1 skill, no hooks, no node (~103 tokens).
# Intentional overlap with ponytail on "do not over-build" — different emphasis
# (process/communication vs. concrete lines of code) and the extra cost of having
# both active is marginal.
#
# The marketplace/plugin names come from the repo's .claude-plugin/marketplace.json,
# NOT from the README: the README still points at forrestchang/andrej-karpathy-skills,
# the name from before it was transferred to multica-ai (GitHub redirects, but we use
# the current one).
# Doc: https://github.com/multica-ai/andrej-karpathy-skills
_claude_plugin_install \
  "https://github.com/multica-ai/andrej-karpathy-skills" \
  "andrej-karpathy-skills@karpathy-skills" \
  "andrej-karpathy-skills"
