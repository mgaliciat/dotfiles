-- ─── colorscheme: selector ───────────────────────────────────
-- Multi-paleta: el theme activo se elige con `vim.g.theme` setteado
-- en `lua/config/options.lua`. Cada paleta vive en `lua/themes/<name>.lua`
-- como módulo lua puro y exporta:
--
--   style          tokyonight variant base ("night" o "day")
--   palette        tabla con todos los hex
--   on_colors(c)   sobreescribe la paleta interna de tokyonight
--   on_highlights(hl, c)   tweaks de grupos específicos
--
-- Themes disponibles actualmente:
--
--   obsidian   high-contrast dark, acento cyan      pareja: obsidian-dots.glsl
--   warm       dark sepia/naranja                   pareja: anthropic-dots.glsl
--                                                          anthropic-crt.glsl
--   paper      light cream + tinta sepia            pareja: anthropic-paper.glsl
--
-- Switching:
--   1. Editá `vim.g.theme = "<name>"` en lua/config/options.lua
--   2. Reiniciá nvim (o `:source $MYVIMRC | colorscheme tokyonight-<style>`).
--
-- Los efectos glitch.glsl y lcd-dithered.glsl son agnósticos —
-- pegan con cualquiera de los tres themes.

local theme_name = vim.g.theme or "obsidian"
local ok, theme  = pcall(require, "themes." .. theme_name)
if not ok then
  vim.notify(
    "Theme '" .. theme_name .. "' no existe en lua/themes/. Fallback a obsidian.",
    vim.log.levels.WARN
  )
  theme = require("themes.obsidian")
end

return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = theme.style,
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
    on_colors     = theme.on_colors,
    on_highlights = theme.on_highlights,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight-" .. theme.style)
  end,
}
