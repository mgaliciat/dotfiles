-- ─── lualine.nvim ─────────────────────────────────────────────
-- Statusline. Theme = "auto" → lualine detecta el colorscheme
-- activo y aplica el lualine theme que ese plugin exporta
-- (solarized-osaka, tokyonight, etc. todos traen el suyo).
-- Patrón de craftzdog: nunca hardcodear paleta acá, dejar que el
-- colorscheme mande. Cambiás `vim.g.theme` → statusline se
-- sincroniza solo.

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      -- Sin separators overrides → lualine usa sus defaults
      -- (powerline chevrons ``), el look de craftzdog/LazyVim.
      globalstatus = true,
      disabled_filetypes = { statusline = { "dashboard", "alpha" } },
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
