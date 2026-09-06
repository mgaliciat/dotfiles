-- ─── nvim-lint ────────────────────────────────────────────────
-- Linter runner for tools that are NOT language servers. Same reason
-- conform exists for formatters: one runner, one UX, diagnostics land in
-- the normal `vim.diagnostic` pipeline next to the LSP's.
--
-- Go: golangci-lint. gopls already runs every staticcheck analyzer
-- (staticcheck = true in lsp.lua), so golangci-lint is here for what gopls
-- can't host — errcheck, gosec, revive, gocritic and whatever the PROJECT's
-- `.golangci.yml` enables. No linter list is pinned here on purpose: the
-- repo's config wins, and a repo without one gets golangci's defaults.
--
-- Lua: nothing. lua_ls's own diagnostics cover it; selene/luacheck would
-- re-report the same undefined-global class with a second config file.
--
-- Shell: nothing here either — bashls runs shellcheck itself once the
-- binary is on PATH (mason-tool-installer puts it there, lsp.lua), and a
-- second run through nvim-lint would double every warning. zsh files are
-- out regardless: shellcheck has no zsh dialect.
--
-- Markdown: markdownlint-cli2, the config-file flavour (`.markdownlint-cli2.*`
-- or `.markdownlint.*` in the repo win; no config = its defaults). marksman
-- is an LSP for links and headings, it does not lint prose structure.
--
-- Dockerfile: hadolint. No LSP exists for Dockerfiles; this is the only
-- feedback there is, and the dev workflow is Docker-first.
--
-- JS/TS: NOT here — eslint runs as a language server (lsp.lua), which also
-- gives the fix-all code action nvim-lint can't offer.
--
-- Trigger: after save and on leaving insert — never per keystroke, golangci
-- on a big package takes seconds.

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile", "BufWritePost" },
  opts = {
    linters_by_ft = {
      go = { "golangcilint" },
      markdown = { "markdownlint-cli2" },
      dockerfile = { "hadolint" },
    },
  },
  config = function(_, opts)
    local lint = require("lint")
    lint.linters_by_ft = opts.linters_by_ft

    local function try_lint()
      -- Only lint real files that have a linter, and never while a diff or
      -- a terminal/float buffer borrowed the filetype.
      if vim.bo.buftype ~= "" then return end
      if not lint.linters_by_ft[vim.bo.filetype] then return end
      lint.try_lint()
    end

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
      callback = function() vim.defer_fn(try_lint, 100) end,
    })
  end,
}
