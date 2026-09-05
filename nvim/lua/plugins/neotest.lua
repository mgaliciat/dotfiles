-- ─── neotest ──────────────────────────────────────────────────
-- Tests from the editor: run the test under the cursor, the file or the
-- whole suite, with pass/fail signs in the gutter, a summary tree and the
-- failing test's output in a float. gopls dropped its `test` code lens in
-- 0.18, and `go test ./...` in a terminal can't point at a line.
--
-- Go adapter: neotest-golang (fredrikaverpil), the maintained one — the
-- older nvim-neotest/neotest-go is archived. It runs `gotestsum` when
-- present (structured JSON, parallel by package) and falls back to
-- `go test -json`; gotestsum comes from mason-tool-installer (lsp.lua).
--
-- Rust: rustaceanvim ships its own adapter, driven by rust-analyzer's
-- runnables (so it sees doctests, integration tests and workspace crates
-- the way cargo does). Do NOT add neotest-rust beside it — upstream says
-- the two conflict.
--
-- Lua: no adapter. This config has no lua test suite, and neotest-plenary
-- would add a dependency for zero tests. Add it the day one exists.
--
-- Keys under <leader>t (group registered in which-key.lua). `<leader>td`
-- debugs the nearest test through nvim-dap-go, same delve as <leader>cgt.

return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "fredrikaverpil/neotest-golang",
    "mrcjkb/rustaceanvim",
  },
  keys = {
    { "<leader>tt", function() require("neotest").run.run() end,                      desc = "Test: nearest" },
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,    desc = "Test: file" },
    { "<leader>ta", function() require("neotest").run.run(vim.uv.cwd()) end,          desc = "Test: all (cwd)" },
    { "<leader>tl", function() require("neotest").run.run_last() end,                 desc = "Test: re-run last" },
    { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end,  desc = "Test: debug nearest" },
    { "<leader>ts", function() require("neotest").summary.toggle() end,               desc = "Test: summary" },
    { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Test: output" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end,          desc = "Test: output panel" },
    { "<leader>tS", function() require("neotest").run.stop() end,                     desc = "Test: stop" },
    { "]t",         function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next failed test" },
    { "[t",         function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev failed test" },
  },
  opts = function()
    return {
      adapters = {
        require("neotest-golang")({
          -- -race and -count=1 every run: a test that only fails under the
          -- race detector or with a warm cache is a test you want to see fail.
          go_test_args = { "-v", "-race", "-count=1" },
          -- gotestsum when mason has it; the adapter falls back on its own.
          runner = "gotestsum",
          -- Debug through nvim-dap-go's delve config (plugins/dap.lua).
          dap_go_enabled = true,
        }),
        require("rustaceanvim.neotest"),
      },
      -- Diagnostics from failed assertions on the failing line, like an LSP.
      diagnostic = { enabled = true, severity = vim.diagnostic.severity.ERROR },
      status  = { enabled = true, virtual_text = true, signs = true },
      output  = { open_on_run = false },
      summary = {
        open = "botright vsplit | vertical resize 40",
      },
      icons = {
        passed  = "",
        failed  = "",
        running = "",
        skipped = "",
        unknown = "",
      },
    }
  end,
}
