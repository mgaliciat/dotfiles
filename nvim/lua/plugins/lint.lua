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
-- Trigger: after save and on leaving insert — never per keystroke, golangci
-- on a big package takes seconds.

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile", "BufWritePost" },
  opts = {
    linters_by_ft = {
      go = { "golangcilint" },
    },
  },
  config = function(_, opts)
    local lint = require("lint")
    lint.linters_by_ft = opts.linters_by_ft

    local function try_lint()
      -- Only lint real files that have a linter, and never while a diff or
      -- a neogit buffer borrowed the filetype.
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
