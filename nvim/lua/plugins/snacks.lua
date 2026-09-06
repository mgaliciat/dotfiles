-- ─── snacks.nvim ──────────────────────────────────────────────
-- folke's suite with several UI modules under a single config. Here
-- we enable ONLY the minimalist visual stuff and leave the rest off so
-- we don't clobber existing plugins:
--
--   dashboard  → splash when opening nvim with no args (recents + shortcuts)
--   indent     → vertical guides + scope highlight of the current block
--   zen        → focus mode (<leader>z toggle)
--
-- Intentionally off:
--   scroll        → smooth scroll fought the trackpad (see its block below).
--   lazygit       → git inside nvim is Neogit + codediff (plugins/neogit.lua,
--                   plugins/codediff.lua) — a buffer UI, not a TUI in a float.
--                   Lazygit stays in the tmux popup (Alt+g) for the shell.
--   notifier      → we already have nvim-notify via noice.nvim. Enabling it
--                   duplicates the message sink and breaks the routing to
--                   notify_send that noice does when you lose focus.
--   statuscolumn  → LSP/git signs already live in the native signcolumn
--                   (signcolumn="yes" in options.lua), it adds nothing.
--   bigfile/quickfile/words/etc → not needed for "look & feel".
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
          { icon = " ", key = "g", desc = "Grep Text",     action = ":lua Snacks.dashboard.pick('live_grep')" },
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
        { section = "recent_files", icon = " ", title = "Recent",  indent = 2, padding = 1 },
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

    -- Explicitly off: documents intent.
    lazygit      = { enabled = false },
    notifier     = { enabled = false },
    statuscolumn = { enabled = false },
    bigfile      = { enabled = false },
    quickfile    = { enabled = false },
    words        = { enabled = false },
  },
  keys = {
    { "<leader>z",  function() Snacks.zen() end,           desc = "Zen mode" },
    { "<leader>Z",  function() Snacks.zen.zoom() end,      desc = "Zen zoom (window only)" },
  },
}
