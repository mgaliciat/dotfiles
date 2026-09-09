# The theme family — provenance

One canonical id per theme, meaning the same thing in every layer. The
mechanics (selection lines, reload, how to add one) are in the repo's
`CLAUDE.md`; what follows is the part no config file records: **where each
palette's hex actually came from, and which sources are not valid.**

A theme here is three files that must mirror one palette — `ghostty/themes/<id>`,
`nvim/lua/themes/<id>.lua`, `tmux/themes/<id>.conf` — so "what is the source of
truth" is a question that comes up every time one is touched.

## Ports — hex taken verbatim from a published source

**`dark-2026`** · Clone of VS Code's default dark theme since 1.113. Hex from
`extensions/theme-defaults/themes/2026-dark.json` in microsoft/vscode.
**`light-2026`** is its light companion.

**`retta`** · Port of the Eclipse "Retta" theme by Eric (eclipsecolorthemes.org
id=1004, site now dead); hex verbatim from `themes/retta.xml` in the
eclipse-color-theme GitHub mirror. True black `#000` + cream `#f8e1aa`, pumpkin
keywords `#e79e3c`. Cyan and the brights do not exist in the source and are
derived on-palette.

**`solarized-dark`** / **`solarized-light`** · Ethan Schoonover's canonical
Solarized. base03 `#002b36` canvas, published accents, the canonical ANSI 16
shared between the two. The *original*, not the osaka fork: no re-tuned hex, no
`background =` override in Ghostty.

**`anthropic-brand`** · The seven official brand colours placed literally.
Source of truth is `skills/brand-guidelines/SKILL.md` in github.com/anthropics/skills
— Anthropic's own, and the only normative publication of them: Dark `#141413`,
Light `#faf9f5`, Mid Gray `#b0aea5`, Light Gray `#e8e6dc`, Orange `#d97757`,
Blue `#6a9bcc`, Green `#788c5d`. Seven values for sixteen ANSI slots is the
whole design problem: each brand colour lands verbatim in a real slot, and the
four hues the brand *has no value for* — red, yellow, magenta, cyan — are
derived on its own H/S/L grid, never borrowed from another palette.

**`anthropic-dark`** claims the same source but its blue `#61aaf2` / green
`#9aca86` came from a VS Code port, i.e. a third party's reading. Both anchors
the two themes share, `#141413` and `#d97757`, were still current as of
aug-2026, so **neither supersedes the other**.

## Sampled or derived — no published hex exists

**`xray`** · The palette of Ghostty's own `xray` dock icon, which
`config.ghostty` selects with `macos-icon = xray`, so the Dock icon and the
terminal are one object. Grays **sampled from the icon**, not guessed: board
`#101010` canvas, traces `#202020`/`#303030`, chip legs `#4c4c4c`, ghost
`#cdcecf` fg, highlight `#f0f0f0`. The icon's only chroma is a faint cool cast
on its light grays; pushed to usable it becomes the single accent, `#a3b5c6`
"film blue". ANSI is kept but desaturated to ~30% — a truly grayscale terminal
loses diffs and diagnostics.

To re-sample: the PNGs live in `Ghostty.app/Contents/Resources/Assets.car` as
`XrayImage`, extractable with `Bundle(path:).image(forResource:)` from a swift
script. Not to be confused with `MicrochipImage`, the green board.

**`naysayer`** · Jonathan Blow's editor colours — deep teal `#052329`, warm sand
fg, comments the brightest thing on screen. He never shipped a theme, so the
source is his editor's own colour-slot table at
<https://vegard.wiki/w/Jon_Blow_emacs_colorscheme>. **The nvim and VS Code ports
each re-interpret it and are not a valid source.** Blue does not exist in his
palette and is derived on its own `0x40/0x80/0xb0/0xc0/0xf0` grid.

