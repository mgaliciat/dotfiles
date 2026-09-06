-- ─── nvim-ts-context-commentstring ────────────────────────────
-- `gc` uses one `commentstring` per buffer, so in a `.astro` / `.tsx` /
-- `.vue` file it comments the `<script>` half with `<!-- -->`. This plugin
-- computes the string from the treesitter node under the cursor instead,
-- so `gcc` on a JS line inside a template gets `//`.
--
-- Wired into nvim's NATIVE commenting (0.10+), not a comment plugin: the
-- built-in `gc` reads `commentstring` through `vim.filetype.get_option`,
-- and that function is the hook. Hence `enable_autocmd = false` (no
-- CursorHold recompute — it's on demand) and `skip_ts_context_commentstring_module`
-- (the legacy nvim-treesitter module registration, gone on `main`).

return {
  "JoosepAlviste/nvim-ts-context-commentstring",
  event = { "BufReadPost", "BufNewFile" },
  init = function()
    vim.g.skip_ts_context_commentstring_module = true
  end,
  opts = { enable_autocmd = false },
  config = function(_, opts)
    require("ts_context_commentstring").setup(opts)
    local get_option = vim.filetype.get_option
    vim.filetype.get_option = function(filetype, option)
      return option == "commentstring"
          and require("ts_context_commentstring.internal").calculate_commentstring()
        or get_option(filetype, option)
    end
  end,
}
