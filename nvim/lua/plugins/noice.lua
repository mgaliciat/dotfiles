-- ─── noice.nvim ───────────────────────────────────────────────
-- Reemplaza la UI nativa de cmdline, mensajes y popups por una
-- versión moderna (cmdline flotante, splits para `:messages`,
-- LSP progress integrado, etc.). PLUGIN INVASIVO — si algo de la
-- experiencia default de nvim te molesta, sacá este plugin y se
-- restaura todo.
--
-- Joya extra (idea de craftzdog): cuando nvim PIERDE FOCO (te vas
-- a Slack/browser), las notificaciones se enrutan a notify nativo
-- de macOS — así te enterás de que terminó tu `:!make build` sin
-- tener que volver a la ventana de nvim.
--
-- Dependencias: nui.nvim (UI primitives) + nvim-notify (toasts).

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "rcarriga/nvim-notify",
      opts = {
        timeout = 5000,
        render  = "wrapped-compact",
      },
    },
  },
  opts = {
    -- presets: aplica configs comunes en bloque
    presets = {
      bottom_search          = true,    -- search en la línea inferior, no float
      command_palette        = true,    -- cmdline + popup juntos arriba-centro
      long_message_to_split  = true,    -- mensajes largos abren split
      lsp_doc_border         = true,    -- border en hover/signature
      inc_rename             = true,    -- preview de inc-rename.nvim integrado
    },
    -- LSP UI replacements
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"]               = true,
        ["cmp.entry.get_documentation"]                 = true,
      },
    },
  },
  config = function(_, opts)
    -- Focus-routing: si nvim NO está focuseado, manda notifs a
    -- macOS native (vía nvim-notify → osascript fallback).
    local focused = true
    vim.api.nvim_create_autocmd("FocusGained", { callback = function() focused = true end })
    vim.api.nvim_create_autocmd("FocusLost",   { callback = function() focused = false end })

    opts.routes = opts.routes or {}
    table.insert(opts.routes, 1, {
      filter = { cond = function() return not focused end },
      view   = "notify_send",
      opts   = { stop = false },
    })

    -- Filtro: silencia el "No information available" del LSP hover
    -- cuando no hay docs — ruido puro en lenguajes sin documentación.
    table.insert(opts.routes, {
      filter = { event = "notify", find = "No information available" },
      opts   = { skip = true },
    })

    require("noice").setup(opts)
  end,
}
