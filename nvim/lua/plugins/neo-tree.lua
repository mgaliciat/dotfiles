-- ─── neo-tree.nvim ────────────────────────────────────────────
-- Persistent sidebar on the left. Coexists with oil.nvim:
--   • neo-tree = side panel always visible, you open a file and
--     it opens in the right split. IDE-style workflow.
--   • oil      = buffer-based, ideal for massive renames, bulk
--     edits of filenames as text. Pure vim-style workflow.
--
-- Keybind: <leader>n (toggle) — `n` for "neo-tree".
-- Auto-opens at startup if you didn't open a specific file
-- (e.g. `nvim .` or plain `nvim`) — replicates the behavior you
-- liked with oil but without it disappearing when you edit a file.

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
    { "<leader>N", "<cmd>Neotree reveal<CR>",                desc = "Reveal current file in tree" },
  },
  opts = {
    close_if_last_window = true,    -- if you close the last normal buffer, neo-tree isn't left alone
    enable_git_status    = true,
    enable_diagnostics   = true,    -- LSP signs in the tree

    window = {
      position = "left",
      width    = 32,
      mappings = {
        ["<space>"] = "none",       -- free up space for your leader
        ["q"]       = "close_window",
        ["h"]       = "close_node",
        ["l"]       = "open",
      },
    },

    filesystem = {
      follow_current_file = { enabled = true },   -- automatic highlight of the open file
      use_libuv_file_watcher = true,              -- updates on external changes (git pull, etc.)
      filtered_items = {
        visible          = true,                  -- show hidden by default (consistent with oil + telescope)
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

    -- Auto-open at startup if no file was passed (e.g. `nvim` or `nvim .`).
    -- If you pass `nvim foo.lua`, the sidebar does NOT open automatically —
    -- you start in the file and open the tree with <leader>n if you want it.
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
