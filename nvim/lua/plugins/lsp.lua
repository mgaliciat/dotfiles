-- ─── LSP: mason + lspconfig ───────────────────────────────────
-- Mason installs servers in ~/.local/share/nvim/mason/ → doesn't pollute
-- brew. lspconfig provides the base configurations per server.
--
-- Rust is configured separately in plugins/rust.lua via rustaceanvim
-- (better inlay hints, runnables, debug than the generic lspconfig).
--
-- SYSTEM prerequisites (mason does NOT handle them):
--   - go        → for gopls             (`brew install go`)
--   - node      → for ts/angular/astro/intelephense/html/css/json/yaml
--                 (you already have it — Claude Code requires it)
--   - python3   → for basedpyright     (system or pyenv)
--   - php       → optional, to validate paths in intelephense
--   - rustup    → for rust-analyzer     (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
--
-- Mason installs the rest on demand. `:Mason` to see the state.

return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    build = ":MasonUpdate",
    opts = {
      ui = { border = "rounded" },
    },
  },

  -- Non-LSP tools mason must ALSO own: formatters, linters, test runners.
  -- mason-lspconfig only knows servers — so `stylua`, `goimports` and
  -- `gofumpt` were all referenced by conform and none was ever installed.
  -- This runs at startup and closes that gap;
  -- nothing here goes to brew (see "Mason doesn't pollute brew", CLAUDE.md).
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        -- Lua
        "stylua",
        -- Go
        "gofumpt",        -- stricter gofmt (conform)
        "goimports",      -- import grouping (conform)
        "golangci-lint",  -- meta-linter (nvim-lint)
        "gotestsum",      -- test runner neotest-golang prefers (structured output)
        -- Rust: nothing — the toolchain is rustup's (rust-analyzer, rustfmt,
        -- rust-src, clippy — see plugins/rust.lua)
        -- Shell
        "shfmt",
        "shellcheck",     -- bashls only runs it "if on PATH", and nothing else put it there
        -- Docs / infra (nvim-lint)
        "markdownlint-cli2",
        "hadolint",       -- Dockerfile best practices
        -- Web (conform, manual `<leader>cf`). prettierd is the daemon
        -- flavour conform tries first; the plain `prettier` fallback in
        -- conform.lua is for repos that ship their own in node_modules.
        "prettierd",
        -- NOT here, both for the same reason — mason has them but they need
        -- a system runtime no machine has, and a package that fails installs
        -- retries (and fails) on every start: php_cs_fixer needs `php`;
        -- sqlfluff needs python ≥3.10 and macOS ships 3.9 (runtimes live in
        -- Dockerfiles here, not on the host). conform keeps listing both, so
        -- `brew install php` / a newer python + `:MasonInstall` is all it takes.
      },
      run_on_start = true,
      start_delay = 3000,   -- ms; don't compete with startup
    },
  },

  -- SchemaStore: catalog of JSON/YAML schemas (package.json, tsconfig,
  -- GitHub Actions, k8s, etc.). Without this, jsonls and yamlls don't know
  -- how to validate anything by default.
  { "b0o/SchemaStore.nvim", lazy = true },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
      "b0o/SchemaStore.nvim",
    },
    config = function()
      -- NOTE: as of nvim 0.11+ the correct API is vim.lsp.config() +
      -- vim.lsp.enable(). lspconfig is still a dependency because it exposes
      -- each server's defaults (cmd, root_dir, filetypes) via
      -- vim.lsp.config[name] when it loads — but we do NOT use its .setup().
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- List of servers that mason installs automatically.
      -- Rust is deliberately left out — rustaceanvim handles it in rust.lua.
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- Web / JS ecosystem
          "ts_ls",          -- TypeScript / JavaScript / React (.tsx)
          "eslint",         -- ESLint rules as diagnostics + fix-all (js/ts/vue/svelte/astro)
          "angularls",      -- Angular (HTML templates + TS components)
          "astro",          -- Astro (.astro files)
          "html",           -- HTML standalone
          "cssls",          -- CSS / SCSS / Less
          "emmet_ls",       -- Emmet abbrev (div.foo>span → markup)
          "jsonls",         -- JSON + JSONC (with schemas via SchemaStore)
          "yamlls",         -- YAML (with k8s/GitHub Actions/etc. schemas)

          -- Backend / systems
          "gopls",          -- Go
          "intelephense",   -- PHP
          "basedpyright",   -- Python type checker (improved fork of pyright)
          "ruff",           -- Python linter + formatter (Rust, ultra-fast)

          -- Shell / scripting / docs
          "bashls",         -- Bash / sh / zsh
          "lua_ls",         -- Lua (to configure nvim itself)
          "marksman",       -- Markdown
        },
        automatic_installation = true,
        -- mason-lspconfig v2 enables EVERY installed mason package that
        -- lspconfig has a server file for. stylua ships an LSP mode and
        -- lspconfig knows it, so installing stylua (for conform) also
        -- attached a second "stylua" client next to lua_ls — a duplicate
        -- formatter provider that fights conform's format-on-save.
        -- rust_analyzer is excluded for the same reason as rustaceanvim
        -- staying out of `ensure_installed`: it owns that client.
        automatic_enable = { exclude = { "stylua", "rust_analyzer" } },
      })

      -- on_attach via LspAttach autocmd (idiomatic post-0.10).
      -- Runs once for every LSP that attaches to a buffer.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(ev)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
          end

          -- Floating Glance instead of a direct jump: with the before_open hook,
          -- if there's only 1 result it jumps anyway; if there are several, peek window.
          map("n", "gd", "<cmd>Glance definitions<cr>",      "Goto definition")
          map("n", "gD", vim.lsp.buf.declaration,            "Goto declaration")
          map("n", "gr", "<cmd>Glance references<cr>",       "References")
          map("n", "gi", "<cmd>Glance implementations<cr>",  "Goto implementation")
          map("n", "gt", "<cmd>Glance type_definitions<cr>", "Goto type definition")
          map("n", "K", vim.lsp.buf.hover,                 "Hover docs")
          -- IncRename: live preview of the call sites while you type.
          -- expr=true → the returned string runs as if you had typed it.
          -- No <CR> at the end → the cmdline stays open for editing.
          vim.keymap.set("n", "<leader>rn", function()
            return ":IncRename " .. vim.fn.expand("<cword>")
          end, { buffer = ev.buf, expr = true, desc = "Rename symbol (inc-rename live preview)" })
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>cs", vim.lsp.buf.signature_help, "Signature help")

          -- Code lens: runs the lens on the current line (go test, go generate, go mod tidy, etc.)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client:supports_method("textDocument/codeLens") then
            map("n", "<leader>cl", vim.lsp.codelens.run, "Run code lens")
            -- nvim 0.12+: enable() auto-refreshes via the decoration provider (on_win).
            -- Replaces the old refresh() + BufEnter/BufWritePost autocmd pattern.
            vim.lsp.codelens.enable(true, { bufnr = ev.buf })
          end

          -- Inlay hints (Go, Rust, TS, Python via basedpyright support them).
          if vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
            map("n", "<leader>ch", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
                                        { bufnr = ev.buf })
            end, "Toggle inlay hints")
          end
        end,
      })

      -- Per-server configurations. Overrides go here; defaults come
      -- from lspconfig. Each entry merges with capabilities at the end.
      local servers = {
        -- ─── Web / JS ecosystem ────────────────────────────────
        ts_ls = {
          -- In Angular projects, angularls takes the lead; ts_ls covers
          -- standalone TS files and mixed React/Next/Astro projects.
        },

        -- ESLint as a language server (vscode-eslint-language-server): the
        -- project's own eslint config drives it, so a repo without one gets
        -- no diagnostics and no client noise. ts_ls reports types, this
        -- reports rules — the two don't overlap. Covers js/ts/tsx, vue,
        -- svelte and astro (lspconfig's filetype list). Fixes come as code
        -- actions (`<leader>ca` → "Fix all auto-fixable problems") and as
        -- the buffer command `:LspEslintFixAll`; NOT on save, same policy as
        -- prettier in conform.lua — project style is the project's call.
        eslint = {
          settings = {
            -- Resolve the working directory per file from the nearest
            -- eslint config; the default (the LSP root) breaks monorepos
            -- where each package has its own config.
            workingDirectories = { mode = "auto" },
          },
        },

        angularls = {
          -- mason provides tsserver internally, no extra config required
          -- for standard Angular projects.
        },

        astro = {
          -- Covers .astro files (mix of HTML + JS/TS frontmatter).
          -- Auto-detects the project's tsconfig.
        },

        html = {
          filetypes = { "html", "templ" },
        },

        cssls = {
          settings = {
            css  = { validate = true, lint = { unknownAtRules = "ignore" } },
            scss = { validate = true, lint = { unknownAtRules = "ignore" } },
            less = { validate = true },
          },
        },

        emmet_ls = {
          filetypes = { "html", "css", "scss", "less", "sass", "javascriptreact",
                        "typescriptreact", "vue", "svelte", "astro" },
        },

        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),  -- all known schemas
              validate = { enable = true },
            },
          },
        },

        yamlls = {
          settings = {
            yaml = {
              schemaStore = {
                enable = false,        -- disable the builtin → we use SchemaStore.nvim
                url = "",
              },
              schemas = require("schemastore").yaml.schemas(),
              validate = true,
              format = { enable = true },
            },
          },
        },

        -- ─── Backend / systems ─────────────────────────────────
        gopls = {
          -- gomod/gowork/gotmpl on top of lspconfig's default so `go.mod`
          -- gets the tidy/upgrade lenses and templates get completion.
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          settings = {
            gopls = {
              gofumpt = true,
              usePlaceholders = true,
              completeUnimported = true,
              -- ALL staticcheck analyzers, not the maintainers' subset —
              -- the extra ones are the style/simplification family (S*, ST*)
              -- that golangci-lint would otherwise duplicate in nvim-lint.
              staticcheck = true,
              semanticTokens = true,                  -- more precise highlighting (variable vs type vs function)
              experimentalPostfixCompletions = true,  -- `err.iferr<Tab>` → `if err != nil { return err }`
              -- govulncheck on the imports graph, not on prompt: a CVE in a
              -- dependency shows as a diagnostic on the import line.
              vulncheck = "Imports",
              -- Deep diagnostics 250ms after the last keystroke instead of
              -- the 1s default — gopls 0.21 is fast enough on a laptop.
              diagnosticsDelay = "250ms",
              symbolScope = "workspace",              -- workspace symbols don't crawl GOROOT/deps
              directoryFilters = {                    -- perf on large repos
                "-node_modules",
                "-vendor",
                "-.git",
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
                ignoredError = true,                  -- `_ = f()` hint when an error is dropped
              },
              -- Additional diagnostics. fieldalignment is left out because it's
              -- famously noisy (prioritizes memory over logical order).
              analyses = {
                unusedparams   = true,  -- parameters never used
                unusedwrite    = true,  -- you write to a field and nobody reads it
                unusedvariable = true,  -- with a quick-fix that deletes the declaration
                nilness        = true,  -- detects nil derefs
                useany         = true,  -- prefers `any` over `interface{}` (Go 1.18+)
                shadow         = true,  -- variable shadowing (gopls handles the `if err :=` pattern well)
              },
              -- Code lenses: inline prefix-actions, run with <leader>cl.
              -- `test` and `gc_details` are gone in gopls ≥0.18 (tests are
              -- neotest's job now, gc details became a code action).
              codelenses = {
                generate           = true,  -- run `go generate` from the buffer
                tidy               = true,  -- `go mod tidy`
                upgrade_dependency = true,  -- list available upgrades
                run_govulncheck    = true,  -- full govulncheck on demand from go.mod
                vendor             = true,
                regenerate_cgo     = true,
              },
            },
          },
        },

        intelephense = {
          settings = {
            intelephense = {
              files = { maxSize = 5000000 },   -- 5MB; large projects need it
            },
          },
        },

        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",    -- "off" | "basic" | "standard" | "strict" | "all"
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly", -- "workspace" indexes the WHOLE repo (expensive)
                inlayHints = {
                  variableTypes = true,
                  callArgumentNames = true,
                  functionReturnTypes = true,
                  genericTypes = false,
                },
              },
            },
          },
        },

        ruff = {
          -- ruff does linting + formatting + import sorting. We disable
          -- hover because basedpyright does it better (we don't want to duplicate UI).
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
        },

        -- ─── Shell / scripting / docs ──────────────────────────
        bashls = {
          filetypes = { "sh", "bash", "zsh" },
        },

        lua_ls = {
          -- The nvim runtime and plugin libraries are NOT listed here: lazydev
          -- (plugins/lazydev.lua) adds them per-buffer, only the ones the file
          -- actually requires. The old `nvim_get_runtime_file("", true)` shipped
          -- every runtime dir to the server on every start — seconds of
          -- indexing, and no types for lazy-loaded plugins.
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              workspace = { checkThirdParty = false },
              diagnostics = {
                globals = { "vim" },
                -- `missing-fields` fires on every partial opts table handed to
                -- a plugin's setup(), which is the whole shape of a lazy spec.
                disable = { "missing-fields" },
              },
              -- Inlay hints, same treatment as gopls: parameter names at call
              -- sites and inferred types on locals; index hints are noise.
              hint = {
                enable = true,
                setType = true,
                paramType = true,
                paramName = "Literal",     -- only when the argument is a literal, not a variable
                arrayIndex = "Disable",
                semicolon = "Disable",
              },
              codeLens = { enable = true },
              format = { enable = false },   -- stylua via conform
              telemetry = { enable = false },
              completion = { callSnippet = "Replace" },
              -- `_foo` is private: hover/completion stop suggesting it from
              -- outside the module.
              doc = { privateName = { "^_" } },
            },
          },
        },

        marksman = {},
      }

      -- Modern API (nvim 0.11+): vim.lsp.config() merges with the defaults
      -- that lspconfig publishes in vim.lsp.config[name]. vim.lsp.enable()
      -- activates them for the corresponding filetypes.
      for name, cfg in pairs(servers) do
        cfg.capabilities = capabilities
        vim.lsp.config(name, cfg)
      end
      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },
}
