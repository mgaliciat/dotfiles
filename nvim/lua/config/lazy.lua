-- ─── lazy.nvim bootstrap ──────────────────────────────────────
-- Auto-clona lazy si no existe. Idempotente: en runs siguientes solo
-- agrega lazypath al rtp.

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

-- import = "plugins" carga TODOS los .lua en lua/plugins/ automáticamente.
-- No hace falta listarlos uno por uno — agregar/quitar plugin = agregar/quitar archivo.
require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "tokyonight-night", "habamax" } },
  checker = { enabled = true, notify = false },  -- chequea updates en background, sin notificar
  change_detection = { notify = false },
  performance = {
    rtp = {
      -- Plugins built-in que no usamos. Desactivarlos baja ~5ms en startup.
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
