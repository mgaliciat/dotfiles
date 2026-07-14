-- ─── DAP: debugger for Go (and extensible base) ───────────────
-- Stack:
--   nvim-dap        → core of the Debug Adapter protocol
--   nvim-dap-ui     → UI with scopes, watches, stacks, repl in splits
--   nvim-nio        → async runtime that dap-ui requires
--   nvim-dap-go     → Go-specific config (delve + test debugging)
--   mason-nvim-dap  → installs adapters (delve) without polluting brew
--
-- System prerequisite: `go` in PATH (you already have it for gopls).
-- mason-nvim-dap takes care of delve — check it with `:Mason`.
--
-- Keymaps chosen so they do NOT collide with `<leader>d` (= black-hole delete
-- in keymaps.lua). Active actions via F-keys (standard in most
-- IDEs); breakpoints and UI via `<leader>c*` ("code" group).

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
      -- Execution control (F-keys, IDE convention)
      { "<F5>",    function() require("dap").continue() end,          desc = "Debug: continue / start" },
      { "<F10>",   function() require("dap").step_over() end,         desc = "Debug: step over" },
      { "<F11>",   function() require("dap").step_into() end,         desc = "Debug: step into" },
      { "<F12>",   function() require("dap").step_out() end,          desc = "Debug: step out" },

      -- Breakpoints and UI under the "code" group (doesn't collide with <leader>d)
      { "<leader>cb", function() require("dap").toggle_breakpoint() end,                                  desc = "Toggle breakpoint" },
      { "<leader>cB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end,          desc = "Conditional breakpoint" },
      { "<leader>cu", function() require("dapui").toggle() end,                                           desc = "Toggle debug UI" },
      { "<leader>cR", function() require("dap").run_last() end,                                           desc = "Re-run last debug session" },
      { "<leader>ct", function() require("dap").terminate() end,                                          desc = "Terminate debug session" },

      -- Go-specific (delegate to the nvim-dap-go plugin)
      { "<leader>cgt", function() require("dap-go").debug_test() end,      desc = "Go: debug nearest test", ft = "go" },
      { "<leader>cgT", function() require("dap-go").debug_last_test() end, desc = "Go: debug last test",    ft = "go" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      -- mason-nvim-dap installs the adapters declared here. delve is the
      -- only one we need for now (Go). If in the future you debug
      -- Python/JS/Rust, add them to ensure_installed.
      require("mason-nvim-dap").setup({
        ensure_installed = { "delve" },
        automatic_installation = true,
        handlers = {},  -- use defaults; nvim-dap-go configures Go separately
      })

      -- nvim-dap-go: registers config for .go files + helpers for tests.
      -- Passes useful delve flags: `-test.v` for verbose output in tests.
      require("dap-go").setup({
        delve = {
          detached = vim.fn.has("win32") == 0,  -- detached on macOS/Linux
        },
      })

      -- UI: default layout (scopes/watches/stack top-left; repl
      -- and console at the bottom). Auto-opens when the session starts, auto-closes when it ends.
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        floating = { border = "rounded" },
      })

      dap.listeners.before.attach.dapui_config           = function() dapui.open() end
      dap.listeners.before.launch.dapui_config           = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config     = function() dapui.close() end

      -- Signs: make the gutter show the breakpoint with a color from the palette.
      vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn",  linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint",            { text = "◆", texthl = "DiagnosticInfo",  linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DiagnosticOk",    linehl = "Visual", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticHint",  linehl = "", numhl = "" })
    end,
  },
}
