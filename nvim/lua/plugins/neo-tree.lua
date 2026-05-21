-- ─── neo-tree.nvim ────────────────────────────────────────────
-- Sidebar persistente a la izquierda. Convive con oil.nvim:
--   • neo-tree = panel lateral siempre visible, abrís archivo y
--     se abre en el split derecho. Workflow tipo IDE.
--   • oil      = buffer-based, ideal para renames masivos, bulk
--     edits de filenames como texto. Workflow tipo vim puro.
--
-- Keybind: <leader>n (toggle) — `n` por "neo-tree".
-- Auto-open en startup si no abriste un archivo específico
-- (ej. `nvim .` o `nvim` solo) — replica el comportamiento que
-- te gustaba con oil pero sin que desaparezca al editar un file.

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    { "<leader>n", "<cmd>Neotree toggle<CR>",                desc = "Toggle file tree" },
    { "<leader>N", "<cmd>Neotree reveal<CR>",                desc = "Reveal current file en tree" },
  },
  opts = {
    close_if_last_window = true,    -- si cerrás el último buffer normal, neo-tree no queda solo
    enable_git_status    = true,
    enable_diagnostics   = true,    -- LSP signs en el tree

    window = {
      position = "left",
      width    = 32,
      mappings = {
        ["<space>"] = "none",       -- liberá space para tu leader
        ["q"]       = "close_window",
        ["h"]       = "close_node",
        ["l"]       = "open",
      },
    },

    filesystem = {
      follow_current_file = { enabled = true },   -- highlight automático del file abierto
      use_libuv_file_watcher = true,              -- updates en cambios externos (git pull, etc.)
      filtered_items = {
        visible          = true,                  -- mostrar hidden por default (consistente con oil + telescope)
        hide_dotfiles    = false,
        hide_gitignored  = false,
      },
    },

    default_component_configs = {
      indent = { padding = 1, with_markers = true },
      icon   = { folder_empty = "󰜌", folder_empty_open = "󰜌" },
      git_status = {
        symbols = {
          added     = "+",
          modified  = "~",
          deleted   = "✖",
          renamed   = "➜",
          untracked = "?",
          ignored   = "○",
          unstaged  = "!",
          staged    = "✓",
          conflict  = "",
        },
      },
    },
  },

  config = function(_, opts)
    require("neo-tree").setup(opts)

    -- Auto-abrir en startup si no se pasó un archivo (ej. `nvim` o `nvim .`).
    -- Si pasás `nvim foo.lua`, el sidebar NO se abre automáticamente —
    -- arrancás en el archivo y abrís el tree con <leader>n si lo querés.
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        local argv0 = vim.fn.argv(0)
        if vim.fn.argc() == 0 or (argv0 ~= "" and vim.fn.isdirectory(argv0) == 1) then
          vim.cmd("Neotree show")
        end
      end,
    })
  end,
}
