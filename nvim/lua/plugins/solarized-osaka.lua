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
    -- Hereda la transparencia de Ghostty (estilo craftzdog). Sidebars y
    -- floats también van transparentes — sino se ven como "islas" opacas
    -- sobre el fondo see-through del terminal.
    transparent = true,
    terminal_colors = true,
    styles = {
      comments  = { italic = true },
      keywords  = { italic = false },
      functions = {},
      variables = {},
      sidebars  = "transparent",
      floats    = "transparent",
    },
    -- El colorscheme upstream deja WinBar/WinBarNC con bg sólido (asume
    -- terminal opaco). Como dropbar.nvim inyecta el breadcrumb en la
    -- winbar, hereda ese bg y se ve como bloque opaco encima del fondo
    -- transparente de Ghostty. Forzar a NONE para que el bar respire.
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
