-- ─── telescope.nvim ───────────────────────────────────────────
-- Fuzzy finder. fzf-native extension acelera el ranking ~10x para
-- repos grandes — build con `make` requiere compiler C (xcode-cli).

return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function() return vim.fn.executable("make") == 1 end,
    },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>",   desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>",    desc = "Live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>",      desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>",    desc = "Help tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>",     desc = "Recent files" },
    { "<leader>fc", "<cmd>Telescope commands<CR>",     desc = "Commands" },
    { "<leader>fk", "<cmd>Telescope keymaps<CR>",      desc = "Keymaps" },
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>",  desc = "Diagnostics" },
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>",         desc = "Document symbols" },
    { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>",        desc = "Workspace symbols" },
    { "<leader>/",  "<cmd>Telescope current_buffer_fuzzy_find<CR>",    desc = "Search in buffer" },
  },
  opts = {
    defaults = {
      prompt_prefix = "  ",
      selection_caret = " ",
      path_display = { "smart" },
      file_ignore_patterns = {
        "node_modules", ".git/", "vendor/", "target/", "dist/", "build/",
      },
      mappings = {
        i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
          ["<Esc>"] = "close",            -- Esc cierra directo (default requiere doble Esc)
        },
      },
    },
    pickers = {
      find_files = { hidden = true },     -- incluye dotfiles
      live_grep = { additional_args = function() return { "--hidden" } end },
    },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf")
  end,
}
