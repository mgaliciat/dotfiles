-- ─── nvim-bqf ─────────────────────────────────────────────────
-- Better quickfix window, now that the quickfix is a real destination
-- here: `<C-q>` from any telescope picker, `<space>q` from grug-far,
-- `:cdo` for bulk edits. What it adds on top of the stock window:
--
--   • a floating preview of the entry under the cursor (`p` toggles it,
--     `<C-f>` / `<C-b>` scroll it), so you read the context without
--     leaving the list
--   • `zf` opens fzf over the entries — type to filter, `<Tab>` to mark,
--     `<CR>` builds a NEW quickfix list from the marks (that is how you
--     turn 200 grep hits into the 12 that matter before `:cdo`)
--   • `<Tab>` / `<S-Tab>` sign an entry, `zn` / `zN` new list from the
--     signed / unsigned ones, `<` / `>` older / newer list
--
-- fzf filtering needs the junegunn/fzf vim plugin for `fzf#run`; the
-- `fzf` binary itself comes from brew (install.sh), so no `build` step.
-- Trouble.nvim was the alternative and lost: it is a whole panel that
-- overlaps glance (LSP lists) and telescope (diagnostics, todos); bqf
-- improves the window nvim already has.

return {
  "kevinhwang91/nvim-bqf",
  ft = "qf",
  dependencies = { "junegunn/fzf" },
  opts = {
    auto_resize_height = true,
    preview = {
      auto_preview = true,
      win_height = 15,
      winblend = 0,
    },
  },
}
