-- ─── telescope.nvim ───────────────────────────────────────────
-- Fuzzy finder. The fzf-native extension speeds up ranking ~10x for
-- large repos — building with `make` requires a C compiler (xcode-cli).
--
-- Project-wide text search is four keys, all on ripgrep:
--   <leader>fg  live grep, with rg flags allowed inline (live-grep-args):
--               `foo -g *.go`, `foo src/`, `-w foo`, `"two words"`.
--               A bare word is auto-quoted, so nothing changes until you
--               type a flag. <C-g> wraps what you typed and appends
--               ` --iglob ` for the common "now narrow by file" move.
--   <leader>fw  the word under the cursor / the visual selection, no typing.
--   <leader>fG  live grep rooted at the current file's directory — the
--               monorepo case, where the cwd is the whole world.
--   <leader>fR  reopen the last picker with its prompt and selection
--               (closing a grep by accident no longer costs the query).
-- Replacing across the project is grug-far's job (plugins/grug-far.lua).
--
-- `--hidden` goes in `vimgrep_arguments` so every rg-backed picker
-- (live_grep, live_grep_args, grep_string) sees dotfiles, matching
-- `find_files = { hidden = true }`; `.git/` stays out via
-- file_ignore_patterns. A per-picker `additional_args` would have to be
-- repeated on each of the three and the extension doesn't read the
-- builtin's entry anyway.

return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-live-grep-args.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function() return vim.fn.executable("make") == 1 end,
    },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>",   desc = "Find files" },
    { "<leader>fg", function() require("telescope").extensions.live_grep_args.live_grep_args() end,
                    desc = "Live grep (rg flags allowed)" },
    { "<leader>fw", function() require("telescope-live-grep-args.shortcuts").grep_word_under_cursor() end,
                    desc = "Grep word under cursor" },
    { "<leader>fw", function() require("telescope-live-grep-args.shortcuts").grep_visual_selection() end,
                    mode = "v", desc = "Grep selection" },
    { "<leader>fG", function()
        require("telescope").extensions.live_grep_args.live_grep_args({
          cwd = vim.fn.expand("%:p:h"),
          prompt_title = "Live grep in " .. vim.fn.fnamemodify(vim.fn.expand("%:p:h"), ":~:."),
        })
      end,
      desc = "Live grep in current file's dir" },
    { "<leader>fR", "<cmd>Telescope resume<CR>",       desc = "Resume last picker" },
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
  opts = function()
    local lga_actions = require("telescope-live-grep-args.actions")
    return {
      defaults = {
        prompt_prefix = "  ",
        selection_caret = " ",
        path_display = { "smart" },
        vimgrep_arguments = {
          "rg", "--color=never", "--no-heading", "--with-filename",
          "--line-number", "--column", "--smart-case", "--hidden",
        },
        file_ignore_patterns = {
          "node_modules", ".git/", "vendor/", "target/", "dist/", "build/",
        },
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<Esc>"] = "close",            -- Esc closes right away (the default requires a double Esc)
          },
        },
      },
      pickers = {
        find_files = { hidden = true },     -- includes dotfiles
      },
      extensions = {
        live_grep_args = {
          auto_quoting = true,
          mappings = {
            i = {
              -- The upstream default is <C-i>, which is Tab on a terminal and
              -- already toggles selection; <C-k> (the other default) is
              -- move_selection_previous here.
              ["<C-g>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
            },
          },
        },
      },
    }
  end,
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf")
    telescope.load_extension("live_grep_args")
  end,
}
