-- ─── entry point ──────────────────────────────────────────────
-- Order matters:
--   1. options BEFORE lazy → some plugins read vim.opt when loading.
--   2. lazy BEFORE plugin-specific keymaps → keymaps.lua only defines
--      native mappings (no plugin dependencies).
--   3. autocmds last → some depend on filetypes that treesitter
--      registers when loading.

require("config.options")
require("config.keymaps")
require("config.lazy")
require("config.autocmds")
