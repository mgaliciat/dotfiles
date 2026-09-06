-- ─── mini.pairs ───────────────────────────────────────────────
-- Auto-close `()[]{}""''``` while typing, and `<BS>` / `<CR>` between a
-- pair delete / expand both sides. Chosen over nvim-autopairs because it
-- has no completion-engine hook to keep in sync — blink.cmp accepts on
-- <CR> through its own keymap and mini.pairs only sees the <CR> that
-- reaches the buffer, so the two never fight.
--
-- `skip_next` / `skip_ts` / `skip_unbalanced` are the three guards that
-- keep it from being annoying: no pair when the next char is a word
-- char or the same closer (`foo|bar`, `"|"`), no quote pairing inside a
-- string or comment node, no closer when the line already has more
-- closers than openers. `markdown` pairs ``` fences.

return {
  "nvim-mini/mini.pairs",
  event = "InsertEnter",
  opts = {
    modes = { insert = true, command = true, terminal = false },
    skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
    skip_ts = { "string", "comment" },
    skip_unbalanced = true,
    markdown = true,
  },
}
