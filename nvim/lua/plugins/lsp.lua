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
          -- K: if the cursor is over a closed fold, ufo opens the peek
          -- window with the folded content; if not, it falls back to the normal LSP hover.
          -- Without this wrapper, LspAttach's buffer-local mapping wins over
          -- ufo's global mapping and you lose the peek in any buffer with LSP.
          map("n", "K", function()
            local ok, ufo = pcall(require, "ufo")
            if ok then
              local winid = ufo.peekFoldedLinesUnderCursor()
              if winid then return end
            end
            vim.lsp.buf.hover()
          end, "Peek fold / Hover docs")
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
          settings = {
            gopls = {
              gofumpt = true,
              usePlaceholders = true,
              completeUnimported = true,
              staticcheck = true,
              semanticTokens = true,                  -- more precise highlighting (variable vs type vs function)
              experimentalPostfixCompletions = true,  -- `err.iferr<Tab>` → `if err != nil { return err }`
              directoryFilters = {                    -- perf on large repos
                "-node_modules",
                "-vendor",
                "-.git",
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              -- Additional diagnostics. fieldalignment is left out because it's
              -- famously noisy (prioritizes memory over logical order).
              analyses = {
                unusedparams = true,    -- parameters never used
                unusedwrite  = true,    -- you write to a field and nobody reads it
                nilness      = true,    -- detects nil derefs
                useany       = true,    -- prefers `any` over `interface{}` (Go 1.18+)
                shadow       = true,    -- variable shadowing (gopls handles the `if err :=` pattern well)
              },
              -- Code lenses: inline prefix-actions. Run them with
              -- `:lua vim.lsp.codelens.run()` (mapped to <leader>cl below).
              codelenses = {
                generate           = true,  -- run `go generate` from the buffer
                test               = true,  -- run the current package's tests
                tidy               = true,  -- `go mod tidy`
                upgrade_dependency = true,  -- list available upgrades
                gc_details         = true,  -- inline escape analysis
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
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
              },
              diagnostics = { globals = { "vim" } },
              telemetry = { enable = false },
              completion = { callSnippet = "Replace" },
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
