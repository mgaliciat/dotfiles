-- ─── snacks.nvim ──────────────────────────────────────────────
-- Suite de folke con varios módulos UI bajo una sola config. Acá
-- activamos SOLO lo visual minimalista y dejamos el resto off para
-- no pisar plugins existentes:
--
--   dashboard  → splash al abrir nvim sin args (recientes + atajos)
--   indent     → guías verticales + scope highlight del bloque actual
--   scroll     → smooth scroll sutil (~150ms)
--   zen        → focus mode (<leader>z toggle)
--
-- Off intencionalmente:
--   notifier      → ya tenemos nvim-notify via noice.nvim. Activarlo
--                   duplica el sink de mensajes y rompe el routing a
--                   notify_send que hace noice cuando perdés foco.
--   statuscolumn  → señales de LSP/git ya viven en signcolumn nativo
--                   (signcolumn="yes" en options.lua), no aporta.
--   bigfile/quickfile/words/etc → no se necesitan para "look & feel".
--
-- Patrón discovery dinámico: snacks es una "suite componible" igual
-- que el resto del repo (mini.bracketed, blink.cmp). Cada módulo
-- vale por sí mismo; el envoltorio es ergonomía.

return {
  "folke/snacks.nvim",
  priority = 1000,                       -- antes que el colorscheme: dashboard se monta limpio
  lazy = false,                          -- la suite se inicializa al arrancar
  ---@type snacks.Config
  opts = {
    -- ─── dashboard ────────────────────────────────────
    -- Sin ASCII art exagerado: header corto, sección de
    -- recientes + atajos rápidos. El preset "doom" es el
    -- más cercano a "minimalista funcional".
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
    -- Guías verticales con scope highlight. `only_scope`
    -- en false: muestra guías en todos los niveles y
    -- resalta el scope activo encima (lectura más rica
    -- sin saturar).
    indent = {
      indent = { char = "│", only_scope = false, only_current = false },
      scope  = { char = "│", underline = false, animate = { enabled = false } },
      -- Animación del scope desactivada — más limpio en código denso.
    },

    -- ─── scroll ───────────────────────────────────────
    -- Smooth scroll sutil. Easing default es bueno;
    -- 150ms es el sweet spot entre "estático" y "mareo".
    scroll = {
      animate = { duration = { step = 15, total = 150 }, easing = "linear" },
    },

    -- ─── zen ──────────────────────────────────────────
    -- Focus mode minimalista: centra el buffer, oculta
    -- statusline/numbers. Toggle con <leader>z (definido
    -- abajo en keys).
    zen = {
      toggles = { dim = true, git_signs = false, diagnostics = false },
      show    = { statusline = false, tabline = false },
    },

    -- Off explícito: documenta intención.
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
