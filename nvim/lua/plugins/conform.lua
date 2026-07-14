-- ─── conform.nvim ─────────────────────────────────────────────
-- Formatter runner. Replaces null-ls/none-ls (deprecated).
-- Why separate the formatter from the LSP: many LSPs (intelephense,
-- bashls) don't format; others (gopls) do, but conform unifies the UX.
--
-- Format on save enabled for languages where the formatter is
-- canonical (gofmt, rustfmt). Disabled for the debatable ones
-- (markdown, sql, php) — use <leader>cf manually.

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
      python = { "ruff_organize_imports", "ruff_format" },  -- ruff does both
      sql    = { "sqlfluff" },

      -- Shell
      sh   = { "shfmt" },
      bash = { "shfmt" },
      zsh  = { "shfmt" },

      -- Web (prettierd > prettier — daemon, much faster).
      -- Requires prettier-plugin-astro installed in the project for .astro.
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
      -- Only languages with a canonical formatter (not negotiable in the community).
      -- Python is in because ruff is the de facto standard in 2026.
      local fts_on_save = { go = true, rust = true, lua = true, python = true }
      if fts_on_save[vim.bo[bufnr].filetype] then
        return { timeout_ms = 1500, lsp_fallback = true }
      end
    end,
  },
}
