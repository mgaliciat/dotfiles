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
-- Themes disponibles actualmente (todos sobre tokyonight):
--
--   anthropic-dark   dark Claude.ai (brown-black + Claude orange) ← espejo Ghostty
--   anthropic-light  light Anthropic (cream paper + sepia)         ← espejo Ghostty
--   oled-neon        true black OLED + Dracula neón                ← espejo Ghostty
--   obsidian         high-contrast dark, acento cyan
--   warm             dark sepia/naranja (legacy)
--   paper            light cream + tinta sepia (legacy)
--
-- Variantes solarized-osaka NO viven en este selector — usan su propio
-- plugin spec (lua/plugins/solarized-osaka.lua) porque vienen con paleta
-- completa cocinada. Ambos plugins se gatean mutuamente con `enabled`
-- según vim.g.theme.
--
-- Switching:
--   1. Editá `vim.g.theme = "<name>"` en lua/config/options.lua
--   2. Reiniciá nvim (o `:source $MYVIMRC | colorscheme tokyonight-<style>`).

local theme_name = vim.g.theme or "obsidian"

-- Bypass: si el theme activo es solarized-osaka, tokyonight no carga
-- (el spec de solarized-osaka toma el control del colorscheme).
if theme_name:match("^solarized%-osaka") then
  return { "folke/tokyonight.nvim", enabled = false }
end

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
