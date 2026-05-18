-- ─── oil.nvim ─────────────────────────────────────────────────
-- File explorer como buffer editable. `-` abre el directorio del
-- archivo actual; editás los nombres como texto (rename), borrás
-- líneas (delete), agregás líneas (touch/mkdir), `:w` aplica los
-- cambios al filesystem.
--
-- No es un side panel persistente — es un buffer normal, encaja
-- con el modelo vim sin agregar chrome de IDE. Reemplaza netrw.

return {
  "stevearc/oil.nvim",
  lazy = false,                                       -- override de netrw → debe cargar al inicio
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    default_file_explorer = true,                     -- reemplaza netrw
    view_options = {
      show_hidden = true,                             -- dotfiles visibles (consistente con telescope)
    },
    keymaps = {
      ["q"] = "actions.close",                        -- q cierra el buffer oil
    },
  },
  keys = {
    { "-",         "<cmd>Oil<CR>", desc = "Open parent directory" },
    { "<leader>e", "<cmd>Oil<CR>", desc = "File explorer" },
  },
}
