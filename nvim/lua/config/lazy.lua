-- ─── lazy.nvim bootstrap ──────────────────────────────────────
-- Auto-clones lazy if it doesn't exist. Idempotent: on later runs it only
-- adds lazypath to the rtp.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- import = "plugins" loads ALL the .lua files in lua/plugins/ automatically.
-- No need to list them one by one — adding/removing a plugin = adding/removing a file.
require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "tokyonight-night", "habamax" } },
  checker = { enabled = true, notify = false },  -- checks for updates in the background, without notifying
  change_detection = { notify = false },
  performance = {
    rtp = {
      -- Built-in plugins we don't use. Disabling them shaves ~5ms off startup.
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
