-- ─── theme del stack ──────────────────────────────────────────
-- nvim es UNA capa del "tema del stack" (junto a Ghostty y tmux). La
-- selección es este string, versionado y fuente de verdad: un `git pull`
-- propaga el tema a las otras máquinas. Para cambiar el look editá esta
-- línea (y las equivalentes de Ghostty y tmux — comparten id) y commiteá.
-- No hay switcher ni puntero; requiere reiniciar nvim.
--
-- Familia canónica (id = mismo string en Ghostty/nvim/tmux):
--   "dark-2026"        clon de "Dark 2026", el default oscuro de VS Code
--                       (extensions/theme-defaults/themes/2026-dark.json)
--   "light-2026"       clon de "2026 Light", su companion claro
--   "carbon"           minimal true-black, high contrast, acento Claude orange
--   "solarized-osaka"  deep-ocean craftzdog ← plugin separado
--   "xcode-oled"       true black OLED + syntax de Xcode "Default (Dark)"
--   "anthropic-dark"   dark Claude.ai (brown-black + Claude orange)
--   "anthropic-warm"   dark sepia/terracota cálido
--   "prism-night"      azul medianoche + arco del prisma
--   "paper"            light cream + tinta sepia
--   "solarized-light"  Solarized Light canónico
-- (Las variantes solarized-osaka-{day,moon,storm} y "obsidian" siguen
--  siendo themes válidos acá, pero fuera de la matriz.)
vim.g.theme = "solarized-osaka"

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
