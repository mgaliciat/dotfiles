-- ─── entry point ──────────────────────────────────────────────
-- Orden importa:
--   1. options ANTES que lazy → algunos plugins leen vim.opt al cargar.
--   2. lazy ANTES que keymaps específicos de plugin → keymaps.lua solo
--      define mappings nativos (sin dependencias de plugin).
--   3. autocmds al final → algunos dependen de filetypes que treesitter
--      registra al cargar.

require("config.options")
require("config.keymaps")
require("config.lazy")
require("config.autocmds")
