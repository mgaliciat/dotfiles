-- ─── incline.nvim ─────────────────────────────────────────────
-- Filename flotante en la esquina superior derecha de cada split.
-- Resuelve el problema clásico: el statusline (lualine) solo muestra
-- el path del split activo — en layouts con 3+ ventanas no sabés
-- qué archivo es cuál sin enfocarlo primero.
--
-- Colores: derivados del tema ACTIVO del stack (vim.g.theme) para que el
-- indicator siga la paleta cross-stack — la familia versionada vive en
-- lua/themes/<id>.lua, de donde sacamos accent/bg. solarized-osaka es el
-- plugin (no tiene themes/<id>.lua), así que para él caemos a su paleta
-- nativa. Activo (focus): box con bg=accent y texto oscuro. NC (inactivo):
-- fg tenue sobre bg flotante.

return {
  "b0o/incline.nvim",
  dependencies = {
    "craftzdog/solarized-osaka.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  event = "BufReadPre",
  priority = 1200,
  config = function()
    -- Por defecto: paleta solarized-osaka (cubre osaka y cualquier id sin
    -- módulo themes/<id>.lua). Si el tema activo SÍ tiene módulo, lo usamos.
    local accent, bg_active, fg_nc, bg_nc
    local pal_ok, mod = pcall(require, "themes." .. (vim.g.theme or "carbon"))
    if pal_ok and type(mod) == "table" and mod.palette then
      local p = mod.palette
      -- `accent` no existe en todos los themes (anthropic-warm/paper/obsidian
      -- solo definen `cursor`); cursor ES el color de foco, así que sirve de
      -- fallback. Sin esto, esos temas dejaban guibg=nil → indicator sin bg.
      accent    = p.accent or p.cursor
      bg_active = p.bg_float or p.bg
      fg_nc     = p.fg_dark or p.comment
      bg_nc     = p.bg_float or p.bg_dark or p.bg
    else
      local ok, sol = pcall(require, "solarized-osaka.colors")
      local c = ok and sol.setup() or {
        magenta500 = "#d33682", base03 = "#002b36",
        base04     = "#001e26", violet500 = "#6c71c4",
      }
      accent, bg_active, fg_nc, bg_nc = c.magenta500, c.base04, c.violet500, c.base03
    end

    require("incline").setup({
      highlight = {
        groups = {
          InclineNormal   = { guibg = accent, guifg = bg_active },
          InclineNormalNC = { guifg = fg_nc,  guibg = bg_nc },
        },
      },
      window = { margin = { vertical = 0, horizontal = 1 } },
      -- Oculta el indicator cuando el cursor está en su misma fila para
      -- que no tape texto.
      hide = { cursorline = true },
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if filename == "" then filename = "[No Name]" end
        if vim.bo[props.buf].modified then
          filename = "[+] " .. filename
        end
        local icon, color = require("nvim-web-devicons").get_icon_color(filename)
        return { { icon, guifg = color }, { " " }, { filename } }
      end,
    })
  end,
}
