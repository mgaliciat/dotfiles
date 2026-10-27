# The theme family — provenance

One canonical id per theme, meaning the same thing in every layer. The
mechanics (selection lines, reload, how to add one) are in the repo's
`CLAUDE.md`; what follows is the part no config file records: **where each
palette's hex actually came from, and which sources are not valid.**

A theme here is two files that must mirror one palette — `ghostty/themes/<id>`
and `nvim/lua/themes/<id>.lua` — so "what is the source of truth" is a question
that comes up every time one is touched.

## Ports — hex taken verbatim from a published source

**`retta`** · Port of the Eclipse "Retta" theme by Eric (eclipsecolorthemes.org
id=1004, site now dead); hex verbatim from `themes/retta.xml` in the
eclipse-color-theme GitHub mirror. True black `#000` + cream `#f8e1aa`, pumpkin
keywords `#e79e3c`. Cyan and the brights do not exist in the source and are
derived on-palette.

**`solarized-patched`** · The "Solarized Dark Patched" cut. Hex copied verbatim
from the theme **Ghostty itself ships**, at
`Ghostty.app/Contents/Resources/ghostty/themes/Solarized Dark Patched` — that
file is the source of truth, and it is where to re-extract from. Nothing here is
derived but one slot, and **canonical Solarized is not a valid source for it**: the patched cut
re-tunes every value (canvas `#001e27` against base03 `#002b36`, red `#d11c24`
against `#dc322f`, blue `#2176c7` against `#268bd2`).

**The one derived slot: no purple.** Upstream's ANSI 13 is the violet `#5956ba`
(OKLCH hue 281), which `bold-color = bright` paints on every bold magenta. It
is replaced in both files by `#d3407f`, a brighter rose on ANSI 5's own hue
(OKLCH L 0.60, C 0.19, h 358), at 4.35:1 over the `#031219` canvas. ANSI 5
`#c61c6f` is a rose too (h 358), not a purple, and stays verbatim. In nvim
`purple` (keywords) follows `_base` onto that magenta instead of the violet.

It exists because **craftzdog's Ghostty selects this theme by name**, and a
built-in cannot be mirrored: it lives inside the app bundle, where nvim and
Windows Terminal cannot read it. Porting it is what lets the id mean the same
thing in every layer instead of Ghostty diverging from the rest.

His own line spells it `theme = "Solarized Dark - Patched"`, with a hyphen, and
that string does not resolve in current Ghostty — his terminal has been falling
back to the default palette since feb-2025. The port is the theme he meant.

