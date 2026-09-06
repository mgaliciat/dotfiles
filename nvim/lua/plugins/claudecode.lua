-- ─── claudecode.nvim ──────────────────────────────────────────
-- Claude Code as an IDE client of nvim. NOT a CLI wrapper: it speaks the
-- same MCP-over-WebSocket protocol as Anthropic's VS Code / JetBrains
-- extensions (a lock file in ~/.claude/ide/<port>.lock, token auth), so
-- Claude sees the open file and the selection in real time, `@`-mentions
-- resolve to buffers, and every edit it proposes lands as a diff HERE with
-- accept / deny — instead of appearing on disk unreviewed.
--
-- Provider `external`: nvim only runs the WebSocket server; the Claude
-- session stays the tmux one. `external_terminal_cmd` below reproduces
-- `Alt+c` from tmux/utility.conf exactly — same `claude-<md5 of cwd>`
-- session name, same 90% popup, same `@claude_origin` for the bell — so
-- `<leader>ac` from nvim and `Alt+c` from the shell reach ONE conversation
-- per directory. A session that `Alt+c` started before nvim was open lacks
-- the IDE env vars: type `/ide` inside it once and it connects.
--
-- History: this plugin was in the repo (f1b809d) and dropped (f06182a) as
-- "the tmux popup is enough". The popup has no editor context and no diff
-- review; the external provider keeps the popup and adds exactly those.

-- Called by the plugin with the Claude command line and the IDE env
-- (ENABLE_IDE_INTEGRATION, CLAUDE_CODE_SSE_PORT). Returns argv, not a
-- string: a string gets parsed into arguments without a shell, so a `;`
-- pipeline has to go through `sh -c` explicitly.
local function tmux_popup_cmd(claude_cmd, env_table)
  local q = vim.fn.shellescape
  local cwd = vim.fn.getcwd()
  -- Same hash as utility.conf: `echo <path> | md5sum | cut -c1-8` — echo's
  -- trailing newline is part of the digest, so it stays a shell pipeline.
  local hash = vim.trim(vim.fn.system({ "sh", "-c", "echo " .. q(cwd) .. " | md5sum | cut -c1-8" }))
  local session = "claude-" .. hash
  local origin = vim.trim(vim.fn.system({ "tmux", "display-message", "-p", "#{window_id}" }))

  -- The plugin hands the env to jobstart, but `tmux new-session -d` runs its
  -- command inside the tmux SERVER, which never sees a client's env. So the
  -- vars ride inline on the command; without them Claude starts unconnected
  -- and you'd need `/ide` by hand.
  local env = {}
  for k, v in pairs(env_table or {}) do
    env[#env + 1] = k .. "=" .. q(tostring(v))
  end
  local launch = "env " .. table.concat(env, " ") .. " " .. claude_cmd
  -- caffeinate keeps the Mac awake while Claude works, as Alt+c does.
  local new_session = ("tmux new-session -d -s %s -c %s %s"):format(
    q(session), q(cwd),
    q("command -v caffeinate >/dev/null 2>&1 && exec caffeinate -di " .. launch .. " || exec " .. launch)
  )
  local script = table.concat({
    ("tmux has-session -t %s 2>/dev/null || %s"):format(q(session), new_session),
    ("tmux set-option -t %s @claude_origin %s"):format(q(session), q(origin)),
    ("tmux display-popup -w90%% -h90%% -E %s"):format(q("tmux attach-session -t " .. session)),
  }, "; ")
  return { "sh", "-c", script }
end

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = {
    "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSend", "ClaudeCodeAdd",
    "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny", "ClaudeCodeSelectModel",
    "ClaudeCodeStart", "ClaudeCodeStop", "ClaudeCodeStatus", "ClaudeCodeTreeAdd",
  },
  -- Server up at startup (auto_start) so a Claude launched from the shell
  -- can `/ide` into this nvim without a keymap having been pressed first.
  event = "VeryLazy",
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Claude: open popup (this dir's session)" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Claude: resume a session" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Claude: continue last" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Claude: select model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Claude: add buffer to context" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        desc = "Claude: send selection", mode = "v" },
    { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",     desc = "Claude: add file from tree", ft = { "neo-tree", "oil" } },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "Claude: accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "Claude: deny diff" },
    { "<leader>aS", "<cmd>ClaudeCodeStatus<cr>",      desc = "Claude: connection status" },
  },
  opts = {
    auto_start = true,
    track_selection = true,
    -- The popup is a separate tmux client, so "focus the terminal after
    -- sending" has nothing to focus inside nvim.
    focus_after_send = false,
    terminal = {
      provider = "external",
      provider_opts = { external_terminal_cmd = tmux_popup_cmd },
    },
    diff_opts = {
      layout = "vertical",           -- old | new, like every other diff in this config
      open_in_new_tab = true,        -- review in its own tab; `q`/accept/deny returns you
      auto_resize_terminal = false,  -- no in-nvim terminal to resize
    },
  },
}
