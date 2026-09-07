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

return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      mode = "tabs",
      -- The angled edge craftzdog has (his line is commented out). It is
      -- drawn with the powerline glyphs  /  , so it needs the Nerd Font
      -- the stack already requires — in a terminal without one the tabs get
      -- two boxes instead of a diagonal. "slope" is the same idea at a
      -- steeper angle; "thin"/"thick" are plain bars, no geometry.
      separator_style = "slant",
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
  },
}
