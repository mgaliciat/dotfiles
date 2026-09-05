-- ─── blink.cmp ────────────────────────────────────────────────
-- Completion engine. Faster than nvim-cmp (written in Rust),
-- simpler API, default in LazyVim 2025. Replaces nvim-cmp +
-- LuaSnip + cmp-* sources.
--
-- Default keymaps ("default" preset):
--   <C-space> open menu / docs
--   <C-n> / <C-p> next / previous
--   <CR> accept
--   <Tab> / <S-Tab> snippet jumps
--   <C-e> cancel

return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  version = "*",                          -- uses the precompiled binary release (no Rust toolchain required)
  opts = {
    keymap = { preset = "default" },
    appearance = {
      use_nvim_cmp_as_default = true,     -- highlights compatible with themes that don't support blink yet
      nerd_font_variant = "mono",
    },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      menu = { border = "rounded" },
      ghost_text = { enabled = false },   -- ghost text overlaps uglily with inlay hints; disabled
    },
    signature = { enabled = true, window = { border = "rounded" } },
    sources = {
      default = { "lazydev", "lsp", "path", "snippets", "buffer" },
      providers = {
        -- lazydev's completions (nvim API, plugin types) outrank lua_ls's own
        -- for the same symbol; without the offset both show and lua_ls's
        -- untyped one wins the sort.
        lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
      },
    },
  },
}
