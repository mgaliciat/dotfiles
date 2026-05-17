-- ─── rustaceanvim ─────────────────────────────────────────────
-- Reemplaza la config lspconfig+rust_analyzer con un setup más rico:
-- inlay hints específicos de Rust, runnables (test individual con
-- <leader>rr), debug integrado, expand-macro.
--
-- NO se setea vía lspconfig — el plugin se autoregistra al cargar
-- un buffer .rs. Por eso queda fuera del loop en lsp.lua.
--
-- Pre-requisito: rust-analyzer en el PATH. Opciones:
--   - rustup component add rust-analyzer  (recomendado — sigue tu toolchain)
--   - mason: `:MasonInstall rust-analyzer`

return {
  "mrcjkb/rustaceanvim",
  version = "^6",
  lazy = false,                     -- el plugin se auto-activa por ft; "lazy = false" es por convención del autor
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
