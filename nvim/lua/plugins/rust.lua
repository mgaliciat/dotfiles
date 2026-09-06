-- ─── rustaceanvim ─────────────────────────────────────────────
-- rust-analyzer done properly: it replaces the lspconfig+rust_analyzer route
-- with runnables/testables, expand-macro, explain-error, the rendered
-- diagnostic, hover actions and a neotest adapter. (It also ships a dap
-- config; unused here — DAP was dropped from this config in sep-2026.)
--
-- It is NOT set up via lspconfig — the plugin registers itself when a
-- .rs buffer loads. That's why it stays out of the loop in lsp.lua, and why
-- `rust_analyzer` is excluded from mason-lspconfig's automatic_enable there
-- (two clients on one buffer otherwise).
--
-- Toolchain prerequisites — rustup, NOT mason, so the server matches the
-- compiler it analyses for:
--   rustup component add rust-analyzer rustfmt rust-src clippy
-- rust-src is the one people forget: without it rust-analyzer starts but
-- knows nothing about std (no completion on `Vec`, no go-to-def into the
-- library). This machine had rust-analyzer as a rustup PROXY with no
-- component behind it until sep-2026 — the LSP had never actually run.

return {
  "mrcjkb/rustaceanvim",
  version = "^6",
  lazy = false,                     -- the plugin auto-activates by ft; "lazy = false" is the author's convention
  ft = { "rust" },
  config = function()
    vim.g.rustaceanvim = {
      tools = {
        -- Runnables/testables run in a neotest-style task, not a split
        -- terminal: output goes where `<leader>to` already looks.
        executor = "background",
        test_executor = "neotest",
        crate_test_executor = "neotest",
        enable_clippy = true,
        -- Floats (hover actions, explain error, expand macro) with the same
        -- frame as every other float in this config.
        float_win_config = { border = "rounded", auto_focus = false },
        code_actions = { ui_select_fallback = true },
      },

      server = {
        on_attach = function(_, bufnr)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end
          -- Rust-only keys, under <leader>c beside the LSP ones from lsp.lua
          -- (ca/cs/cl/ch/cf/cd).
          map("n", "<leader>cr", function() vim.cmd.RustLsp("runnables") end,      "Rust: runnables")
          map("n", "<leader>ce", function() vim.cmd.RustLsp("explainError") end,   "Rust: explain error (rustc --explain)")
          map("n", "<leader>cE", function() vim.cmd.RustLsp("expandMacro") end,    "Rust: expand macro")
          map("n", "<leader>cx", function() vim.cmd.RustLsp("renderDiagnostic") end, "Rust: render diagnostic (as cargo prints it)")
          map("n", "<leader>cp", function() vim.cmd.RustLsp("parentModule") end,   "Rust: parent module")
          map("n", "<leader>cC", function() vim.cmd.RustLsp("openCargo") end,      "Rust: open Cargo.toml")
          map("n", "<leader>ck", function() vim.cmd.RustLsp("openDocs") end,       "Rust: docs.rs for symbol")
          -- Hover with actions (go to impl, run test, open docs) instead of
          -- the plain LSP hover. Same K, richer float.
          map("n", "K", function() vim.cmd.RustLsp({ "hover", "actions" }) end,    "Rust: hover actions")
          -- Join lines the rust-analyzer way: it knows about trailing commas,
          -- `{}` blocks and string continuation, `J` does not.
          map("n", "J", function() vim.cmd.RustLsp("joinLines") end,               "Rust: join lines (rust-analyzer)")
        end,

        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              buildScripts = { enable = true },   -- build.rs and proc-macro crates are analysed, not guessed
            },
            procMacro = { enable = true },
            -- Clippy on save, as `cargo clippy`, not `cargo check`: the
            -- lints land as diagnostics in the buffer. `checkOnSave = { command }`
            -- is the pre-2024 shape and is ignored now.
            checkOnSave = true,
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" },        -- lint this crate, not the dependency tree
            },
            imports = {
              granularity = { group = "module" }, -- `use a::{b, c};` per module, rustfmt-compatible
              prefix = "self",
            },
            inlayHints = {
              lifetimeElisionHints = { enable = "always", useParameterNames = true },
              closureReturnTypeHints = { enable = "always" },
              reborrowHints = { enable = "always" },
              expressionAdjustmentHints = { enable = "reborrow" },  -- show implicit `&*`, not every coercion
              bindingModeHints = { enable = true },
              closureCaptureHints = { enable = true },
              maxLength = 30,                       -- a type hint longer than this is noise, not help
            },
            diagnostics = {
              experimental = { enable = true },     -- rust-analyzer's own (unused-mut style) on top of rustc's
            },
            lens = {
              enable = true,
              references = { adt = { enable = true }, method = { enable = true }, trait = { enable = true } },
            },
            semanticHighlighting = {
              operator = { specialization = { enable = true } },
              punctuation = { enable = true, specialization = { enable = true } },
            },
            rustfmt = { rangeFormatting = { enable = true } },
          },
        },
      },
    }
  end,
}
