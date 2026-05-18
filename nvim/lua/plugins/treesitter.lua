-- ─── nvim-treesitter (main branch) ────────────────────────────
-- Branch `master` está archivado y es incompatible con nvim ≥0.12
-- (la API de query directives cambió). El plugin se reescribió en
-- `main` con otra interfaz: no hay `setup{}` con módulos como
-- `highlight`/`indent`/`textobjects` — son features built-in de nvim
-- que se activan vía `vim.treesitter.start()` en un autocmd FileType.
--
-- Requisitos del branch main:
--  - nvim 0.12+ (✓)
--  - tree-sitter-cli ≥0.26.1 desde brew (NO npm). Registrado en install.sh.
--  - main NO soporta lazy-loading → `lazy = false`.
--
-- :TSUpdate corre al instalar/actualizar. Parsers viven en
-- ~/.local/share/nvim/site/parser/ (install_dir default).

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter").install({
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
        "json", "yaml", "toml",
        "dockerfile",
        "gitcommit", "gitignore", "diff",
        "regex",
      })

      -- Highlight + indent: el branch main no los activa solo, hay que
      -- prenderlos por filetype. `vim.treesitter.start()` falla silente
      -- si el parser no está instalado, por eso el pcall.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local ft = args.match
          if pcall(vim.treesitter.start, args.buf) then
            -- Indent treesitter-based (experimental upstream). PHP queda
            -- afuera — el indent de TS para PHP es flaky igual que antes.
            if ft ~= "php" then
              vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end
        end,
      })
    end,
  },

  -- ─── textobjects (también branch main, API nueva) ────────────
  -- En main, los textobjects no se configuran como módulos de
  -- nvim-treesitter: el plugin separado expone funciones (`select`,
  -- `move`) que se mapean a teclas manualmente.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")

      -- Selecciones: vaf / vif / vac / vic / vaa / via
      local select_maps = {
        { "af", "@function.outer" },
        { "if", "@function.inner" },
        { "ac", "@class.outer" },
        { "ic", "@class.inner" },
        { "aa", "@parameter.outer" },
        { "ia", "@parameter.inner" },
      }
      for _, m in ipairs(select_maps) do
        vim.keymap.set({ "x", "o" }, m[1], function()
          select.select_textobject(m[2], "textobjects")
        end, { desc = "select " .. m[2] })
      end

      -- Movimiento: ]f / [f por funciones, ]c / [c por clases
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
