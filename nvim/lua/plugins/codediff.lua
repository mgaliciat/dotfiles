-- ─── codediff.nvim ────────────────────────────────────────────
-- The REVIEW half of git-in-nvim (lazygit, in snacks.lua, is the OPERATE half): VS Code's
-- diff, ported to C. Two-tier highlighting — the changed LINE gets the
-- DiffAdd/DiffDelete tint, the changed CHARACTERS inside it get a brighter
-- one — so a one-word edit shows the word, not the whole line painted.
-- Side-by-side or inline (`t` toggles), moved-line detection, `gc` folds
-- the unchanged stretches, an explorer of changed files with stage /
-- unstage, commit history, 3-way conflicts, and `:CodeDiff pr <n>`.
--
-- Replaced diffview.nvim (sep-2026): same jobs, prettier output, and one
-- thing diffview never had — the character-level pass. Binary is
-- downloaded prebuilt; no compiler involved.
--
-- Keys under <leader>g beside gitsigns (gs/gr/gp/gb) and lazygit (gg/gl/gL);
-- the commit PICKERS (gf/gF) live in plugins/git-history.lua and land here.
-- No repo-wide `CodeDiff history` key: `<leader>gf` (telescope over the
-- same commits, with search) opens the chosen one here, and `<leader>gl`
-- is lazygit's log — a third view of the log was one too many.

return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  keys = {
    { "<leader>gv", "<cmd>CodeDiff<cr>",           desc = "CodeDiff: working tree" },
    { "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "CodeDiff: file history" },
    -- PR-style review: merge-base of origin/HEAD vs the working tree, so
    -- commits that landed on the base since branching don't show as yours.
    { "<leader>gB", "<cmd>CodeDiff origin/HEAD...<cr>", desc = "CodeDiff: branch vs base" },
    { "<leader>gh", ":'<,'>CodeDiff history<cr>", mode = "v", desc = "CodeDiff: history of selection" },
  },
  opts = {
    diff = {
      layout = "side-by-side",
      -- Old on the left, new on the right: the reading order of every
      -- other diff tool in the stack (delta, GitHub, diffview before it).
      original_position = "left",
    },
    explorer = {
      position  = "left",
      width     = 35,
      view_mode = "tree",
      auto_refresh = true,
    },
    -- Colours are NOT set here: line tints come from the theme's
    -- DiffAdd/DiffDelete (lua/themes/xray.lua), and the character-level
    -- pair is derived from them (1.4× brighter on a dark canvas).
  },
}
