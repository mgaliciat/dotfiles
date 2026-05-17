-- ─── blink.cmp ────────────────────────────────────────────────
-- Completion engine. Más rápido que nvim-cmp (escrito en Rust),
-- API más simple, default en LazyVim 2025. Sustituye nvim-cmp +
-- LuaSnip + cmp-* sources.
--
-- Keymaps default ("default" preset):
--   <C-space> abrir menu / docs
--   <C-n> / <C-p> siguiente / anterior
--   <CR> aceptar
--   <Tab> / <S-Tab> snippet jumps
--   <C-e> cancelar

return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  version = "*",                          -- usa el release binario precompilado (no requiere Rust toolchain)
  opts = {
    keymap = { preset = "default" },
    appearance = {
      use_nvim_cmp_as_default = true,     -- highlights compatibles con themes que aún no soportan blink
      nerd_font_variant = "mono",
    },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      menu = { border = "rounded" },
      ghost_text = { enabled = false },   -- ghost text se solapa feo con inlay hints; desactivado
    },
    signature = { enabled = true, window = { border = "rounded" } },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
