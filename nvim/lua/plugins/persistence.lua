-- ─── persistence.nvim ─────────────────────────────────────────
-- Sessions keyed by cwd (and git branch): buffers, splits, folds and
-- cursor positions are saved on exit and come back with `<leader>Sr`, or
-- `s` on the dashboard. Nothing is restored automatically — `nvim` alone
-- still lands on the dashboard, so an accidental `nvim` in the wrong dir
-- doesn't reopen twenty buffers.
--
-- `need = 1`: a session is only written when at least one real file
-- buffer is open, so `nvim` → dashboard → `:q` does not overwrite the
-- session you had with an empty one. `branch = true` keeps one session per
-- git branch — switching branches with a stack of PRs open in the other
-- one would otherwise clobber it.
--
-- neo-tree is closed right before the save (`PersistenceSavePre`): a
-- neo-tree window in a session file restores as a dead empty buffer, and
-- neo-tree's own VimEnter autocmd re-opens it anyway when nvim starts
-- with no file argument.

return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    need = 1,
    branch = true,
  },
  keys = {
    { "<leader>Sr", function() require("persistence").load() end,                desc = "Session: restore (cwd)" },
    { "<leader>Sl", function() require("persistence").load({ last = true }) end, desc = "Session: restore last" },
    { "<leader>Ss", function() require("persistence").select() end,              desc = "Session: select" },
    { "<leader>Sd", function() require("persistence").stop() end,                desc = "Session: don't save this one" },
  },
  init = function()
    -- What a session records. `localoptions` is left out on purpose: every
    -- per-buffer setting here comes from a FileType autocmd (the Go tabs /
    -- PHP 4-space ones in autocmds.lua, ftplugins, treesitter's indentexpr),
    -- and those fire again when the session reopens the file. Saving them
    -- would pin the values from the run that wrote the session over
    -- whatever the config says by the time it is restored.
    vim.opt.sessionoptions = {
      "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds",
    }
    vim.api.nvim_create_autocmd("User", {
      group   = vim.api.nvim_create_augroup("persistence_close_neotree", { clear = true }),
      pattern = "PersistenceSavePre",
      callback = function()
        pcall(vim.cmd, "Neotree close")
      end,
    })
  end,
}
