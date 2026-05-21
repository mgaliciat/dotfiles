-- ─── nvim-highlight-colors ────────────────────────────────────
-- Pinta el fondo de literales de color en cualquier archivo:
--   #d97757            ← hex
--   rgb(217, 119, 87)  ← rgb / hsl
--   bg-orange-500      ← clases de Tailwind
--   --color-primary    ← CSS vars
--
-- Render "background" = la celda del color tiñe la palabra entera.
-- Otras opciones: "foreground" (solo el texto) o "first_column".

return {
  "brenoprata10/nvim-highlight-colors",
  event = "BufReadPre",
  opts = {
    render                     = "background",
    enable_hex                 = true,
    enable_short_hex           = true,
    enable_rgb                 = true,
    enable_hsl                 = true,
    enable_hsl_without_function = true,
    enable_ansi                = true,
    enable_var_usage           = true,
    enable_tailwind            = true,
  },
}
