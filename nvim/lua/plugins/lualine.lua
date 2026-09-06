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
-- running" — that's a flash; this is "what will run on save").
local function linters()
  local ok, lint = pcall(require, "lint")
  if not ok then return "" end
  local ls = lint.linters_by_ft[vim.bo.filetype]
  return ls and #ls > 0 and ("󰁨 " .. table.concat(ls, " ")) or ""
end

-- conform formatters that would run on `<leader>cf` / on save. Only the
-- available ones: a name the binary is missing for is exactly the
-- situation the cheatsheet's "formatter that silently never runs"
-- warns about, and showing it as active would hide that.
local function formatters()
  local ok, conform = pcall(require, "conform")
  if not ok then return "" end
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
  local ok, harpoon = pcall(require, "harpoon")
  if not ok then return "" end
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
        { macro, color = { fg = "#e35f5f" } },
        { lsp_clients },
        { linters },
        { formatters },
        "filetype",
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
