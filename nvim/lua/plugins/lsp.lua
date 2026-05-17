-- ─── LSP: mason + lspconfig ───────────────────────────────────
-- Mason instala servers en ~/.local/share/nvim/mason/ → no contamina
-- brew. lspconfig provee las configuraciones base por server.
--
-- Rust se configura aparte en plugins/rust.lua vía rustaceanvim
-- (mejor inlay hints, runnables, debug que el lspconfig genérico).
--
-- Pre-requisitos del SISTEMA (mason NO los maneja):
--   - go        → para gopls            (`brew install go`)
--   - node      → para ts/angular/astro/intelephense/html/css/json/yaml
--                 (ya lo tenés — Claude Code lo requiere)
--   - python3   → para basedpyright    (sistema o pyenv)
--   - php       → opcional, para validar paths en intelephense
--   - rustup    → para rust-analyzer    (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
--
-- Mason instala el resto bajo demanda. `:Mason` para ver el estado.

return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    build = ":MasonUpdate",
    opts = {
      ui = { border = "rounded" },
    },
  },

  -- SchemaStore: catálogo de schemas JSON/YAML (package.json, tsconfig,
  -- GitHub Actions, k8s, etc.). Sin esto, jsonls y yamlls no saben
  -- validar nada por default.
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
      -- NOTA: a partir de nvim 0.11+ la API correcta es vim.lsp.config() +
      -- vim.lsp.enable(). lspconfig sigue siendo dependencia porque expone
      -- los defaults de cada server (cmd, root_dir, filetypes) vía
      -- vim.lsp.config[name] al cargarse — pero NO usamos su .setup().
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Lista de servers que mason instala automáticamente.
      -- Rust queda fuera adrede — rustaceanvim lo maneja en rust.lua.
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- Web / JS ecosystem
          "ts_ls",          -- TypeScript / JavaScript / React (.tsx)
          "angularls",      -- Angular (HTML templates + TS components)
          "astro",          -- Astro (.astro files)
          "html",           -- HTML standalone
          "cssls",          -- CSS / SCSS / Less
          "emmet_ls",       -- Emmet abbrev (div.foo>span → markup)
          "jsonls",         -- JSON + JSONC (con schemas vía SchemaStore)
          "yamlls",         -- YAML (con schemas k8s/GitHub Actions/etc.)

          -- Backend / systems
          "gopls",          -- Go
          "intelephense",   -- PHP
          "basedpyright",   -- Python type checker (fork mejorado de pyright)
          "ruff",           -- Python linter + formatter (Rust, ultrarrápido)

          -- Shell / scripting / docs
          "bashls",         -- Bash / sh / zsh
          "lua_ls",         -- Lua (para configurar nvim mismo)
          "marksman",       -- Markdown
        },
        automatic_installation = true,
      })

      -- on_attach vía LspAttach autocmd (idiomatic post-0.10).
      -- Se ejecuta una vez por cada LSP que se adjunta a un buffer.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(ev)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
          end

          map("n", "gd", vim.lsp.buf.definition,           "Goto definition")
          map("n", "gD", vim.lsp.buf.declaration,          "Goto declaration")
          map("n", "gr", vim.lsp.buf.references,           "References")
          map("n", "gi", vim.lsp.buf.implementation,       "Goto implementation")
          map("n", "gt", vim.lsp.buf.type_definition,      "Goto type definition")
          map("n", "K",  vim.lsp.buf.hover,                "Hover docs")
          map("n", "<leader>rn", vim.lsp.buf.rename,       "Rename symbol")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>cs", vim.lsp.buf.signature_help, "Signature help")

          -- Inlay hints (Go, Rust, TS, Python via basedpyright los soportan).
          if vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
            map("n", "<leader>ch", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
                                        { bufnr = ev.buf })
            end, "Toggle inlay hints")
          end
        end,
      })

      -- Configuraciones por server. Overrides van aquí; defaults vienen
      -- de lspconfig. Cada entry merge con capabilities al final.
      local servers = {
        -- ─── Web / JS ecosystem ────────────────────────────────
        ts_ls = {
          -- En proyectos Angular, angularls toma el lead; ts_ls cubre
          -- archivos TS sueltos y proyectos React/Next/Astro mixtos.
        },

        angularls = {
          -- mason provee tsserver internamente, no requiere config extra
          -- para proyectos Angular estándar.
        },

        astro = {
          -- Cubre archivos .astro (mezcla HTML + frontmatter JS/TS).
          -- Auto-detecta el tsconfig del proyecto.
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
              schemas = require("schemastore").json.schemas(),  -- todos los schemas conocidos
              validate = { enable = true },
            },
          },
        },

        yamlls = {
          settings = {
            yaml = {
              schemaStore = {
                enable = false,        -- desactivar el builtin → usamos SchemaStore.nvim
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
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },

        intelephense = {
          settings = {
            intelephense = {
              files = { maxSize = 5000000 },   -- 5MB; proyectos grandes lo necesitan
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
                diagnosticMode = "openFilesOnly", -- "workspace" indexa TODO el repo (caro)
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
          -- ruff hace linting + formatting + import sorting. Desactivamos
          -- hover porque basedpyright lo hace mejor (no queremos duplicar UI).
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

      -- API moderna (nvim 0.11+): vim.lsp.config() merge con los defaults
      -- que lspconfig publica en vim.lsp.config[name]. vim.lsp.enable()
      -- los activa para los filetypes correspondientes.
      for name, cfg in pairs(servers) do
        cfg.capabilities = capabilities
        vim.lsp.config(name, cfg)
      end
      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },
}
