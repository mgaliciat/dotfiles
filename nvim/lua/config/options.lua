-- ─── theme switcher ───────────────────────────────────────────
-- Selecciona qué paleta carga lua/plugins/colorscheme.lua. Los
-- módulos viven en lua/themes/<name>.lua. Variantes disponibles:
--   "obsidian"  high-contrast dark + cyan       (pareja: obsidian-dots)
--   "warm"      dark sepia/naranja              (pareja: anthropic-dots, anthropic-crt)
--   "paper"     light cream + sepia             (pareja: anthropic-paper)
-- Cambiar requiere reiniciar nvim (o :source $MYVIMRC + :colorscheme ...).
vim.g.theme = "obsidian"

-- ─── vim.opt ──────────────────────────────────────────────────
-- Buenos defaults. Sigue el espíritu del dotfiles: comentar el WHY,
-- no el WHAT — vim.opt.number = true no necesita comentario.

local opt = vim.opt

-- Líneas
opt.number = true
opt.relativenumber = true            -- saltos con `5j`, `10k` sin contar
opt.cursorline = true
opt.scrolloff = 8                    -- 8 líneas de margen al hacer scroll
opt.sidescrolloff = 8
opt.wrap = false                     -- wrap suele ser ruido para código

-- Indentación
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
-- Lenguajes con convención propia override con autocmd (autocmds.lua):
-- Go usa tabs reales; PHP suele ser 4 espacios.

-- Búsqueda
opt.ignorecase = true
opt.smartcase = true                 -- ignora case salvo que escribas mayúsculas
opt.incsearch = true
opt.hlsearch = true

-- UI
opt.termguicolors = true             -- 24-bit. Requiere terminal capable (Ghostty ✓).
opt.signcolumn = "yes"               -- siempre visible: evita layout shift al aparecer LSP/git signs
opt.showmode = false                 -- lualine ya muestra el modo
opt.cmdheight = 1
opt.pumheight = 10                   -- max items en popup de completion
opt.splitright = true                -- vsplits a la derecha (intuitivo en pantallas anchas)
opt.splitbelow = true
opt.fillchars = { eob = " " }        -- oculta ~ en líneas vacías al final del buffer

-- Buffers / archivos
opt.hidden = true                    -- permite cambiar de buffer sin guardar
opt.undofile = true                  -- undo persistente entre sesiones (en ~/.local/share/nvim/undo/)
opt.swapfile = false                 -- molesta más de lo que ayuda con undofile + git
opt.backup = false
opt.updatetime = 250                 -- gitsigns/lsp respond más rápido (default 4000ms)
opt.timeoutlen = 400                 -- chord timeout (which-key respeta esto)

-- Clipboard
opt.clipboard = "unnamedplus"        -- comparte yank con clipboard del sistema

-- Completion / wildmenu
opt.completeopt = { "menu", "menuone", "noselect" }
opt.wildmode = "longest:full,full"

-- Folding (treesitter lo provee; arranca con todo expandido)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false               -- no fold al abrir buffer; usa `za` para toggle

-- Caracteres invisibles
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Diagnostic UI
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 4 },
  signs = true,
  underline = true,
  update_in_insert = false,          -- ruidoso mientras escribes
  severity_sort = true,
  float = { border = "rounded", source = true },
})
