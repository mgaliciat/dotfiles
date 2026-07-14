-- ─── rustaceanvim ─────────────────────────────────────────────
-- Replaces the lspconfig+rust_analyzer config with a richer setup:
-- Rust-specific inlay hints, runnables (individual test with
-- <leader>rr), integrated debug, expand-macro.
--
-- It is NOT set up via lspconfig — the plugin registers itself when a
-- .rs buffer loads. That's why it stays out of the loop in lsp.lua.
--
-- Prerequisite: rust-analyzer in the PATH. Options:
--   - rustup component add rust-analyzer  (recommended — follows your toolchain)
--   - mason: `:MasonInstall rust-analyzer`

return {
  "mrcjkb/rustaceanvim",
  version = "^6",
  lazy = false,                     -- the plugin auto-activates by ft; "lazy = false" is the author's convention
  ft = { "rust" },
  config = function()
    vim.g.rustaceanvim = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            inlayHints = {
              lifetimeElisionHints = { enable = "always" },
            },
          },
        },
      },
    }
  end,
}