That table is 18 slots of canvas and literals — `Background`, `Default`,
`Comment`, `Str_Constant`, `Int_Constant`, `Preproc`, `Cursor`, `Highlight`,
`Bar`, `Margin`, `Ghost_Character`, `Paste`, `Pop1`, … — and says **nothing about
keywords, types, functions or directives**. Left to itself a tokyonight base
invents a hierarchy he doesn't have, which is what makes every port of this theme
look wrong. Those roles come from a **secondary source**: `jblowtorch`, a builtin
theme of [Focus](https://github.com/focus-editor/focus), the editor written in
Jai — `config/themes/jblowtorch.focus-theme`, introduced by Focus's own author
Ivan Ivanov (`77114c51`, dec-2023), **not by Blow**. So it is a third party's
reading like the ports, and it earns its vote only by converging independently on
the anchors: bg `#072626`, fg `#d3b58d`, comment `#3ddf23`, cursor `#90ee90`,
selection `#0000ff`.

The rule that keeps the two straight: **jblowtorch fills gaps, it never overrides
a slot the table defines.** Strings stay `Str_Constant #40b0a0` and numbers stay
`Int_Constant #80f0e0` even though jblowtorch reads them as `#0fdfaf` / `#d699b5`.
What it does supply is `code_keyword #ffffff`, `code_type #98fb98`,
`code_directive #e67d74`, `code_macro #e0ad82`, `code_identifier #bfc9db`,
`code_builtin_variable #d699b5` — plus the two ANSI slots where an observed hex
beats a constructed one, red `#e64d4d` (its `code_deletion`) and magenta
`#d699b5` (its `code_number`).

The other half of the port problem is **flatness**: functions, calls, operators
and punctuation are all plain `Default` in his editor, so nothing competes with
the comments. `naysayer.lua` collapses those groups back onto `fg` explicitly.

**`neon-noir`** · True black `#000` noir canvas + a cool neon spectrum — magenta
keywords `#ff4d9d`, cyan types, electric-blue functions, mint strings, amber the
only warm slot. **Derived, NOT a port**: it takes its name and intent from the
"Neon Noir" preset Xcode 27 ships, but Apple publishes no hex for those presets
(WWDC26 rebuilt the theme system as a base palette plus two intensity sliders)
and no Xcode was installed to extract from. Nothing here is Apple's literal
value, and a VS Code port or a screenshot guess is not a valid source either.

It replaced `xcode-oled`, which *was* a literal port of Apple's
`Default (Dark).xccolortheme`. If Xcode 27 ever lands on a machine here,
re-extract from its bundled `.xccolortheme` under
`Xcode.app/Contents/SharedFrameworks/DVTUserInterfaceKit.framework/…/FontAndColorThemes/`
and this becomes a real port.

**`carbon`** (minimal true-black, high contrast, Claude-orange accent),
**`anthropic-warm`**, **`prism-night`**, **`paper`**, **`gray`** (neutral grey
canvas, near-black ink — the low-saturation light option beside `paper`) carry
no external source.

## `solarized-osaka` — the one with a plugin behind it

craftzdog's deep-ocean theme. The id is the full plugin name in all three
layers; "osaka" is just the informal nickname.

**The plugin is the source of truth for its own palette.** The hex comes from
`require("solarized-osaka.colors").setup()` (extractable with headless nvim) and
is baked by hand into the Ghostty theme and the tmux palette. If the plugin
changes its palette, re-extract and re-sync both mirrors.

- **Ghostty's ANSI is a literal mirror of the plugin's `M.terminal()`** — flat
  mapping: brights == normals, no orange/violet in ANSI, white = fg. That is
  deliberately *not* the classic Solarized convention; it is what makes the
  shell and a `:terminal` inside nvim look identical.
- **tmux is our own semantic derivation** (`@thm_*`). No upstream osaka tmux
  theme exists to mirror.
- **It is the only theme in the family that carries transparency**, with
  craftzdog's exact values from his dotfiles-public: Ghostty
  `background-opacity = 0.9` + `background-blur = 20` + the `background =
  #031219` canvas override, `transparent = true` in the nvim spec,
  `minimum-contrast` back to 1.1. All of that lives **in the shared files** with
  an "osaka only" note beside each line, not in the palette — so **activating
  any other theme means also putting opacity back to 1.0, blur to 0, and
  commenting the `background =` line**, or the new theme ships with a glass it
  was not designed for.

Sub-flavours `solarized-osaka-day`, `-moon` and `-storm` are nvim-only and not
members of the family. `obsidian` is likewise a valid nvim theme that sits
outside it.
