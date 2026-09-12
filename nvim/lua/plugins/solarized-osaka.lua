-- ─── solarized-osaka.nvim ─────────────────────────────────────
-- craftzdog's theme (tokyonight fork with a solarized palette).
-- Identical API to tokyonight, but the plugin is independent — that's
-- why it does NOT fit the `lua/themes/*.lua` pattern (which overrides
-- tokyonight). It lives as a separate spec and is gated with `enabled`
-- against `vim.g.theme` so it doesn't fight tokyonight over the
-- final colorscheme.
--
-- Variants registered by the plugin:
--   solarized-osaka       (dark / night, default)
--   solarized-osaka-day   (light)
--   solarized-osaka-moon  (softer dark variant)
--   solarized-osaka-storm (grayer dark variant)
--
-- Activation: set `vim.g.theme = "solarized-osaka"` (or any
-- of the variants above) in lua/config/options.lua.

local theme_name = vim.g.theme or ""

-- If the active theme is NOT a solarized-osaka variant, we don't load
-- the plugin — tokyonight (colorscheme.lua) takes over.
if not theme_name:match("^solarized%-osaka") then
  return { "craftzdog/solarized-osaka.nvim", enabled = false }
end

return {
  "craftzdog/solarized-osaka.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    -- On since 2026-09-11, with the glass back in Ghostty (opacity 0.9 + blur 20).
    -- The two move together: transparent here against a SOLID terminal hands
    -- Normal a nil bg with nothing behind it, and a solid nvim over a glass
    -- terminal shows a seam at every split edge.
    --
    -- This plus sidebars/floats still "dark" (opaque base04) below is craftzdog's
    -- actual look — panels as solid "islands" over a see-through background,
    -- not everything transparent.
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
  },
  config = function(_, opts)
    require("solarized-osaka").setup(opts)
    vim.cmd.colorscheme(theme_name)
  end,
}
