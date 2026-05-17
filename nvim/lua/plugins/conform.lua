-- ─── conform.nvim ─────────────────────────────────────────────
-- Formatter runner. Reemplaza null-ls/none-ls (deprecado).
-- Por qué separar formatter del LSP: muchos LSPs (intelephense,
-- bashls) no formatean; otros (gopls) sí pero conform unifica la UX.
--
-- Format on save activado para lenguajes donde el formatter es
-- canónico (gofmt, rustfmt). Desactivado para los discutibles
-- (markdown, sql, php) — usá <leader>cf manualmente.

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    { "<leader>cf",
      function() require("conform").format({ async = true, lsp_fallback = true }) end,
      mode = { "n", "v" },
      desc = "Format buffer/selection",
    },
  },
  opts = {
    formatters_by_ft = {
      -- Systems / backend
      lua    = { "stylua" },
      go     = { "goimports", "gofumpt" },
      rust   = { "rustfmt" },
      php    = { "php_cs_fixer" },
      python = { "ruff_organize_imports", "ruff_format" },  -- ruff hace ambos
      sql    = { "sqlfluff" },

      -- Shell
      sh   = { "shfmt" },
      bash = { "shfmt" },
      zsh  = { "shfmt" },

      -- Web (prettierd > prettier — daemon, mucho más rápido).
      -- Requiere prettier-plugin-astro instalado en el proyecto para .astro.
      javascript      = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescript      = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      astro           = { "prettierd", "prettier", stop_after_first = true },
      html            = { "prettierd", "prettier", stop_after_first = true },
      css             = { "prettierd", "prettier", stop_after_first = true },
      scss            = { "prettierd", "prettier", stop_after_first = true },
      json            = { "prettierd", "prettier", stop_after_first = true },
      jsonc           = { "prettierd", "prettier", stop_after_first = true },
      yaml            = { "prettierd", "prettier", stop_after_first = true },
      markdown        = { "prettierd", "prettier", stop_after_first = true },
    },
    format_on_save = function(bufnr)
      -- Solo lenguajes con formatter canónico (no negociable en la comunidad).
      -- Python entra porque ruff es el de facto standard en 2026.
      local fts_on_save = { go = true, rust = true, lua = true, python = true }
      if fts_on_save[vim.bo[bufnr].filetype] then
        return { timeout_ms = 1500, lsp_fallback = true }
      end
    end,
  },
}
