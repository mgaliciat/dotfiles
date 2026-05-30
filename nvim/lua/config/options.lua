-- ─── theme del stack ──────────────────────────────────────────
-- nvim es UNA capa del "tema del stack" (junto a Ghostty y tmux). La
-- selección activa la maneja `scripts/theme <id>`, que escribe el id en
-- lua/theme-current.local (gitignored, *.local). Acá leemos ese puntero;
-- si no existe (máquina recién clonada, o nunca corriste `theme`) caemos
-- al default versionado. Mismo patrón override-at-end que ~/.zshrc.local.
--
-- Familia canónica (id = mismo string en Ghostty/nvim/tmux):
--   "solarized-osaka"  deep-ocean craftzdog (DEFAULT) ← plugin separado
--   "oled-neon"        true black OLED + Dracula neón
--   "anthropic-dark"   dark Claude.ai (brown-black + Claude orange)
--   "anthropic-warm"   dark sepia/terracota cálido
--   "prism-night"      azul medianoche + arco del prisma
--   "paper"            light cream + tinta sepia
-- (Las variantes solarized-osaka-{day,moon,storm} y "obsidian" siguen
--  siendo themes válidos acá, pero fuera de la matriz del switcher.)
--
-- Cambiar requiere reiniciar nvim (o :source $MYVIMRC + :colorscheme ...).
local function stack_theme()
  -- lua/theme-current.local vive junto a este archivo (config dir). Como
  -- ~/.config/nvim es symlink al repo, el puntero queda dentro del repo y
  -- gitignored por *.local. Una sola línea con el id del tema.
  local pointer = vim.fn.stdpath("config") .. "/lua/theme-current.local"
  if vim.fn.filereadable(pointer) == 1 then
    local line = (vim.fn.readfile(pointer)[1] or ""):gsub("%s+", "")
    if line ~= "" then
      return line
    end
  end
  return "solarized-osaka" -- default versionado del stack
end
vim.g.theme = stack_theme()

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

-- Folding (nvim-ufo lo provee; arranca con todo expandido)
-- ufo necesita foldlevel alto + foldenable=true; el provider
-- (treesitter→indent) se setea en plugins/ufo.lua, NO acá con
-- foldexpr — ufo registra su propio handler vía API.
opt.foldcolumn = "1"                 -- columna de fold markers (clickable con ufo)
opt.foldlevel = 99                   -- abrí todo por default
opt.foldlevelstart = 99
opt.foldenable = true                -- ufo requiere true para renderear su virtual text

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
