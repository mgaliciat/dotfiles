-- ─── snacks.nvim ──────────────────────────────────────────────
-- folke's suite with several UI modules under a single config. Here
-- we enable ONLY the minimalist visual stuff and leave the rest off so
-- we don't clobber existing plugins:
--
--   dashboard  → splash when opening nvim with no args (projects + recents
--                + shortcuts). "Projects" are the git roots of recent files;
--                picking one `cd`s there and restores its persistence.nvim
--                session (snacks knows persistence's load command), falling
--                back to the file picker when there is no session yet.
--   indent     → vertical guides + scope highlight of the current block
--   zen        → focus mode (<leader>z toggle)
--   input      → `vim.ui.input` as a small floating window instead of the
--                cmdline — neo-tree's add/rename, grug-far's prompts,
--                `:LspRestart`'s client pick. (`vim.ui.select` is
--                telescope-ui-select's, in telescope.lua — a list wants a
--                picker, a one-liner wants an input box.)
--
-- Intentionally off:
--   scroll        → smooth scroll fought the trackpad (see its block below).
--   lazygit    → the git porcelain (status, stage, commit, push, log), as a
--                float. Replaced Neogit in sep-2026 — see its block below.
--   notifier      → we already have nvim-notify via noice.nvim. Enabling it
--                   duplicates the message sink and breaks the routing to
--                   notify_send that noice does when you lose focus.
--   statuscolumn  → LSP/git signs already live in the native signcolumn
--                   (signcolumn="yes" in options.lua), it adds nothing.
--   quickfile     → it renders the file before plugins load; with a ~40 ms
--                   startup there's nothing to hide.
--
-- On, but not for looks (sep-2026): bigfile (guard against huge files),
-- words (LSP reference highlight + `]]`/`[[`), bufdelete (`<leader>bd`
-- keeps the window layout) — see their blocks below.
--
-- Dynamic discovery pattern: snacks is a "composable suite" just like
-- the rest of the repo (mini.bracketed, blink.cmp). Each module
-- stands on its own; the wrapper is ergonomics.

