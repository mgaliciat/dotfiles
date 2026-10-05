-- ─── oil.nvim ─────────────────────────────────────────────────
-- File explorer as an editable buffer. `-` opens the current file's
-- directory; you edit the names as text (rename), delete
-- lines (delete), add lines (touch/mkdir), `:w` applies the
-- changes to the filesystem.
--
-- It's not a persistent side panel — it's a normal buffer, it fits
-- the vim model without adding IDE chrome. Replaces netrw.

return {
  "stevearc/oil.nvim",
  lazy = false,                                       -- netrw override → must load at startup
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    default_file_explorer = true,                     -- replaces netrw
    view_options = {
      show_hidden = true,                             -- dotfiles visible (consistent with telescope)
    },
    -- oil's defaults bind <C-h> (open in a split) and <C-l> (refresh) in its
    -- buffers, which shadows the window-navigation keys from keymaps.lua the
    -- moment the cursor is in oil. `false` drops the default; `:e` refreshes.
    keymaps = {
      ["q"]     = "actions.close",                    -- q closes the oil buffer
      ["<C-h>"] = false,
      ["<C-l>"] = false,
    },
  },
  keys = {
    { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
  },
}
