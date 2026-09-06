-- ─── which-key.nvim ───────────────────────────────────────────
-- Popup that shows the available mappings after a prefix (e.g.
-- when you press <leader>, it waits `timeoutlen` and shows the menu).
-- It reads the `desc` each keymap defines → no need to register
-- names here.

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 400,   -- aligned with vim.opt.timeoutlen
    spec = {
      -- Groups: visible names for the prefixes. The individual
      -- mappings (with their desc) are discovered on their own.
      { "<leader>b",  group = "buffer" },
      { "<leader>c",  group = "code (LSP / format)" },
      { "<leader>f",  group = "find (telescope)" },
      { "<leader>g",  group = "git" },
      { "<leader>r",  group = "rename" },
      { "<leader>s",  group = "search & replace (grug-far)" },
      { "<leader>S",  group = "session (persistence)" },
      { "<leader>t",  group = "test (neotest)" },
    },
  },
  keys = {
    { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
  },
}
