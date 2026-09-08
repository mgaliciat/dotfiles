-- ─── bufferline.nvim ──────────────────────────────────────────
-- The tab bar at the top of the screen (craftzdog's, from his
-- .config/nvim/lua/plugins/ui.lua).
--
-- `mode = "tabs"` is the whole point and the reason this doesn't
-- duplicate anything already here: the bar lists vim TABPAGES, not open
-- buffers. A buffer list grows on its own — every file an LSP jump or a
-- grep touches ends up in it — and this config already navigates that
-- with <S-h>/<S-l> and harpoon's numbered slots. A tabpage is opened by
-- hand, so the bar only ever shows what you decided to put there:
-- workspaces, not history.
--
-- Cycling is the NATIVE `gt` / `gT`, plus `:tabnew` / `:tabclose`.
-- craftzdog binds <Tab> / <S-Tab> to BufferLineCycleNext/Prev; that is
-- deliberately not copied. In a terminal <Tab> and <C-i> are the same
-- byte, and they're only distinguishable through the kitty keyboard
-- protocol — which tmux drops here (`extended-keys` is `off` in
-- tmux/tmux.conf), so nvim can't tell them apart and mapping <Tab>
-- silently kills <C-i>, the forward half of the jumplist. Turning
-- `extended-keys on` in tmux is what would make those binds safe.
--
-- The close icons are off because there's no mouse workflow here and
-- `:tabclose` is the way out; the neo-tree offset keeps the bar from
-- being drawn over the tree, which otherwise looks like the sidebar
-- starts one row lower than it does.
--
-- ─── why no `separator_style = "slant"` ───────────────────────
-- The angled edge was tried and reverted. A slant is not a glyph drawn
-- in the foreground: it is a powerline wedge whose fg is one tab's
-- BACKGROUND and whose bg is its neighbour's, so the diagonal is the
-- boundary between two filled blocks. This stack has no filled blocks —
-- solarized-osaka runs `transparent = true` over Ghostty's glass, so
-- every bufferline group resolves with `bg = nil` and the wedges come
-- out as unfilled shapes floating over the wallpaper.
--
-- Giving the tabs a solid background to slice would put an opaque strip
-- back over the glass, which is the same thing the tmux statusline was
-- fixed for in sep-2026 (`bg=default`, never a baked hex — see the repo
-- CLAUDE.md). So the geometry goes and the accent stays: a left bar on
-- the active tab, italic bold text, thin dividers. That is also what
-- craftzdog's own screenshots show — his `separator_style` line is
-- commented out in the config the rest of this file came from.
--
-- Colours are derived from the active theme, same technique and same
-- reason as incline.lua: `vim.g.theme` selects from a whole matrix, so
-- the palette is pulled out of groups every theme defines. `Special` is
-- the accent (osaka's orange #c94c16, which is the colour craftzdog's
-- tabs carry), `Comment` the inactive text, `WinSeparator` the dividers.
-- Every `bg` stays NONE on purpose — see above.

local function hl_hex(group, attr)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  return hl[attr] and string.format("#%06x", hl[attr]) or nil
end

return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = function()
    local accent = hl_hex("Special", "fg") or "#d97757"
    local muted  = hl_hex("Comment", "fg") or "#666666"
    local border = hl_hex("WinSeparator", "fg") or muted

    return {
      options = {
        mode = "tabs",
        -- `themable` (default true) makes bufferline register EVERY group
        -- with `default = true`, i.e. "only if the colorscheme has not
        -- defined it" — so a theme that styles one group wins over the
        -- `highlights` table below and you get a single mismatched slot with
        -- no error. solarized-osaka does exactly that: its
        -- `groups/bufferline.lua` sets `BufferLineIndicatorSelected` to
        -- yellow500 and nothing else, which is why the active tab's bar came
        -- out amber against an orange name. Off, because the palette here is
        -- already derived from the active theme — this table IS the theming.
        themable = false,
        separator_style = "thin",
        indicator = { style = "icon", icon = "▎" },
        show_buffer_close_icons = false,
        show_close_icon = false,
        diagnostics = "nvim_lsp",
        offsets = {
          {
            filetype = "neo-tree",
            text = "Explorer",
            highlight = "Directory",
            separator = true,
          },
        },
      },
      highlights = {
        fill                   = { bg = "NONE" },
        background             = { bg = "NONE", fg = muted },
        buffer_visible         = { bg = "NONE", fg = muted },
        buffer_selected        = { bg = "NONE", fg = accent, bold = true, italic = true },
        tab                    = { bg = "NONE", fg = muted },
        tab_selected           = { bg = "NONE", fg = accent, bold = true },
        tab_separator          = { bg = "NONE", fg = border },
        tab_separator_selected = { bg = "NONE", fg = border },
        separator              = { bg = "NONE", fg = border },
        separator_visible      = { bg = "NONE", fg = border },
        separator_selected     = { bg = "NONE", fg = border },
        offset_separator       = { bg = "NONE", fg = border },
        indicator_selected     = { bg = "NONE", fg = accent },
        indicator_visible      = { bg = "NONE", fg = "NONE" },
        duplicate              = { bg = "NONE", fg = muted, italic = true },
        duplicate_visible      = { bg = "NONE", fg = muted, italic = true },
        duplicate_selected     = { bg = "NONE", fg = accent, italic = true },
        modified               = { bg = "NONE", fg = muted },
        modified_visible       = { bg = "NONE", fg = muted },
        modified_selected      = { bg = "NONE", fg = accent },
      },
    }
  end,
}
