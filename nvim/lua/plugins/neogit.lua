-- ─── neogit ───────────────────────────────────────────────────
-- Magit for nvim: the OPERATE half of git inside the editor — status buffer
-- with stage/unstage per file, hunk or line, and popups for commit, push,
-- pull, fetch, branch, rebase, cherry-pick, stash, log. Chosen over a
-- lazygit float (tried and removed the same day) so that git is a buffer
-- like any other — nvim motions, search, yank — instead of a TUI with its
-- own key table. Lazygit lives on in the tmux popup (Alt+g) for the shell.
--
-- Diffs are NOT Neogit's job beyond inline hunks: `integrations.codediff`
-- routes `d` in the status buffer and the commit views to codediff.nvim
-- (plugins/codediff.lua), which is the REVIEW half.
--
-- Keys under <leader>g beside gitsigns (gs/gr/gp/gb/gd), codediff
-- (gv/gh/gH/gB) and the commit pickers (gf/gF).

return {
  "NeogitOrg/neogit",
  dependencies = {
    "esmuellert/codediff.nvim",
    "nvim-telescope/telescope.nvim",
  },
  cmd = "Neogit",
  keys = {
    { "<leader>gg", "<cmd>Neogit<cr>",        desc = "Neogit: status" },
    { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit: commit" },
    { "<leader>gl", "<cmd>Neogit log<cr>",    desc = "Neogit: log" },
  },
  opts = {
    -- Status as a full tab, not a split: it is a workspace you enter and
    -- leave (`q`), and a split would fight the file panel of diffview.
    kind = "tab",
    commit_editor = { kind = "tab", show_staged_diff = true },
    log_view      = { kind = "tab" },
    -- "unicode" draws the branch graph with box-drawing glyphs (every font in
    -- the stack is a Nerd Font). "kitty" renders it as an image over the
    -- kitty graphics protocol — Ghostty speaks it, but tmux in between does
    -- not pass it through reliably, so it would blank inside a popup.
    graph_style = "unicode",
    integrations = {
      codediff  = true,
      telescope = true,
    },
    -- Explicit rather than auto-detected: auto picks diffview if it is
    -- installed, and lazy keeps a plugin dir around after its spec is gone.
    diff_viewer = "codediff",
    -- Hints line off: the popups list their own keys, and the status buffer
    -- hint row costs a line on every open.
    disable_hint = true,
    -- Fold marks. Upstream draws sections/items with ASCII `>` / `v`; the
    -- Nerd Font chevrons read as the same fold state the file tree and
    -- folds use elsewhere in this config (neo-tree, foldcolumn). Hunks keep the
    -- empty default: their header line already says what they are.
    signs = {
      hunk    = { "", "" },
      item    = { "", "" },
      section = { "", "" },
    },
    -- Colours are NOT set here: the stack theme owns every Neogit* group
    -- (see the Neogit block in lua/themes/xray.lua), because Neogit's own
    -- derived palette drifts off-theme and it defers to whatever the
    -- colorscheme defined first.
    -- Sections that are noise on open stay folded; the ones you act on
    -- (unstaged/staged) stay open.
    sections = {
      untracked = { folded = true,  hidden = false },
      unstaged  = { folded = false, hidden = false },
      staged    = { folded = false, hidden = false },
      stashes   = { folded = true,  hidden = false },
      recent    = { folded = true,  hidden = false },
    },
  },
}
