-- ─── nvim-treesitter ──────────────────────────────────────────
-- Parsing estructural → highlighting preciso, indent, text objects,
-- folding. Reemplaza el syntax regex viejo de Vim.
--
-- :TSUpdate corre al instalar/actualizar el plugin. Los parsers viven
-- en ~/.local/share/nvim/lazy/nvim-treesitter/parser/.

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",  -- selecciones tipo `vaf` (func), `vac` (class)
  },
  opts = {
    ensure_installed = {
      -- Lenguajes que el user usa
      "go", "gomod", "gosum",
      "typescript", "tsx", "javascript", "html", "css", "scss",
      "astro",
      "rust",
      "php",
      "python",
      "sql",
      "bash",
      "markdown", "markdown_inline",
      -- Soporte general
      "lua", "vim", "vimdoc", "query",      -- requeridos por nvim mismo
      "json", "jsonc", "yaml", "toml",
      "dockerfile",
      "gitcommit", "gitignore", "diff",
      "regex",
    },
    highlight = { enable = true },
    indent = { enable = true, disable = { "php" } },  -- el indent de TS para PHP es flaky
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
