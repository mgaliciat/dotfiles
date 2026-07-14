-- ─── colorscheme: selector ───────────────────────────────────
-- Multi-palette: the active theme is chosen with `vim.g.theme` set
-- in `lua/config/options.lua`. Each palette lives in `lua/themes/<name>.lua`
-- as a pure lua module and exports:
--
--   style          base tokyonight variant ("night" or "day")
--   palette        table with all the hex values
--   on_colors(c)   overrides tokyonight's internal palette
--   on_highlights(hl, c)   tweaks for specific groups
--
-- Themes currently available (all on top of tokyonight; except
-- obsidian, each one has a Ghostty + tmux mirror — the stack family):
--
--   dark-2026        clone of VS Code's default "Dark 2026" (near-black + teal)
--   light-2026       clone of "2026 Light" (pure white + blue #0069CC)
--   carbon           minimal true-black, high contrast, Claude orange accent
--   xcode-oled       true black OLED + Xcode Default (Dark) syntax
--   anthropic-dark   dark Claude.ai (brown-black + Claude orange)
--   anthropic-warm   warm charcoal + Claude palette (terracotta, olive, amber)
--   prism-night      deep night-blue + spectrum accents
--   paper            light cream + sepia ink
--   solarized-light  canonical Solarized Light
--   obsidian         high-contrast dark, cyan accent (nvim only + fallback)
--
-- The solarized-osaka variants do NOT live in this selector — they use their own
-- plugin spec (lua/plugins/solarized-osaka.lua) because they ship with a full
-- baked palette. Both plugins gate each other with `enabled`
-- according to vim.g.theme.
--
-- Switching:
--   1. Edit `vim.g.theme = "<name>"` in lua/config/options.lua
--   2. Restart nvim (or `:source $MYVIMRC | colorscheme tokyonight-<style>`).

local theme_name = vim.g.theme or "obsidian"

-- Bypass: if the active theme is solarized-osaka, tokyonight doesn't load
-- (the solarized-osaka spec takes over the colorscheme).
if theme_name:match("^solarized%-osaka") then
  return { "folke/tokyonight.nvim", enabled = false }
end

local ok, theme  = pcall(require, "themes." .. theme_name)
if not ok then
  vim.notify(
    "Theme '" .. theme_name .. "' does not exist in lua/themes/. Falling back to obsidian.",
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
