-- ─── lualine.nvim ─────────────────────────────────────────────
-- Statusline. Theme = "auto" → lualine detects the active
-- colorscheme and applies the lualine theme that plugin exports
-- (solarized-osaka, tokyonight, etc. all ship their own).
-- craftzdog pattern: never hardcode a palette here, let the
-- colorscheme rule. You change `vim.g.theme` → the statusline
-- syncs by itself.

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      -- No separator overrides → lualine uses its defaults
      -- (powerline chevrons ``), the craftzdog/LazyVim look.
      globalstatus = true,
      disabled_filetypes = { statusline = { "dashboard", "alpha", "snacks_dashboard" } },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", { "diff", symbols = { added = " ", modified = " ", removed = " " } } },
      lualine_c = {
        { "filename", path = 1 },
        { "diagnostics", sources = { "nvim_lsp" } },
      },
      lualine_x = { "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
