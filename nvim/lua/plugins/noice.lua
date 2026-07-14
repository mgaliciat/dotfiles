-- ─── noice.nvim ───────────────────────────────────────────────
-- Replaces the native cmdline, messages and popups UI with a
-- modern version (floating cmdline, splits for `:messages`,
-- integrated LSP progress, etc.). INVASIVE PLUGIN — if something about
-- nvim's default experience bothers you, remove this plugin and
-- everything is restored.
--
-- Extra gem (craftzdog's idea): when nvim LOSES FOCUS (you go
-- to Slack/browser), notifications get routed to macOS's native
-- notify — so you find out your `:!make build` finished without
-- having to go back to the nvim window.
--
-- Dependencies: nui.nvim (UI primitives) + nvim-notify (toasts).

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "rcarriga/nvim-notify",
      opts = {
        timeout = 5000,
        render  = "wrapped-compact",
      },
    },
  },
  opts = {
    -- presets: applies common configs as a block
    presets = {
      bottom_search          = true,    -- search on the bottom line, not a float
      command_palette        = true,    -- cmdline + popup together at top-center
      long_message_to_split  = true,    -- long messages open a split
      lsp_doc_border         = true,    -- border on hover/signature
      inc_rename             = true,    -- integrated inc-rename.nvim preview
    },
    -- LSP UI replacements
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"]               = true,
        ["cmp.entry.get_documentation"]                 = true,
      },
    },
  },
  config = function(_, opts)
    -- Focus-routing: if nvim is NOT focused, send notifs to
    -- macOS native (via nvim-notify → osascript fallback).
    local focused = true
    vim.api.nvim_create_autocmd("FocusGained", { callback = function() focused = true end })
    vim.api.nvim_create_autocmd("FocusLost",   { callback = function() focused = false end })

    opts.routes = opts.routes or {}
    table.insert(opts.routes, 1, {
      filter = { cond = function() return not focused end },
      view   = "notify_send",
      opts   = { stop = false },
    })

    -- Filter: silences the LSP hover's "No information available"
    -- when there are no docs — pure noise in languages without documentation.
    table.insert(opts.routes, {
      filter = { event = "notify", find = "No information available" },
      opts   = { skip = true },
    })

    require("noice").setup(opts)
  end,
}
