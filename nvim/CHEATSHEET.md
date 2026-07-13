# nvim cheatsheet

Comandos relevantes para **esta config específica**. Para referencia exhaustiva de vim, usá `:help` dentro de nvim. Este documento cubre: lo nativo más usado + todos los keymaps custom + plugins instalados.

> Versión condensada (solo lo esencial para revisar diffs generados por IA): `../NVIM-CHEATSHEET.md` en la raíz del repo.

`<leader>` = **barra espaciadora**. `<CR>` = Enter. `<C-x>` = Ctrl+x. `<A-x>` = Alt+x. `<S-x>` = Shift+x.

---

## 0. Conceptos base

### Modos

| Modo | Cómo entrar | Para qué |
|---|---|---|
| **Normal** | `<Esc>` o `jk` | Default. Navegar, comandos. No escribís texto. |
| **Insert** | `i`, `a`, `o`, `I`, `A`, `O` | Escribir texto. |
| **Visual** | `v` (char), `V` (línea), `<C-v>` (bloque) | Seleccionar. |
| **Command** | `:` | Comandos `:w`, `:Telescope`, etc. |
| **Replace** | `R` | Sobrescribe en vez de insertar. |
| **Terminal** | `:terminal` | Terminal embebido. `<C-\><C-n>` para volver a normal. |

### Salir / guardar

| Acción | Atajo |
|---|---|
| Guardar | `<leader>w` o `:w` |
| Cerrar | `<leader>q` o `:q` |
| Forzar cerrar todo | `<leader>Q` |
| Guardar y cerrar | `:wq` o `ZZ` |
| Cerrar sin guardar | `:q!` o `ZQ` |

---

## 1. Movimiento (vim nativo, esencial)

### Carácter / línea
- `h j k l` — izquierda, abajo, arriba, derecha
- `w` / `b` — palabra siguiente / anterior
- `W` / `B` — WORD siguiente / anterior (separado por espacios, ignora puntuación)
- `e` — fin de palabra
- `0` / `^` — inicio de línea / primer no-espacio
- `$` — fin de línea
- `f<char>` / `F<char>` — saltar a `<char>` en línea (adelante / atrás)
- `t<char>` — hasta justo antes de `<char>`
- `;` / `,` — repetir último `f`/`t` (adelante / atrás)

### Archivo
- `gg` / `G` — primera / última línea
- `<num>G` o `:<num>` — ir a línea N (ej: `42G`)
- `<C-u>` / `<C-d>` — scroll media página arriba / abajo
- `<C-b>` / `<C-f>` — scroll página entera arriba / abajo
- `zz` — centrar línea actual en pantalla
- `zt` / `zb` — línea actual al top / bottom

### Saltos
- `%` — saltar al `()` / `{}` / `[]` que matchea
- `*` / `#` — buscar palabra bajo cursor adelante / atrás
- `n` / `N` — siguiente / anterior match de búsqueda
- `<C-o>` / `<C-i>` — atrás / adelante en jump history
- `<C-^>` — toggle buffer anterior

---

## 2. Edición (vim nativo, esencial)

### Texto
- `i` / `a` — insert antes / después del cursor
- `I` / `A` — insert al inicio / fin de línea
- `o` / `O` — nueva línea abajo / arriba (entra a insert)
- `r<char>` — reemplazar 1 carácter
- `cw` — cambiar palabra. `cc` — cambiar línea. `C` — cambiar hasta fin de línea
- `dw` — borrar palabra. `dd` — borrar línea. `D` — borrar hasta fin de línea
- `x` — borrar carácter. `X` — borrar carácter anterior
- `yy` — yank (copiar) línea. `Y` — yank hasta fin de línea
- `p` / `P` — paste después / antes
- `u` — undo. `<C-r>` — redo
- `.` — repetir último cambio
- `J` — juntar línea siguiente con actual

