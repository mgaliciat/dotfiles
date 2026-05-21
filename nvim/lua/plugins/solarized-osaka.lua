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
    transparent = false,
    terminal_colors = true,
    styles = {
      comments  = { italic = true },
      keywords  = { italic = false },
      functions = {},
      variables = {},
      sidebars  = "dark",
      floats    = "dark",
    },
  },
  config = function(_, opts)
    require("solarized-osaka").setup(opts)
    vim.cmd.colorscheme(theme_name)
  end,
}
