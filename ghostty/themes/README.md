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
derived, and **canonical Solarized is not a valid source for it**: the patched cut
re-tunes every value (canvas `#001e27` against base03 `#002b36`, red `#d11c24`
against `#dc322f`, blue `#2176c7` against `#268bd2`).

It exists because **craftzdog's Ghostty selects this theme by name**, and a
built-in cannot be mirrored: it lives inside the app bundle, where nvim and
Windows Terminal cannot read it. Porting it is what lets the id mean the same
thing in every layer instead of Ghostty diverging from the rest.

His own line spells it `theme = "Solarized Dark - Patched"`, with a hyphen, and
that string does not resolve in current Ghostty — his terminal has been falling
back to the default palette since feb-2025. The port is the theme he meant.

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
