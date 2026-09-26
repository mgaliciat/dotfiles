-- ─── colorscheme: selector ───────────────────────────────────
-- Multi-palette: the active theme is chosen with `vim.g.theme` set
-- in `lua/config/options.lua`. Each palette lives in `lua/themes/<name>.lua`
-- as a pure lua module and exports:
--
--   style          base tokyonight variant ("night" or "day")
--   palette        table with all the hex values
--   on_colors(c)   overrides tokyonight's internal palette
--   on_highlights(hl, c)   tweaks for specific groups
--   transparent    optional, defaults false — drop nvim's own canvas so
--                  Ghostty's translucency shows through (see below)
--
-- `transparent` is per-theme and not a global switch on purpose: it only makes
-- sense while Ghostty runs `background-opacity < 1`, and a light theme (paper,
-- light-2026, solarized-light) over that glass is unreadable. The theme that
-- wants it declares it; everything else keeps its opaque canvas.
--
-- The available ids: `theme --list` (scripts/theme) prints every id all
-- three layers can render; provenance of each palette is in
-- ghostty/themes/README.md. `obsidian` is the one module here with no Ghostty
-- or tmux mirror: it is the fallback below, not a stack theme.
--
-- The solarized-osaka variants do NOT live in this selector — they use their own
-- plugin spec (lua/plugins/solarized-osaka.lua) because they ship with a full
-- baked palette. Both plugins gate each other with `enabled`
-- according to vim.g.theme.
--
-- Switching:
--   1. `theme <name>` (scripts/theme), which edits `vim.g.theme` in
--      lua/config/options.lua along with the Ghostty and tmux lines
--   2. Restart nvim (or `:source $MYVIMRC | colorscheme tokyonight-<style>`).

local theme_name = vim.g.theme or "obsidian"

-- Bypass: if the active theme is solarized-osaka, tokyonight doesn't load
-- (the solarized-osaka spec takes over the colorscheme).
if theme_name:match("^solarized%-osaka") then
  return { "folke/tokyonight.nvim", enabled = false }
end

-- A missing module falls back to obsidian; a module that exists but errors
-- says so instead. One pcall(require) for both used to report a typo inside
-- a palette as "does not exist", which sends you looking for the wrong fault.
local theme
if #vim.api.nvim_get_runtime_file("lua/themes/" .. theme_name .. ".lua", false) == 0 then
  vim.notify(
    "Theme '" .. theme_name .. "' does not exist in lua/themes/. Falling back to obsidian.",
    vim.log.levels.WARN
  )
  theme = require("themes.obsidian")
else
  local ok, loaded = pcall(require, "themes." .. theme_name)
  if ok then
    theme = loaded
  else
    vim.notify(
      "Theme '" .. theme_name .. "' failed to load, falling back to obsidian:\n" .. loaded,
      vim.log.levels.ERROR
    )
    theme = require("themes.obsidian")
  end
end

local transparent = theme.transparent or false

return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = theme.style,
    transparent = transparent,
    terminal_colors = true,
    styles = {
      comments  = { italic = true },
      keywords  = { italic = false },
      functions = {},
      variables = {},
      -- `transparent` only drops the canvas of `Normal`; sidebars and floats
      -- are resolved apart from it. With "dark" the sidebar (neo-tree) keeps
      -- an opaque patch over the glass, so it follows the theme's flag.
      -- Floats stay "dark" on purpose: incline reads NormalFloat as its
      -- fallback canvas and needs a real bg there.
      sidebars  = transparent and "transparent" or "dark",
      floats    = "dark",
    },
    on_colors = function(c)
      if theme.on_colors then
        theme.on_colors(c)
      end
      -- The theme modules assign bg_sidebar a solid hex, and on_colors runs
      -- AFTER tokyonight resolved `styles.sidebars` — so the override would
      -- put the opaque patch back.
      if transparent then
        c.bg_sidebar = c.none
      end
    end,
    on_highlights = theme.on_highlights,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight-" .. theme.style)
  end,
}
