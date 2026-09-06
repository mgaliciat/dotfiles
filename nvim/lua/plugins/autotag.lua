-- ─── nvim-ts-autotag ──────────────────────────────────────────
-- Typing `<div>` inserts `</div>`; renaming one side of a tag renames
-- the other. Uses the treesitter tree, so it knows a tag in a `.astro`
-- or `.tsx` from one in a string. Filetypes come from the plugin's own
-- list (html, tsx, jsx, astro, vue, svelte, xml, php, markdown…) — the
-- parsers for ours are in treesitter.lua.
--
-- `enable_close_on_slash` stays off: with it, typing `</` auto-completes
-- the closer, which collides with typing `</` on purpose to close a
-- different tag than the innermost one.

return {
  "windwp/nvim-ts-autotag",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = false,
    },
  },
}
