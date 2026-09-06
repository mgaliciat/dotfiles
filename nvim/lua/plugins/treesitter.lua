-- ─── nvim-treesitter (main branch) ────────────────────────────
-- The `master` branch is archived and incompatible with nvim ≥0.12
-- (the query directives API changed). The plugin was rewritten on
-- `main` with a different interface: there's no `setup{}` with modules like
-- `highlight`/`indent`/`textobjects` — those are built-in nvim features
-- enabled via `vim.treesitter.start()` in a FileType autocmd.
--
-- Requirements of the main branch:
--  - nvim 0.12+ (✓)
--  - tree-sitter-cli ≥0.26.1 from brew (NOT npm). Registered in install.sh.
--  - main does NOT support lazy-loading → `lazy = false`.
--
-- :TSUpdate runs on install/update. Parsers live in
-- ~/.local/share/nvim/site/parser/ (default install_dir).

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter").install({
        -- Languages the user uses
        "go", "gomod", "gosum", "gowork", "gotmpl",
        "typescript", "tsx", "javascript", "html", "css", "scss",
        "astro",
        "rust",
        "php",
        "python",
        "sql",
        "bash",
        "markdown", "markdown_inline",
        -- General support
        "lua", "luadoc", "luap",              -- luadoc: ---@annotations highlighted; luap: lua patterns
        "vim", "vimdoc", "query",             -- required by nvim itself
        "json", "yaml", "toml",
        "dockerfile",
        "gitcommit", "gitignore", "diff",
        "regex",
      })

      -- Highlight + indent: the main branch doesn't enable them by itself, you have to
      -- turn them on per filetype. `vim.treesitter.start()` fails silently
      -- if the parser isn't installed, hence the pcall.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local ft = args.match
          if pcall(vim.treesitter.start, args.buf) then
            -- Treesitter-based indent (experimental upstream). PHP is left
            -- out — TS indent for PHP is as flaky as it used to be.
            if ft ~= "php" then
              vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end
        end,
      })
    end,
  },

  -- ─── textobjects (also branch main, new API) ─────────────────
  -- On main, textobjects aren't configured as nvim-treesitter
  -- modules: the separate plugin exposes functions (`select`,
  -- `move`) that you map to keys manually.
  --
  -- Only `move` is mapped here. The `select` half (`vaf`, `dic`, `cia`…)
  -- moved to mini.ai (plugins/mini-ai.lua), which reads the SAME
  -- `textobjects.scm` queries this plugin ships — so the plugin stays
  -- installed for its queries even where `move` isn't used.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({})

      local move = require("nvim-treesitter-textobjects.move")

      -- Movement: ]f / [f by functions, ]c / [c by classes
      vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "next function start" })
      vim.keymap.set({ "n", "x", "o" }, "]c", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "next class start" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "prev function start" })
      vim.keymap.set({ "n", "x", "o" }, "[c", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "prev class start" })
    end,
  },
}
