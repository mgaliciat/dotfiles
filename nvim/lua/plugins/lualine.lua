-- ─── lualine.nvim ─────────────────────────────────────────────
-- Statusline. Theme = "auto" → lualine detects the active
-- colorscheme and applies the lualine theme that plugin exports
-- (solarized-osaka, tokyonight, etc. all ship their own).
-- craftzdog pattern: never hardcode a palette here, let the
-- colorscheme rule. You change `vim.g.theme` → the statusline
-- syncs by itself.
--
-- The right side answers "which tools are on this buffer?" — with 16
-- servers, 3 linters and 6 formatters configured, the name of the one
-- that actually attached is the first thing to check when something
-- doesn't fire. Each component is empty when it has nothing to say,
-- so a plain-text buffer shows only the filetype.
--
-- Components that read a plugin check `package.loaded` instead of calling
-- `require`: lazy.nvim hooks `require`, so a statusline component that
-- requires conform or harpoon loads it on the first redraw and defeats the
-- trigger its own spec declares (conform on BufWritePre, harpoon on its
-- keys). Until that trigger fires the component stays empty — no formatter
-- before the first save or `<leader>cf`, no harpoon slot before the first
-- harpoon key.

-- LSP clients attached to the current buffer, by name. Hides the ones
-- that are infrastructure rather than a language (copilot-style helpers
-- would go here too).
local function lsp_clients()
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if c.name ~= "null-ls" and c.name ~= "crates" then
      names[#names + 1] = c.name
    end
  end
  return #names > 0 and (" " .. table.concat(names, " ")) or ""
end

-- nvim-lint linters registered for this filetype (not "currently
-- running" — that's a flash; this is "what will run on save"). Resolved the
-- way nvim-lint's try_lint does: the exact filetype's entry if it has one,
-- otherwise the union of its dotted parts (`markdown.mdx` → markdown's).
-- An exact-only lookup showed nothing on .mdx while lint.lua linted it.
local function linters()
  local lint = package.loaded["lint"]
  if not lint then return "" end
  local ft    = vim.bo.filetype
  local names = lint.linters_by_ft[ft]
  if not names then
    names = {}
    for part in ft:gmatch("[^.]+") do
      for _, name in ipairs(lint.linters_by_ft[part] or {}) do
        if not vim.tbl_contains(names, name) then names[#names + 1] = name end
      end
    end
  end
  return #names > 0 and ("󰁨 " .. table.concat(names, " ")) or ""
end

-- conform formatters that would run on `<leader>cf` / on save. Only the
-- available ones: a name the binary is missing for is exactly the
-- situation the cheatsheet's "formatter that silently never runs"
-- warns about, and showing it as active would hide that.
local function formatters()
  local conform = package.loaded["conform"]
  if not conform then return "" end
  local names = {}
  for _, f in ipairs(conform.list_formatters(0)) do
    if f.available then names[#names + 1] = f.name end
  end
  return #names > 0 and ("󰉼 " .. table.concat(names, " ")) or ""
end

-- `recording @q` while a macro is being recorded — `showmode` is off
-- (lualine owns the mode), which also hid this native message.
local function macro()
  local reg = vim.fn.reg_recording()
  return reg ~= "" and ("󰑊 @" .. reg) or ""
end

-- Harpoon slot of the current file, `󱡅 2/4`, when it is marked.
local function harpoon_slot()
  local harpoon = package.loaded["harpoon"]
  if not harpoon then return "" end
  local list = harpoon:list()
  local current = vim.fn.expand("%:.")
  for i, item in ipairs(list.items) do
    if item.value == current then
      return string.format("󱡅 %d/%d", i, list:length())
    end
  end
  return ""
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      -- No separator overrides → lualine uses its defaults
      -- (powerline chevrons ``), the craftzdog/LazyVim look.
      globalstatus = true,
      disabled_filetypes = { statusline = { "dashboard", "alpha", "snacks_dashboard" } },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", { "diff", symbols = { added = " ", modified = " ", removed = " " } } },
      lualine_c = {
        { "filename", path = 1 },
        { "diagnostics", sources = { "nvim_lsp" } },
        { harpoon_slot },
      },
      lualine_x = {
        { macro, color = "DiagnosticError" },
        { lsp_clients },
        { linters },
        { formatters },
        "filetype",
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },

  -- The colorscheme's lualine theme bakes `bg_statusline` into section `c`
  -- (the filler that spans the bar) and into every inactive section. Over a
  -- transparent colorscheme that is an opaque strip on Ghostty's glass.
  -- `Normal` without a bg IS the transparency signal, so this costs nothing
  -- on an opaque theme. The `a`/`b` blocks keep theirs: the mode badge and the
  -- branch are meant to read as colored blocks.
  config = function(_, opts)
    if require("config.util").hl_hex("Normal", "bg") == nil then
      local theme = vim.deepcopy(require("lualine.themes.auto"))
      for name, mode in pairs(theme) do
        for section, colors in pairs(mode) do
          if section == "c" or name == "inactive" then
            colors.bg = nil
          end
        end
      end
      opts.options.theme = theme
    end
    require("lualine").setup(opts)
  end,
}