**`flexoki-light`** · Steph Ango's Flexoki, light half: printing inks on warm
paper. The family's one light theme, picked in October 2026 for an OLED
screen. Hex copied verbatim from the theme **Ghostty itself ships**, at
`Ghostty.app/Contents/Resources/ghostty/themes/Flexoki Light` (it comes from
iTerm2-Color-Schemes' `ghostty/Flexoki Light`); the base/accent names, and the
values nvim uses beyond the ANSI table (orange-600, base-50/100/700), are from
`lua/flexoki/palette.lua` in kepano/flexoki-neovim.

Why it, for an OLED: the canvas is paper `#fffcf0`, not `#ffffff`. An OLED
lights each pixel on its own, so full white is its brightest, most power-hungry
frame and the one its brightness limiter fights; a warm off-white (OKLCH h 95)
carries less blue at the same level, and the near-black ink `#100f0f` (18.6:1)
sits on pixels that are almost off. Its accents are Solarized's hues
(1-6 within 2–8° of the patched cut's), so the stack keeps its look, and it has
**no purple**: Flexoki's purple is not in the ANSI table and the magentas are
roses (h 350). Passed over: Solarized Light (body text 4.1:1, and a violet),
Catppuccin Latte and Rosé Pine Dawn (built around mauve/iris), GitHub Light and
Modus Operandi (pure white canvas, purple keywords).

**The one deviation: ANSI 8.** Upstream's is base-300 `#b7b5ac`, 2.0:1 on the
paper, and 8 paints zsh's autosuggestions, tmux's status line and Claude Code's
dim text. It is base-500 `#878580` in both files, 3.6:1. The brights stay the
shipped 400 accents, lighter than the normals; yellow 11 and cyan 14 sit under
3:1 and `minimum-contrast = 3.0` in `config.ghostty` lifts them.

Derived, in nvim and the Claude Code theme only: the diff and search tints,
set in OKLCH on each accent's hue at L 0.84–0.97 so the ink reads on them at
11:1 or more. Its Claude Code theme (`claude/themes/flexoki-light.json`) exists
for legibility: on `light-ansi` it turns the spinner Flexoki orange
(`#bc5215`, 4.7:1) and puts message backgrounds and diffs on the paper's own
ladder.

**`slate`** · Tailwind's slate greys at night, made in October 2026 as the dark
counterpart to `flexoki-light`: a soft blue-grey canvas rather than a black
one, and no purple. Every hex is a swatch of the **Tailwind CSS v3 default
palette**, copied verbatim from `src/public/colors.js` in the tailwindcss
3.4.17 package; no published terminal theme is built on it, so the slot
assignment is ours and is written down in the theme file.

The canvas is slate-900 `#0f172a` (OKLCH L 0.21, C 0.04), the one Tailwind's
own dark mode sits on: lighter than `blueprint`'s near-black, and low enough in
chroma to read as grey rather than navy. Text is slate-200 (14.5:1), every
neutral is a step of the slate ladder, the normals 1-6 are Tailwind's 400s
(6.5–11.7:1) and the brights 9-14 their 300s (9.4–13.5:1). ANSI 8 is
slate-500 (3.8:1), the dim grey for zsh's autosuggestions and Claude Code's
subtle text; nvim's comments sit one step up on slate-400 (7.0:1).

**No purple**: the magenta slots are pink (h 350, the rose family the rest of
the stack uses there), not purple, violet or fuchsia. Sky (h 233) sits between
blue and cyan, so it is kept for the accent and cursor and the two ANSI slots
stay a plain blue and a plain cyan. Passed over: Nord, Iceberg, GitHub Dark
Dimmed, Tokyo Night Storm and One Dark, all slate-ish canvases whose magenta
slot is a lavender or violet; and Ghostty's built-in "Slate" (from
iTerm2-Color-Schemes), which despite the name sits on a neutral `#222222` with
cyan body text, a violet magenta (`#a481d3`, h 303) and a blue at 1.7:1.

Derived, in nvim and the Claude Code theme only: the search and diff tints, set
in OKLCH on each accent's hue at L 0.27–0.45 so the text reads on them at 5.7:1
or more. The nvim module also re-points what tokyonight derives from its own
`night` palette before `on_colors` (diff, rainbow, `:terminal`, diagnostics),
which would otherwise carry tokyonight's lavender in. Its Claude Code theme
(`claude/themes/slate.json`) exists for the accent: on `dark-ansi` it turns the
spinner sky (`#38bdf8`, shimmer `#7dd3fc`) and puts the message backgrounds and
diffs on the slate ladder, taking everything else from the Ghostty slots.

**`modus-vivendi`** · Protesilaos Stavrou's Modus Vivendi, the dark half of the
Modus themes that ship with Emacs (28+), added in October 2026 from a
screenshot of Emacs with it on: pure white `#ffffff` on pure black `#000000`,
every accent at WCAG AAA (7:1) or more. Hex copied verbatim from
`modus-themes.el` in protesilaos/modus-themes: the named colours of
`modus-themes-vivendi-palette`, and for the ANSI table the `fg-term-*` mappings
Emacs paints its own ANSI faces with. Nothing is derived, in any of the three
files: the diff, search, region, paren and message backgrounds are upstream
entries too.

Ghostty ships it as the built-in "Modus Vivendi" (from iTerm2-Color-Schemes),
and that copy is not the source: its ANSI 9 is `#ff7f9f`, an older red-cooler,
where upstream's bright red today is red-warmer `#ff6b55`. ANSI 0 is the canvas
itself and ANSI 8 `#595959` sits at 3.0:1, both as upstream has them.

**Purple is the theme here**, unlike the rest of the family: keywords are
magenta-cooler `#b6a0ff` (ANSI 13), and the screenshot it was matched to is
mostly that lavender, the teal types (cyan-cooler `#6ae4b9`), the blue strings
(blue-warmer `#79a8ff`), the pink function names (magenta `#feacd0`) and the
cyan variables (cyan `#00d3d0`). The nvim module maps tokyonight's groups onto
those Modus roles and resets what Emacs leaves plain (numbers, operators,
punctuation, calls) to fg; the line-number column sits on bg-dim `#1e1e1e` as
in Emacs. Neovim has a full port, miikanissi/modus-themes.nvim; it is not used
because the stack renders every theme but `solarized-osaka` through `_base`,
and one module keeps that single path. Its Claude Code theme
(`claude/themes/modus-vivendi.json`, `dark-ansi`) turns the spinner the keyword
lavender (shimmer fg-lavender `#dfc0f0`) and puts message backgrounds and
diffs on Modus's own greys and diff tints.

## Derived — no published hex exists

**`dia-de-muertos`** · The night of the vigil, made for October 2026. The altar
gives the hues and nothing else — morado canvas (the mourning colour of papel
picado), cempasúchil accent, grana cochinilla red, papel picado green, veladora
yellow, talavera blue, rosa mexicano magenta, sugar-skull turquoise, bone text,
copal-smoke comments.

Lightness and chroma are set per role in OKLCH, so no slot pops or sinks
against the others: normals at L 0.68–0.72 (yellow 0.80, since a yellow at 0.70
is mustard), brights at 0.78–0.88 with less chroma, every neutral carrying the
canvas hue, and a background ladder in even L steps. Normals land at 5.7–7.8:1
over the `#1d1022` canvas (yellow 9.7:1), brights at 8.7–12.7:1, measured in
sRGB. Cempasúchil is the cursor in Ghostty and `orange` (numbers, constants) in
nvim. Pantone's rosa mexicano `#e4007c` is a print swatch, not a valid source:
on this canvas it reads at 4.0:1.

**Ghostty's ANSI 12 is the bright cempasúchil `#ffbb76`, not a blue**, and it
is the one slot where the two files disagree on purpose: nvim keeps `#95c0ff`
as `bright_blue`, where it colours types. On a `dark-ansi` theme Claude Code
paints inline code, paths and hashes in ANSI 12, and in 2.1.287 its markdown
renderer resolves that colour from the base theme by name, so an override in
the Claude Code JSON never reaches the replies. The terminal slot is the only
lever that does.

Its Claude Code theme (`claude/themes/dia-de-muertos.json`) is the one that
exists for the accent rather than for legibility: Claude orange already reads
at 5.9:1 here. It turns the spinner cempasúchil (`#fc9417`, shimmer `#ffbb76`)
and puts the message backgrounds and diffs on the theme's own ladder and hues,
`dark-ansi` taking everything else from the Ghostty slots.

**`blueprint`** · A drafting sheet read at night, made in October 2026. The
cyanotype gives the hues and nothing else — the white of the cyanotype line for
text, the cyan of a lit drafting line as the accent, the architect's redline
correction pencil for red, highlighter yellow, surveyor's orange (nvim only),
graphite comments. A blueprint carries no green or magenta ink; those two are
filled in on-palette.

The canvas is a neutral near-black `#0a0a0a`, not blue. It started as the
cyanotype's Prussian blue taken down to a night (`#04172c`) and was dropped the
day it landed: on the blue the lettering read as lost. The blue survives in
the inks. Not pure `#000`, because the shader's paper grain lightens by a
fraction of the canvas and over black it could only darken.

Lightness and chroma are set per role in OKLCH, the same scheme as
`dia-de-muertos`: normals at L 0.68–0.84 (yellow at the top, cyan 0.76),
brights 9–14 at 0.80–0.90 with chroma lowered to 0.09–0.11, every neutral
(greys, graphite, the background ladder) achromatic, the text and ANSI 7/15
on the cyanotype-white hue (h 224–231), and the ladder in L steps
(0.11 / 0.145 / 0.215 / 0.29 / 0.34). Normals land at 6.3–9.6:1 over the
canvas (yellow 12.2:1), brights at 10.1–14.8:1, graphite comments at 5.9:1,
text at 16.2:1, measured in sRGB. The cyan accent `#4be4ff` is the cursor in
Ghostty.

It comes with a shader, `ghostty/shaders/blueprint.glsl` — a faint grey grid,
ink bleed and paper grain — which `scripts/theme` turns on with the theme and
off with any other.

**Unlike `dia-de-muertos`, ANSI 12 stays a real bright blue `#97c9fd`**, so
the Ghostty file and nvim agree on every slot. Claude Code still paints inline
code in ANSI 12, but on a blueprint blue is the theme's own ink, so there is
nothing to redirect.

Its Claude Code theme (`claude/themes/blueprint.json`) exists for the accent:
on `dark-ansi` it turns the spinner the drafting-line cyan (`#4be4ff`, shimmer
`#86e2f0`) and puts the message backgrounds and diffs on the theme's own ladder
and hues, taking everything else from the Ghostty slots.

## `solarized-osaka` — the one with a plugin behind it

craftzdog's deep-ocean theme. The id is the full plugin name in both
layers; "osaka" is just the informal nickname.

**The plugin is the source of truth for its own palette.** The hex comes from
`require("solarized-osaka.colors").setup()` (extractable with headless nvim) and
is baked by hand into the Ghostty theme. If the plugin changes its palette,
re-extract and re-sync the Ghostty theme.

- **Ghostty's ANSI is a literal mirror of the plugin's `M.terminal()`** — flat
  mapping: brights == normals, no orange/violet in ANSI, white = fg. That is
  deliberately *not* the classic Solarized convention; it is what makes the
  shell and a `:terminal` inside nvim look identical.
- **Transparency is all-or-nothing across two layers.** Ghostty's opacity and
  blur, plus `transparent = true` on the active theme's spec — one without the
  other means nvim paints an opaque canvas over the glass and the seam shows at
  every split edge. The values live **in the shared files**, not in a palette,
  so they do not follow a theme around; craftzdog's set is opacity 0.9, blur 20,
  the `#031219` canvas and `minimum-contrast` at 1.1.

Sub-flavours `solarized-osaka-day`, `-moon` and `-storm` are nvim-only and not
members of the family.
