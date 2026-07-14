-- ─── nvim-highlight-colors ────────────────────────────────────
-- Paints the background of color literals in any file:
--   #d97757            ← hex
--   rgb(217, 119, 87)  ← rgb / hsl
--   bg-orange-500      ← Tailwind classes
--   --color-primary    ← CSS vars
--
-- Render "background" = the color cell tints the whole word.
-- Other options: "foreground" (text only) or "first_column".

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
