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
-- JS/TS: neotest-vitest and neotest-jest side by side. Each one claims a
-- file only when its own config is in the project root (vitest.config.*,
-- jest.config.* / a "jest" key in package.json), so an Astro or Angular
-- repo lands on the right one and a repo with neither gets no adapter —
-- no "which runner" prompt, no false positives on `*.spec.ts` in a repo
-- that runs karma.
--
-- Python: neotest-python on pytest. It runs the `python` the buffer's
-- project resolves to; with runtimes in Docker rather than on the host,
-- that means it only works inside a repo whose venv is on PATH — the
-- adapter is here so the keys are uniform, not because the host has pytest.
--
-- Lua: no adapter. This config has no lua test suite, and neotest-plenary
-- would add a dependency for zero tests. Add it the day one exists.
--
-- Keys under <leader>t (group registered in which-key.lua). No debug
-- strategy: DAP was dropped from this config (sep-2026) — a failing test's
-- output plus the LSP is what gets read now, not a stepping session.

return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "fredrikaverpil/neotest-golang",
    "mrcjkb/rustaceanvim",
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-jest",
    "nvim-neotest/neotest-python",
  },
  keys = {
    { "<leader>tt", function() require("neotest").run.run() end,                      desc = "Test: nearest" },
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,    desc = "Test: file" },
    { "<leader>ta", function() require("neotest").run.run(vim.uv.cwd()) end,          desc = "Test: all (cwd)" },
    { "<leader>tl", function() require("neotest").run.run_last() end,                 desc = "Test: re-run last" },
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
        }),
        require("rustaceanvim.neotest"),
        require("neotest-vitest"),
        require("neotest-jest")({
          -- Run through the project's own binary, never a global one.
          jestCommand = "npx jest --",
        }),
        require("neotest-python")({
          runner = "pytest",
          -- Re-detect the interpreter per run: the venv can appear after
          -- nvim started (docker exec, direnv).
          python = function() return vim.fn.exepath("python3") end,
        }),
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
