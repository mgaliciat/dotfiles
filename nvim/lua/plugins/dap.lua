-- ─── DAP: debugger para Go (y base extensible) ────────────────
-- Stack:
--   nvim-dap        → core del protocolo Debug Adapter
--   nvim-dap-ui     → UI con scopes, watches, stacks, repl en splits
--   nvim-nio        → async runtime que dap-ui requiere
--   nvim-dap-go     → config específica para Go (delve + test debugging)
--   mason-nvim-dap  → instala adapters (delve) sin contaminar brew
--
-- Pre-requisito sistema: `go` en PATH (ya lo tenés para gopls).
-- mason-nvim-dap se encarga de delve — verificalo con `:Mason`.
--
-- Keymaps elegidos para NO chocar con `<leader>d` (= delete black-hole
-- en keymaps.lua). Acciones activas vía F-keys (estándar de la mayoría
-- de IDEs); breakpoints y UI vía `<leader>c*` (grupo "code").

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "leoluz/nvim-dap-go",
    },
    keys = {
      -- Control de ejecución (F-keys, convención IDE)
      { "<F5>",    function() require("dap").continue() end,          desc = "Debug: continue / start" },
      { "<F10>",   function() require("dap").step_over() end,         desc = "Debug: step over" },
      { "<F11>",   function() require("dap").step_into() end,         desc = "Debug: step into" },
      { "<F12>",   function() require("dap").step_out() end,          desc = "Debug: step out" },

      -- Breakpoints y UI bajo grupo "code" (no choca con <leader>d)
      { "<leader>cb", function() require("dap").toggle_breakpoint() end,                                  desc = "Toggle breakpoint" },
      { "<leader>cB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end,          desc = "Conditional breakpoint" },
      { "<leader>cu", function() require("dapui").toggle() end,                                           desc = "Toggle debug UI" },
      { "<leader>cR", function() require("dap").run_last() end,                                           desc = "Re-run last debug session" },
      { "<leader>ct", function() require("dap").terminate() end,                                          desc = "Terminate debug session" },

      -- Específicos de Go (delegate al plugin nvim-dap-go)
      { "<leader>cgt", function() require("dap-go").debug_test() end,      desc = "Go: debug nearest test", ft = "go" },
      { "<leader>cgT", function() require("dap-go").debug_last_test() end, desc = "Go: debug last test",    ft = "go" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      -- mason-nvim-dap instala adapters declarados acá. delve es el
      -- único que necesitamos por ahora (Go). Si en el futuro debuggeás
      -- Python/JS/Rust, agregalos al ensure_installed.
      require("mason-nvim-dap").setup({
        ensure_installed = { "delve" },
        automatic_installation = true,
        handlers = {},  -- usá defaults; nvim-dap-go configura Go aparte
      })

      -- nvim-dap-go: registra config para .go files + helpers para tests.
      -- Pasa delve flags útiles: `-test.v` para output verbose en tests.
      require("dap-go").setup({
        delve = {
          detached = vim.fn.has("win32") == 0,  -- detached en macOS/Linux
        },
      })

      -- UI: layout default (scopes/watches/stack arriba-izquierda; repl
      -- y console abajo). Auto-abre al iniciar sesión, auto-cierra al terminar.
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        floating = { border = "rounded" },
      })

      dap.listeners.before.attach.dapui_config           = function() dapui.open() end
      dap.listeners.before.launch.dapui_config           = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config     = function() dapui.close() end

      -- Signs: que el gutter muestre el breakpoint con color de la paleta.
      vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn",  linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint",            { text = "◆", texthl = "DiagnosticInfo",  linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DiagnosticOk",    linehl = "Visual", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticHint",  linehl = "", numhl = "" })
    end,
  },
}
