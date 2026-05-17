-- ─── claudecode.nvim ──────────────────────────────────────────
-- Integración Claude Code dentro de nvim. NO es un wrapper del CLI —
-- implementa el protocolo MCP/WebSocket que usa la extensión oficial
-- de VSCode, así que tenés paridad real: send-selection con diff view,
-- @-mentions, accept/deny inline.
--
-- Pre-requisitos:
--   - claude CLI en PATH (`npm i -g @anthropic-ai/claude-code`)
--   - snacks.nvim (dependencia para el terminal embebido)
--
-- Prefijo de keymaps: <leader>a (AI). Lazy-load por keys → el plugin
-- no se carga hasta la primera vez que tocás <leader>a*.

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    { "<leader>a",  nil,                              desc = "AI / Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume session" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue task" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer to context" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        desc = "Send selection", mode = "v" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "Deny diff" },
  },
}