return {
  "folke/snacks.nvim",
  priority = 1000,                       -- before the colorscheme: the dashboard mounts clean
  lazy = false,                          -- the suite initializes at startup
  ---@type snacks.Config
  opts = {
    -- ─── dashboard ────────────────────────────────────
    -- No over-the-top ASCII art: short header, recents
    -- section + quick shortcuts. The "doom" preset is the
    -- closest to "functional minimalist".
    dashboard = {
      preset = {
        header = table.concat({
          "",
          "  󰚄  nvim  ",
          "",
        }, "\n"),
        keys = {
          { icon = " ", key = "f", desc = "Find File",     action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File",      action = ":ene | startinsert" },
          -- Same picker as <leader>fg (rg flags allowed), not the plain
          -- live_grep `Snacks.dashboard.pick` would resolve to.
          { icon = " ", key = "g", desc = "Grep Text",     action = ":lua require('telescope').extensions.live_grep_args.live_grep_args()" },
          { icon = " ", key = "r", desc = "Recent Files",  action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
          { icon = " ", key = "c", desc = "Config",        action = ":e $MYVIMRC" },
          { icon = "󰒲 ", key = "L", desc = "Lazy",          action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit",          action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys",   gap = 1, padding = 1 },
        { section = "projects",     icon = " ", title = "Projects", indent = 2, padding = 1, limit = 5 },
        { section = "recent_files", icon = " ", title = "Recent",   indent = 2, padding = 1 },
        { section = "startup" },
      },
    },

    -- ─── indent ───────────────────────────────────────
    -- Vertical guides with scope highlight. `only_scope`
    -- set to false: shows guides at every level and
    -- highlights the active scope on top (richer reading
    -- without saturating).
    indent = {
      indent = { char = "│", only_scope = false, only_current = false },
      scope  = { char = "│", underline = false, animate = { enabled = false } },
      -- Scope animation disabled — cleaner in dense code.
    },

    -- ─── scroll ───────────────────────────────────────
    -- OFF (2026-09-04). It animates every scroll event, and a trackpad
    -- through Ghostty+tmux sends dozens per second: each one starts a new
    -- 150ms animation while nvim keeps relocating the cursor to honour
    -- scrolloff=8, so the cursor darts around the window during a swipe.
    -- j/k/{/} were never affected (one event, one animation). Keyboard-only
    -- smooth scroll isn't an option snacks offers — it hooks WinScrolled,
    -- which can't tell a wheel from a key — so the whole module goes.
    scroll = { enabled = false },

    -- ─── zen ──────────────────────────────────────────
    -- Minimalist focus mode: centers the buffer, hides
    -- statusline/numbers. Toggle with <leader>z (defined
    -- below in keys).
    zen = {
      toggles = { dim = true, git_signs = false, diagnostics = false },
      show    = { statusline = false, tabline = false },
    },

    input = { enabled = true },

    -- ─── bigfile ──────────────────────────────────────
    -- Above 1.5 MB (or an average line over 1000 chars — a minified
    -- bundle) the buffer gets `ft=bigfile`: no treesitter, no LSP, no
    -- folds, syntax off. Without it a dumped JSON or a log freezes nvim
    -- for seconds on open and on every keystroke.
    bigfile = { enabled = true },

    -- ─── words ────────────────────────────────────────
    -- LSP document highlight: every reference of the symbol under the
    -- cursor lights up, and `]]` / `[[` jump between them (keys below).
    -- `*` finds text; this finds the same *binding*, so a local `x`
    -- doesn't match the `x` in another function.
    words = { enabled = true, debounce = 200 },

    -- ─── lazygit ──────────────────────────────────────
    -- The git porcelain: the lazygit TUI in a float, same binary and same
    -- versioned config as the tmux popup (`Alt+g`, lazygit/config.yml —
    -- its palette mirrors the stack theme by hand). It replaced Neogit
    -- (sep-2026): the user wanted the prettier UI and no second porcelain
    -- beside it. Review (diffs, history) stays in codediff — lazygit's
    -- diff pane is for reading a hunk before staging it, not for review.
    -- `configure = false`: with it on, snacks appends its own theme derived
    -- from nvim's highlights and overrides the palette the repo maintains.
    lazygit = { enabled = true, configure = false },

    -- Explicitly off: documents intent.
    notifier     = { enabled = false },
    statuscolumn = { enabled = false },
    quickfile    = { enabled = false },
  },
  keys = {
    -- `]]` / `[[` are vim's section motions (`{` in column 0 — C-era).
    -- When words has references for the buffer they jump between them;
    -- otherwise the native motion runs, so nothing is lost.
    { "]]", function() Snacks.words.jump(vim.v.count1) end,  mode = { "n", "t" }, desc = "Next reference" },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, mode = { "n", "t" }, desc = "Prev reference" },
    -- Buffer close that keeps the window layout: the window gets the
    -- alternate (or next) buffer instead of being destroyed like `:bdelete`
    -- does when the buffer is visible. Asks before dropping unsaved changes.
    { "<leader>bd", function() Snacks.bufdelete() end,       desc = "Delete buffer (keep window)" },
    { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Delete other buffers" },
    -- Neogit's old keys, same meaning: gg status, gl log. gc (commit) went
    -- with Neogit — in lazygit `c` from the status float is the commit.
    { "<leader>gg", function() Snacks.lazygit() end,          desc = "Lazygit" },
    { "<leader>gl", function() Snacks.lazygit.log() end,      desc = "Lazygit: repo log" },
    { "<leader>gL", function() Snacks.lazygit.log_file() end, desc = "Lazygit: log of this file" },
    { "<leader>z",  function() Snacks.zen() end,           desc = "Zen mode" },
    { "<leader>Z",  function() Snacks.zen.zoom() end,      desc = "Zen zoom (window only)" },
  },
}
