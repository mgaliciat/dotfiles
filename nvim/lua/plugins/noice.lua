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
      command_palette        = false,   -- was the top-center floating bar; see cmdline below
      long_message_to_split  = true,    -- long messages open a split
      lsp_doc_border         = true,    -- border on hover/signature
      inc_rename             = true,    -- integrated inc-rename.nvim preview
    },

    -- ─── cmdline: terminal style (sep-2026) ───────────────────
    -- `:` lives on the bottom line, like a shell prompt, not in a floating
    -- bar at the top (that was the `command_palette` preset). noice still
    -- owns it — syntax highlighting of the command as you type, the
    -- `:lua`/`:!`/`:h` modes — it just draws it where the cmdline is.
    -- The icons are the literal prompt characters: the typed `:` is
    -- concealed by noice and drawn back as the icon, so `:` stays `:`.
    cmdline = {
      view = "cmdline",
      format = {
        cmdline     = { icon = ":" },
        search_down = { icon = "/" },
        search_up   = { icon = "?" },
        filter      = { icon = "!" },
        lua         = { icon = ":lua" },
        help        = { icon = ":h" },
      },
    },
    -- Completion in the cmdline is nvim's own popup menu (`wildoptions=pum`,
    -- `wildmode` in options.lua), which sits directly above the bottom line
    -- like a shell's menu-select. noice's popupmenu would float in the
    -- middle of the screen once the cmdline is no longer up there with it.
    popupmenu = { enabled = false },
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
