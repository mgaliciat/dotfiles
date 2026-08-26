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

# ── no plugins installed right now ──
# `ponytail` and `andrej-karpathy-skills` lived here until aug-2026; both were
# always-on rulesets ("be lazy", "don't over-build") injected into every session,
# and they were dropped. The mechanism stays — adding one back is a single
# _claude_plugin_install call with the full https:// marketplace URL, the
# `plugin@marketplace` id from the repo's .claude-plugin/marketplace.json (NOT
# from its README, which often lags a transfer), and a label.
