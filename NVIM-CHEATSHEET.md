# nvim cheatsheet

Atajos más usados de mi config. `<leader>` = **espacio**. Salir de insert: **`jk`**.

Para todo lo demás: **`<leader>fk`** abre el buscador de keymaps (telescope), y **`<leader>`** solo dispara which-key con el menú de continuaciones.

> Referencia exhaustiva (todos los keymaps custom + plugins): `nvim/CHEATSHEET.md`.

---

## Archivos y carpetas

### oil.nvim — editar el directorio como texto (vim puro)
| Tecla | Acción |
|-------|--------|
| `-` | abre el directorio del archivo actual |
| `<leader>e` | abre oil |
| `o` / `i` + texto + `:w` | **crear archivo** (`foo.lua`) |
| nombre con `/` final + `:w` | **crear carpeta** (`utils/`) |
| `foo/bar/baz.lua` + `:w` | crea carpetas anidadas + archivo |
| editar línea + `:w` | renombrar |
| `dd` + `:w` | borrar |
| `q` | cerrar |

> `:w` aplica los cambios al filesystem (muestra preview antes de confirmar).

### neo-tree — sidebar tipo IDE
| Tecla | Acción |
|-------|--------|
| `<leader>n` | toggle del árbol |
| `<leader>N` | revelar archivo actual en el árbol |
| `a` | **add** — `foo.lua` archivo · `foo/` carpeta · `a/b/c.lua` ruta completa |
| `d` / `r` | borrar / renombrar |
| `c` / `m` | copiar / mover |
| `l` / `h` | abrir / colapsar nodo |
| `q` | cerrar panel |

---

## Buscar / navegar (telescope)
| Tecla | Acción |
|-------|--------|
| `<leader>ff` | find files |
| `<leader>fg` | live grep (buscar en todo el proyecto) |
| `<leader>/` | buscar en el buffer actual |
| `<leader>fb` | buffers abiertos |
| `<leader>fr` | recientes |
| `<leader>fs` / `<leader>fS` | símbolos del documento / workspace |
| `<leader>fd` | diagnostics |
| `<leader>ft` | TODOs |
| `<leader>fc` / `<leader>fk` | commands / keymaps |
| `<leader>fh` | help tags |

### Saltos rápidos (flash)
| Tecla | Acción |
|-------|--------|
| `s` + 2 chars | saltar a cualquier lado de la pantalla |
| `S` | saltar por nodos treesitter (normal/operator; en visual `S` es el wrap de nvim-surround) |

---

## LSP — esencial para revisar código generado
| Tecla | Acción |
|-------|--------|
| `gd` | ir a definición (peek si hay varias) |
| `gr` | referencias |
| `gi` / `gt` | implementación / type definition |
| `gD` | declaración |
| `K` | hover docs (o abre peek de un fold) |
| `<leader>ca` | code action (fixes, imports, etc.) |
| `<leader>rn` | renombrar símbolo (preview en vivo) |
| `<leader>cs` | signature help |
| `<leader>ch` | toggle inlay hints |
| `<leader>cl` | run code lens (go test, etc.) |
| `[d` / `]d` | diagnostic anterior / siguiente |
| `<leader>cd` | diagnostics de la línea |

---

## Git (gitsigns) — clave revisando diffs de prompts
| Tecla | Acción |
|-------|--------|
| `<leader>gs` | stage hunk |
| `<leader>gr` | reset hunk (descartar cambio) |
| `<leader>gp` | preview hunk |
| `<leader>gd` | diff del archivo |
| `<leader>gb` | toggle blame en la línea |

> Lazygit completo: **`prefix + g`** en tmux (`prefix` = `C-t`).

---

## Formatear código
| Tecla | Acción |
|-------|--------|
| `<leader>cf` | formatear buffer / selección |

> Go, Rust y Lua se formatean **solo al guardar**. Markdown / SQL / PHP: manual con `<leader>cf`.

---

## Edición rápida
| Tecla | Acción |
|-------|--------|
| `<A-j>` / `<A-k>` | mover línea (o selección) abajo / arriba |
| `<` / `>` en visual | indentar y mantener selección |
| `p` en visual | pegar sin perder el yank |
| `<leader>p` / `<leader>P` | pegar último yank (ignora deletes) |
| `<leader>d` / `x` | borrar sin contaminar el registro |
| `+` / `<C-x>` | incrementar / decrementar (dial: bool, fechas, semver, let↔const; `-` es de oil.nvim) |

---

## Ventanas, buffers, archivo
| Tecla | Acción |
|-------|--------|
| `<C-h/j/k/l>` | moverse entre splits |
| `<C-flechas>` | redimensionar split |
| `<S-l>` / `<S-h>` | buffer siguiente / anterior |
| `<leader>bd` | cerrar buffer |
| `<leader>w` / `<leader>q` | guardar / cerrar |
| `<leader>Q` | cerrar todo (force) |
| `<Esc>` | limpiar highlight de búsqueda |

---

## Folds, foco, plugins
| Tecla | Acción |
|-------|--------|
| `zR` / `zM` | abrir / cerrar todos los folds |
| `zr` / `zm` | reducir / aumentar nivel de fold |
| `<leader>z` | zen mode (foco) |
| `<leader>Z` | zen zoom (solo la ventana) |
| `:Lazy` | gestionar plugins |
| `:Mason` | gestionar LSPs / formatters |

---

> 🤠 **Cowboy mode**: si martilás `hjkl` más de 10 veces en 2s, te frena. Usá motions reales (`w`, `b`, `f{char}`, `s` de flash, `5j`).
