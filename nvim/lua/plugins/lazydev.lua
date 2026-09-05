-- ─── lazydev.nvim ─────────────────────────────────────────────
-- lua_ls for THIS config, done right. It watches which modules a lua buffer
-- `require`s and adds only those plugins' sources to lua_ls's workspace
-- library, on the fly — so `require("snacks")` gets Snacks' types the moment
-- you type it, and a file that requires nothing pays for nothing.
--
-- Replaces `workspace.library = vim.api.nvim_get_runtime_file("", true)` in
-- lua_ls's settings: that shipped EVERY runtime dir to the server on every
-- start (seconds of indexing on a cold cache), and still had no types for
-- lazy-loaded plugins, which aren't on the rtp until they load.
--
-- Scope: only lua files under a nvim config / plugin dir (lazydev checks
-- for that); a stray lua script elsewhere gets plain lua_ls.

return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      -- vim.uv / vim.loop types: not part of the nvim runtime, they ship as
      -- a separate luv addon that lazydev knows how to fetch.
      { path = "${3rd}/luv/library", words = { "vim%.uv", "vim%.loop" } },
      -- Always-on, regardless of what the buffer requires: the two globals
      -- this config leans on from every plugin spec.
      { path = "snacks.nvim", words = { "Snacks" } },
      { path = "lazy.nvim",   words = { "LazySpec", "LazyPlugin" } },
    },
  },
}