### Text objects (combinan con `d`, `c`, `y`, `v`)
- `iw` / `aw` — inner word / a word (incluye espacio)
- `i"` / `a"` — inner / around quotes (igual con `'` y `` ` ``)
- `i(` / `a(` — inner / around paréntesis (igual con `[`, `{`, `<`)
- `it` / `at` — inner / around tag HTML
- `ip` / `ap` — inner / around párrafo
- `if` / `af` — inner / around **function** (treesitter)
- `ic` / `ac` — inner / around **class** (treesitter)
- `ia` / `aa` — inner / around **argument** (treesitter)

Ejemplos: `daw` borra palabra + espacio. `ci"` cambia contenido entre comillas. `vaf` selecciona función entera.

### Modo visual
- `v` / `V` / `<C-v>` — visual char / línea / bloque
- `o` — saltar al otro extremo de la selección
- En visual, todos los operadores funcionan: `d`, `y`, `c`, `>`, `<`
- `<` / `>` — indentar (mantiene selección, ver custom keymap)
- `p` — paste sin yankear lo reemplazado (ver custom keymap)
- `<A-j>` / `<A-k>` — mover selección arriba/abajo (ver custom keymap)

### Registros (clipboards múltiples)
- `"ayy` — yank línea al registro `a`
- `"ap` — paste del registro `a`
- `"+y` / `"+p` — yank / paste al system clipboard (ya seteado por default con `clipboard=unnamedplus`)
- `"_d` — delete sin sobrescribir el yank actual (ej: `"_d` en visual)
- `:reg` — ver todos los registros

---

## 3. Custom keymaps de esta config

Todos están en `lua/config/keymaps.lua` con sus `desc` — los ves también con which-key (presioná `<leader>` y esperá).

### General

| Atajo | Acción |
|---|---|
| `jk` (en insert) | Salir a normal (más rápido que `<Esc>`) |
| `<Esc>` (en normal) | Limpiar highlight de búsqueda |
| `<leader>w` | Guardar |
| `<leader>q` | Cerrar ventana |
| `<leader>Q` | Cerrar todo forzado |

### Navegación entre splits

| Atajo | Acción |
|---|---|
| `<C-h>` | Split izquierda |
| `<C-j>` | Split abajo |
| `<C-k>` | Split arriba |
| `<C-l>` | Split derecha |
| `<C-Arrow>` | Redimensionar split |

### Buffers

| Atajo | Acción |
|---|---|
| `<S-l>` | Buffer siguiente |
| `<S-h>` | Buffer anterior |
| `<leader>bd` | Cerrar buffer actual |

### Mover líneas

| Atajo | Acción |
|---|---|
| `<A-j>` (normal) | Bajar línea actual |
| `<A-k>` (normal) | Subir línea actual |
| `<A-j>` / `<A-k>` (visual) | Mover selección |

### Visual mejorado

| Atajo | Acción |
|---|---|
| `<` / `>` (visual) | Indentar manteniendo selección |
| `p` (visual) | Paste sin perder el yank |

### Diagnostics (sin LSP attach todavía)

| Atajo | Acción |
|---|---|
| `[d` | Diagnostic anterior |
| `]d` | Diagnostic siguiente |
| `<leader>cd` | Mostrar diagnostic de la línea |

### Aceleradores (estilo craftzdog)

Todos son **aceleradores dentro del modelo vim**, no muletas Mac. Diseñados para que el yank register no se contamine y la edición sea más eficiente.

| Atajo | Acción |
|---|---|
| `<leader>p` (normal / visual) | Paste del **registro 0** — siempre pega el último yank, ignora deletes |
| `<leader>P` | Igual pero **antes** del cursor |
| `<leader>d` (normal / visual) | Delete sin contaminar registro (al black-hole `"_`) |
| `<leader>D` | Delete hasta EOL sin contaminar registro |
| `x` | Borrar 1 char sin contaminar registro |
| `+` | Increment número bajo cursor (= `<C-a>`, smart vía dial) |
| `<C-x>` | Decrement (smart vía dial). `-` no está mapeado: lo usa oil.nvim para "parent dir" |

### 🤠 Cowboy mode

Si presionás `h j k l` **más de 10 veces en 2 segundos**, se bloquea y muestra `🤠 Hold it Cowboy!`. Te fuerza a aprender motions reales:

- En vez de `jjjjjj` → usá `}` (próximo párrafo), `5j` (5 líneas), `/foo` (buscar), `Gg` (ir al final/inicio).
- En vez de `hhhhh` → usá `b` (palabra atrás), `0` (inicio de línea), `F<char>` (saltar a char).
- En vez de `lllll` → usá `w` (palabra adelante), `$` (fin de línea), `f<char>` (saltar a char).
- Si usás un count (ej: `15j`), **no cuenta como spam**.

---

## 4. LSP — stack instalado

| Lenguaje | LSP server | Notas |
|---|---|---|
| Go | `gopls` | inlay hints completos, gofumpt + staticcheck on |
| TypeScript / JavaScript / React (.tsx) | `ts_ls` | un solo server para todo el ecosistema TS/JS |
| Angular | `angularls` | toma el lead en proyectos Angular; ts_ls cubre TS fuera del proyecto |
| Astro | `astro` | parsea `.astro` con frontmatter mixto |
| Rust | `rust-analyzer` vía `rustaceanvim` | NO va por lspconfig — plugin propio |
| PHP | `intelephense` | premium-tier sin licencia (~80% de features); soporta proyectos hasta 5MB |
| Python | `basedpyright` + `ruff` | basedpyright = type checking; ruff = linter + formatter + import sorter |
| YAML | `yamlls` | schemas auto vía SchemaStore (k8s, GitHub Actions, etc.) |
| JSON | `jsonls` | schemas auto vía SchemaStore (package.json, tsconfig, etc.) |
| HTML | `html` + `emmet_ls` | emmet expande `div.foo>span` → markup |
| CSS / SCSS / Less | `cssls` + `emmet_ls` | |
| Bash / sh / zsh | `bashls` | usa shellcheck si está en PATH |
| Lua | `lua_ls` | conoce las APIs de nvim para tu config |
| Markdown | `marksman` | links, refs, headings |

**Pre-requisitos del SISTEMA** (mason NO los instala):

| Toolchain | Para qué LSP | Cómo instalar |
|---|---|---|
| `go` | gopls | `brew install go` |
| `node` | ts_ls, angularls, astro, html, cssls, jsonls, yamlls, intelephense, emmet, bashls, marksman | ya lo tenés (Claude Code lo requiere) |
| `python3` | basedpyright | macOS trae uno; recomendado `pyenv` para versiones específicas |
| `rustup` | rust-analyzer | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| `php` (opcional) | intelephense valida paths | `brew install php` |

Mason descarga el resto bajo demanda. `:Mason` para ver/instalar/actualizar.

**Verificar estado del LSP en el buffer actual:** `:LspInfo`

## LSP keymaps (activos cuando hay un server adjunto)

Se setean automáticamente en cualquier buffer con LSP activo.

| Atajo | Acción |
|---|---|
| `gd` | Goto definition |
| `gD` | Goto declaration |
| `gr` | Buscar referencias |
| `gi` | Goto implementation |
| `gt` | Goto type definition |
| `K` | Hover docs (mostrar info del símbolo bajo cursor) |
| `<leader>rn` | Renombrar símbolo (en todo el proyecto) |
| `<leader>ca` | Code action (quick fix, refactor) |
| `<leader>cs` | Signature help |
| `<leader>ch` | Toggle inlay hints |

### Treesitter movement (en funciones / clases)

| Atajo | Acción |
|---|---|
| `]f` / `[f` | Siguiente / anterior función |
| `]c` / `[c` | Siguiente / anterior clase |

---

## 5. Telescope (fuzzy finder) — `<leader>f*`

| Atajo | Acción |
|---|---|
| `<leader>ff` | Find files (en cwd) |
| `<leader>fg` | Live grep (buscar texto en proyecto) |
| `<leader>fb` | Buffers abiertos |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags (docs de nvim) |
| `<leader>fc` | Commands disponibles |
| `<leader>fk` | Keymaps activos |
| `<leader>fd` | Diagnostics del workspace |
| `<leader>fs` | Symbols del documento actual |
| `<leader>fS` | Symbols del workspace |
| `<leader>/` | Buscar dentro del buffer actual |

**Dentro de Telescope:**
- `<C-j>` / `<C-k>` — navegar resultados (igual que `<C-n>` / `<C-p>`)
- `<CR>` — abrir
- `<C-x>` — abrir en split horizontal
- `<C-v>` — abrir en split vertical
- `<C-t>` — abrir en tab
- `<Esc>` — cerrar (sin doble escape)

---

## 6. Git — `<leader>g*` (gitsigns)

| Atajo | Acción |
|---|---|
| `]h` | Próximo hunk |
| `[h` | Hunk anterior |
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Toggle blame inline |
| `<leader>gd` | Diff buffer actual |

Signs en gutter:
- `│` línea agregada / modificada
- `_` / `‾` línea eliminada
- `~` línea cambiada-y-eliminada
- `┆` archivo untracked

---

## 7. Formatting — `<leader>cf` (conform.nvim)

| Atajo | Acción |
|---|---|
| `<leader>cf` (normal / visual) | Formatear buffer o selección |

**Format on save automático** (definido en `plugins/conform.lua`) para:
- Go (`goimports` + `gofumpt`)
- Rust (`rustfmt`)
- Lua (`stylua`)

**Disponibles pero NO on-save** (corré manual con `<leader>cf`):
- TS/JS/JSON/YAML/MD → `prettierd` / `prettier`
- PHP → `php_cs_fixer`
- SQL → `sqlfluff`
- shell → `shfmt`

Mason instala los formatters al primer uso. Si falta uno: `:Mason` → buscalo → `i` para install.

---

## 8. Folding (treesitter-based)

| Atajo | Acción |
|---|---|
| `za` | Toggle fold actual |
| `zM` | Cerrar todos los folds |
| `zR` | Abrir todos los folds |
| `zc` / `zo` | Cerrar / abrir fold |
| `zj` / `zk` | Próximo / anterior fold |

Por default arrancás con **todo expandido** (`foldenable = false` en `options.lua`).

---

## 9. Búsqueda y reemplazo

### Buscar
- `/<patrón>` — buscar adelante
- `?<patrón>` — buscar atrás
- `n` / `N` — siguiente / anterior
- `*` / `#` — buscar palabra bajo cursor
- `<Esc>` — limpiar highlight (custom)

### Reemplazo `:substitute`
- `:s/viejo/nuevo/` — primera ocurrencia en línea
- `:s/viejo/nuevo/g` — todas en línea
- `:%s/viejo/nuevo/g` — todas en archivo
- `:%s/viejo/nuevo/gc` — todas en archivo con confirmación
- `:'<,'>s/viejo/nuevo/g` — en selección visual

Flags útiles: `c` confirmar, `i` case-insensitive, `I` case-sensitive.

---

## 10. Splits y tabs

### Splits
- `:split` / `:sp` o `<C-w>s` — split horizontal
- `:vsplit` / `:vsp` o `<C-w>v` — split vertical
- `<C-w>q` o `:close` — cerrar split
- `<C-w>o` — solo este split (cierra los demás)
- `<C-w>=` — igualar tamaños
- `<C-w>x` — swap con el split siguiente
- Navegación: `<C-h/j/k/l>` (custom)
- Resize: `<C-Arrow>` (custom)

### Tabs
- `:tabnew` — nueva tab
- `:tabclose` — cerrar tab
- `gt` / `gT` — siguiente / anterior tab
- `<num>gt` — ir a tab N

---

## 11. Mantenimiento

### Plugins (lazy.nvim)
- `:Lazy` — abrir UI del plugin manager
- `:Lazy sync` — actualizar e instalar plugins pendientes
- `:Lazy update` — actualizar plugins
- `:Lazy clean` — borrar plugins no listados
- `:Lazy profile` — ver tiempo de carga de cada plugin
- `:Lazy log` — log de cambios recientes

### LSP servers (mason)
- `:Mason` — UI para instalar/desinstalar LSPs, formatters, linters
- `:MasonInstall <name>` — instalar uno específico
- `:LspInfo` — estado del LSP en el buffer actual
- `:LspRestart` — reiniciar LSP del buffer

### Treesitter
- `:TSUpdate` — actualizar parsers
- `:TSInstall <lang>` — instalar parser de un lenguaje
- `:Inspect` — mostrar highlight groups bajo el cursor
- `:InspectTree` — abrir AST del buffer

### Diagnóstico
- `:checkhealth` — chequeo general (nvim, plugins, mason)
- `:checkhealth lazy` — solo lazy
- `:checkhealth mason` — solo mason
- `:messages` — historial de mensajes (útil tras un error que pasó rápido)

---

## 12. which-key

Si te olvidás un atajo, presioná solo `<leader>` y esperá ~400ms. Te aparece un popup con todos los grupos:

- `<leader>b` → buffer
- `<leader>c` → code (LSP)
- `<leader>f` → find (telescope)
- `<leader>g` → git
- `<leader>r` → rename

También: `<leader>?` muestra solo los keymaps activos en el buffer actual.

---

## 13. Tips útiles

- **Macros**: `q<letra>` empezar a grabar, `q` parar, `@<letra>` ejecutar. `@@` repite la última.
- **Marcas**: `m<letra>` marca posición, `'<letra>` salta a la línea, `` `<letra> `` salta al carácter exacto. Marcas mayúsculas (`mA`) son globales entre archivos.
- **Increment / decrement**: `<C-a>` suma 1 al número bajo cursor, `<C-x>` resta 1.
- **`gx`** — abre URL bajo cursor en el navegador.
- **`gu` / `gU`** — lowercase / uppercase (con motion, ej: `guw` palabra a minúsculas).
- **`>ip` / `<ip`** — indentar / desindentar párrafo.
- **`==`** — re-indentar línea según LSP/treesitter.
- **`gd` en LSP attach** = goto definition. Mucho más útil que el `gd` nativo.
- **`<C-r>=` en insert** — calculadora inline (escribís `5*7` Enter, inserta `35`).

---

## 14. Cuando algo no funciona

| Síntoma | Diagnóstico |
|---|---|
| Atajo no responde | `:checkhealth which-key` o `:WhichKey <leader>a` para ver si está registrado |
| LSP no completa | `:LspInfo` muestra si está corriendo. `:Mason` para verificar que el server esté instalado |
| Color raro | `:Inspect` bajo el cursor muestra qué highlight group lo aplica |
| Lenguaje sin highlight | `:TSInstall <lang>` para instalar parser |
| Plugin no carga | `:Lazy` y buscar el plugin — ver si tiene error de instalación |
| Todo se rompió | `:Lazy restore` vuelve al lockfile (`lazy-lock.json`) |
