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
    -- Inherits Ghostty's transparency (craftzdog style): Normal with no bg,
    -- the wallpaper/blur shows through the editor. Sidebars and floats, on the
    -- other hand, stay "dark" (opaque base04) — that's craftzdog's real look:
    -- panels as solid "islands" over the see-through background, not everything
    -- transparent. Italic keywords = the plugin's default.
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
    -- The upstream colorscheme leaves WinBar/WinBarNC with a solid bg (base03).
    -- Since dropbar.nvim injects the breadcrumb into the winbar, it inherits that bg and
    -- looks like an opaque block over the transparent Normal. Force it to NONE
    -- so the breadcrumb breathes (independent of the floats style).
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
