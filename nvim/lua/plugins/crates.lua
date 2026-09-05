-- ─── crates.nvim ──────────────────────────────────────────────
-- Cargo.toml as a first-class buffer: latest versions inline as virtual
-- text, completion of crate names / versions / features, popups to pick a
-- version or toggle features, and update/upgrade actions.
--
-- Wired as its in-process LSP (`lsp.enabled`), which is upstream's
-- recommended path: completion arrives through blink's `lsp` source with no
-- extra source to register, hover and code actions come for free, and the
-- LspAttach block in lsp.lua gives it the same K / <leader>ca as any server.

return {
  "saecki/crates.nvim",
  tag = "stable",
  event = { "BufRead Cargo.toml" },
  opts = {
    smart_insert = true,
    completion = {
      crates = { enabled = true, min_chars = 2, max_results = 12 },
    },
    lsp = {
      enabled = true,
      actions = true,
      completion = true,
      hover = true,
      on_attach = function(_, bufnr)
        local crates = require("crates")
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        -- Buffer-local to Cargo.toml only, so they can reuse letters the
        -- Rust buffers give to rustaceanvim.
        map("n", "<leader>cv", crates.show_versions_popup,     "Crates: versions")
        map("n", "<leader>cF", crates.show_features_popup,     "Crates: features")
        map("n", "<leader>cu", crates.update_crate,            "Crates: update (compatible)")
        map("v", "<leader>cu", crates.update_crates,           "Crates: update selection")
        map("n", "<leader>cU", crates.upgrade_crate,           "Crates: upgrade (latest)")
        map("v", "<leader>cU", crates.upgrade_crates,          "Crates: upgrade selection")
        map("n", "<leader>cA", crates.upgrade_all_crates,      "Crates: upgrade all")
        map("n", "<leader>ck", crates.open_documentation,      "Crates: docs.rs")
        map("n", "<leader>cR", crates.open_repository,         "Crates: repository")
      end,
    },
    popup = {
      border = "rounded",
      show_version_date = true,
    },
  },
}
