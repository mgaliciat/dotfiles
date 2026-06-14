-- ─── solarized-osaka.nvim ─────────────────────────────────────
-- Theme de craftzdog (fork de tokyonight con paleta solarized).
-- API idéntica a tokyonight, pero el plugin es independiente — por
-- eso NO encaja en el patrón `lua/themes/*.lua` (que sobreescribe
-- tokyonight). Vive como spec separado y se gatea con `enabled`
-- contra `vim.g.theme` para no pelear con tokyonight por el
-- colorscheme final.
--
-- Variantes registradas por el plugin:
--   solarized-osaka       (dark / night, default)
--   solarized-osaka-day   (light)
--   solarized-osaka-moon  (variante dark más suave)
--   solarized-osaka-storm (variante dark más gris)
--
-- Activación: setear `vim.g.theme = "solarized-osaka"` (o cualquiera
-- de las variantes de arriba) en lua/config/options.lua.

local theme_name = vim.g.theme or ""

-- Si el theme activo NO es una variante de solarized-osaka, no cargamos
-- el plugin — tokyonight (colorscheme.lua) toma el control.
if not theme_name:match("^solarized%-osaka") then
  return { "craftzdog/solarized-osaka.nvim", enabled = false }
end

return {
  "craftzdog/solarized-osaka.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    -- Hereda la transparencia de Ghostty (estilo craftzdog): Normal sin bg,
    -- el wallpaper/blur se ve a través del editor. Sidebars y floats, en
    -- cambio, quedan en "dark" (base04 opaco) — es el look real de craftzdog:
    -- paneles como "islas" sólidas sobre el fondo see-through, no todo
    -- transparente. keywords itálicas = default del plugin.
    transparent = true,
    terminal_colors = true,
    styles = {
      comments  = { italic = true },
      keywords  = { italic = true },
      functions = {},
      variables = {},
      sidebars  = "dark",
      floats    = "dark",
    },
    -- El colorscheme upstream deja WinBar/WinBarNC con bg sólido (base03).
    -- Como dropbar.nvim inyecta el breadcrumb en la winbar, hereda ese bg y
    -- se ve como bloque opaco sobre el Normal transparente. Forzar a NONE
    -- para que el breadcrumb respire (independiente del estilo de floats).
    on_highlights = function(hl, _)
      hl.WinBar   = { bg = "NONE" }
      hl.WinBarNC = { bg = "NONE" }
    end,
  },
  config = function(_, opts)
    require("solarized-osaka").setup(opts)
    vim.cmd.colorscheme(theme_name)
  end,
}
