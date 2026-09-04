-- ─── git history pickers ──────────────────────────────────────
-- Telescope over `git log`, landing in codediff. Not a plugin: two builtin
-- pickers (git_commits, git_bcommits) with their default action replaced.
-- Telescope's stock <CR> CHECKS OUT the commit — the one thing you never
-- want from a "show me this commit" picker — so it is remapped to open the
-- commit against its parent in codediff, whole commit, all files.
--
-- advanced-git-search.nvim was here for a day and went: its <CR> is
-- hard-wired to "current buffer vs commit" and it only knows how to land in
-- fugitive or diffview, neither of which is in the stack any more.
--
-- Keys under <leader>g beside gitsigns, Neogit and codediff:
--   <leader>gf   commits of the repo      <CR> commit in codediff
--   <leader>gF   commits of this file     <C-y> yank the hash
-- The preview pane is telescope's own `git show` of the entry.

local function open_in_codediff(prompt_bufnr)
  local actions = require("telescope.actions")
  local entry = require("telescope.actions.state").get_selected_entry()
  actions.close(prompt_bufnr)
  if not entry or not entry.value then return end
  vim.cmd(("CodeDiff %s~1 %s"):format(entry.value, entry.value))
end

local function yank_hash(prompt_bufnr)
  local entry = require("telescope.actions.state").get_selected_entry()
  if not entry or not entry.value then return end
  vim.fn.setreg("+", entry.value)
  vim.notify("yanked " .. entry.value)
end

local function attach(_, map)
  local actions = require("telescope.actions")
  actions.select_default:replace(open_in_codediff)
  map({ "i", "n" }, "<C-y>", yank_hash)
  return true
end

return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "esmuellert/codediff.nvim" },
  keys = {
    {
      "<leader>gf",
      function() require("telescope.builtin").git_commits({ attach_mappings = attach }) end,
      desc = "Git: repo commits",
    },
    {
      "<leader>gF",
      function() require("telescope.builtin").git_bcommits({ attach_mappings = attach }) end,
      desc = "Git: file commits",
    },
  },
}
