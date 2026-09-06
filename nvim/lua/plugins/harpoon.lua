-- ─── harpoon (v2) ─────────────────────────────────────────────
-- A per-project list of the handful of files the current task lives
-- in, reachable by slot number. Buffers (S-h/S-l) walk everything you
-- have touched in order and `oldfiles` is history; neither is "the four
-- files I keep bouncing between". Marks persist on disk per cwd, so
-- reopening the project brings them back.
--
--   <leader>m     add the current file to the list (m = mark)
--   <leader>M     the list as an editable buffer: reorder lines to
--                 renumber, delete a line to unmark, q to close
--   <leader>1..4  jump to slot 1..4
-- No `]h/[h` cycling: gitsigns owns those for hunks, and a numbered
-- slot is the point — cycling is what the buffer list already does.
--
-- `harpoon2` is the rewritten branch (list-based API, `harpoon:list()`);
-- `master` is v1 with the `harpoon.mark` module and is unmaintained.
-- Don't copy snippets for that one — the module names don't exist here.

return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = function()
    local function harpoon() return require("harpoon") end
    local keys = {
      { "<leader>m", function() harpoon():list():add() end,                          desc = "Harpoon: mark file" },
      { "<leader>M", function() harpoon().ui:toggle_quick_menu(harpoon():list()) end, desc = "Harpoon: list" },
    }
    for i = 1, 4 do
      table.insert(keys, {
        "<leader>" .. i, function() harpoon():list():select(i) end, desc = "Harpoon: file " .. i,
      })
    end
    return keys
  end,
  opts = {
    settings = {
      save_on_toggle = true,   -- closing the list buffer (q) persists its edits
    },
  },
  config = function(_, opts)
    require("harpoon"):setup(opts)
  end,
}
